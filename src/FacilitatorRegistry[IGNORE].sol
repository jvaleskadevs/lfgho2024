// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {IGhoToken} from "./interfaces/IGhoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
//import {FacilitatorStable} from "./FacilitatorStable.sol"; // TODO: use proxy

// need FACILITATOR ROLES OR ADMIN
// owner should be a DAO
contract FacilitatorRegistry is Ownable {
    error InitializationFailed();
    
    ////////////////////////////////////////////
    //        VARIABLES
    ///////////////////////////////////////////
    
    IGhoToken public immutable IGHO;        
    address public immutable USDC;
/*    
    // facilitator => capacity
    mapping (address => uint) public capacityOf;   
*/    
    // total amount of GHO locked in this contract
    uint256 public totalSupply; 
/*
    // Implementation for the FacilitatorStable
    address public facilitatorStableImpl; // TODO use proxy

    // FacilitatorMultichain creation code hash, used by Create2
    bytes32 immutable FM_HASH = 
        0x5c148315112e20a140c861f62da9d0d47c41ca1ff60aab7bdf46c88e448cb355;
*/
    // every new Facilitator must pay this fee
    uint256 public facilitatorFee; 
    
    // ccip router
    address immutable CCIP_ROUTER;
    // destination chain => multichainListener
    mapping (uint => address) public multichainListeners;
/*
    // ccip mainnet/sepolia chain selector, this chain
    //uint64 CHAIN_SELECTOR = 5009297550715157269; // mainnet
    uint64 immutable CHAIN_SELECTOR = 16015286601757825753; // sepolia
*/

    ////////////////////////////////////////////
    //        EVENTS
    ///////////////////////////////////////////
    
    // emited after successfully create a new Facilitator
    event NewFacilitator(address indexed facilitator, string label, uint capacity);
    // emited after successfully change the Facilitator capacity
    event CapacityChanged(address indexed facilitator, uint oldCapacity, uint newCapacity);
    
    // init interfaces and variables
    constructor(address _gho, address _usdc, address _router, uint256 _fee) 
        Ownable(msg.sender) {
            IGHO = IGhoToken(_gho);
            USDC = _usdc;
            CCIP_ROUTER = _router;
            facilitatorFee = _fee;
            //multichainListeners[2664363617261496610] = ; // opt goerli /// TODO TODO TODO 
    }
    
    ////////////////////////////////////////////
    //        MODIFIERS
    ///////////////////////////////////////////
    
    // only callable from a previously registered Facilitator
    modifier onlyFacilitator() {
        (uint capacity, uint level) = bucketOf(msg.sender);
        require(capacity > 0, "Forbidden");
        _;
    }
    
    ////////////////////////////////////////////
    //        WRITE FUNCTIONS
    ///////////////////////////////////////////
    
    // Create and Register a new Facilitator,
    // caller must supply an amount of GHO equals to capacity + fee,
    // caller must approve this amount of GHO, or it will revert  
    function registerFacilitator(
        address impl,
        uint128 capacity,
        string memory label,
        address admin,
        uint64 destinationChainSelector,
        bytes memory initData
    ) public payable returns (address facilitator) {   
        // increase the total amount of GHO in this contract
        totalSupply += capacity;
        // transfer the GHO (amount=capacity) from the caller
        // it ensures market neutrality of the Facilitator
        IGHO.transferFrom(msg.sender, address(this), capacity); // TODO: send to external treasury
        // transfer an small amount of GHO as fee from the caller
        IGHO.transferFrom(msg.sender, address(this), facilitatorFee); // TODO: send to other address
        
        if (destinationChainSelector != 0) {
            // create a new FacilitatorMultichain in the destination chain trough CCIP
            _deployFacilitatorMultichain(impl, capacity, destinationChainSelector, initData);      
        } else {
             // create a new Facilitator
            facilitator = _deployFacilitator(impl, initData, label);
            // add the new Facilitator to the GHO contract
            IGHO.addFacilitator(facilitator, label, capacity);
        }
        
        emit NewFacilitator(facilitator, label, capacity);     
        // emit with ZeroAddress for a multichain facilitator
    }
    
 /*   
    
    function registerFacilitator(
        string memory label,
        uint128 capacity,
        address admin,
        uint64 destinationChainSelector,
        address customAddress
    ) public payable returns (address facilitator) {
        // aassign custom Facilitator address or ZeroAddress
        facilitator = customAddress;
        // increase the total amount of GHO in this contract
        totalSupply += capacity;
        // transfer the GHO (amount=capacity) from the caller
        // it ensures market neutrality of the Facilitator
        IGHO.transferFrom(msg.sender, address(this), capacity); // TODO: send to external treasury
        // transfer an small amount of GHO as fee from the caller
        IGHO.transferFrom(msg.sender, address(this), facilitatorFee); // TODO: send to other address
        // check if the Facilitator exists, if not creates one
        if (facilitator == address(0)) {
            if (destinationChainSelector != 0 && destinationChainSelector != CHAIN_SELECTOR) {
                // a salt to help us computing a fixed address with Create2
                bytes32 salt = keccak256(abi.encodePacked(label, admin));
                // create a new FacilitatorMultichain in the destination chain trough CCIP
                _deployFacilitatorMultichain(capacity, admin, destinationChainSelector, salt);
                // compute the contract address of the deployed FacilitatorMultichain  
                facilitator = Create2.computeAddress(
                    salt, 
                    FM_HASH, //keccak256(abi.encodePacked(type(FacilitatorMultichain).creationCode)),
                    multichainListener // TODO: change to CCIP transmisoor: 0x7fEbf5F84a29CEF69CF0b1357C967B4Dd93A491f
                );
            } else {
                // create a new FacilitatorStable, GHO/USDC, 1:1
                facilitator = address(
                    new FacilitatorStable(admin, address(IGHO), USDC)
                );
            }  
        }
        // it will revert if the Facilitator has already been registered
        require(capacityOf[facilitator] == 0, "AlreadyRegistered");
        // assign the capacity to the facilitator
        capacityOf[facilitator] = capacity;
        // add the new Facilitator to the GHO contract
        IGHO.addFacilitator(facilitator, label, capacity);       
                
        emit NewFacilitator(facilitator, label, capacity);  
    }
*/
    
    ////////////////////////////////////////////
    //        INTERNAL FUNCTIONS
    /////////////////////////////////////////// 
    
    function _deployFacilitator(
        address impl,
        bytes memory initData,
        string memory label
    ) internal returns (address facilitator) {
        bytes32 salt = keccak256(abi.encodePacked(label, msg.sender));
        bytes memory code = _creationCode(impl, block.chainid, uint(salt));
        // precompute the address for the Facilitator contract
        facilitator = Create2.computeAddress(salt, keccak256(code));
        // revert if the contract was previously deployed
        if (facilitator.code.length != 0) revert InitializationFailed();
        // deploy Facilitator
        facilitator = Create2.deploy(0, salt, code);  
        (bool success, ) = facilitator.call(initData);
        if (!success) revert InitializationFailed();    
    }

    // Send a message to the MultichainListener with CCIP
    // it will create a new Facilitator in the destinatation chain
    function _deployFacilitatorMultichain(
        address impl,
        uint128 capacity, 
        uint64 destinationChainSelector,
        bytes memory initData
    ) internal {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(multichainListeners[destinationChainSelector]),
            data: abi.encode(impl, capacity, initData),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 3000000})),
            feeToken: address(0)//LINK
        });
        
        IRouterClient router = IRouterClient(CCIP_ROUTER);
        uint256 fees = router.getFee(destinationChainSelector, message);
        
        require(msg.value >= fees, "NotEnoughEth");
        
        bytes32 messageId = router.ccipSend{value: fees}(destinationChainSelector, message);    
    }
 
/*    
    // Send a message to the MultichainListener with CCIP
    // it will create a new Facilitator in the destinatation chain
    function _deployFacilitatorMultichain(
        uint128 capacity, 
        address admin, 
        uint64 destinationChainSelector,
        bytes32 salt
    ) internal {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(multichainListeners[destinationChainSelector]),
            data: abi.encode(admin, capacity, salt),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 3000000})),
            feeToken: address(0)//LINK
        });
        
        IRouterClient router = IRouterClient(CCIP_ROUTER);
        uint256 fees = router.getFee(destinationChainSelector, message);
        
        require(msg.value >= fees, "NotEnoughEth");
        
        bytes32 messageId = router.ccipSend{value: fees}(destinationChainSelector, message);
    }
 */   
    function _creationCode(
        address implementation_,
        uint256 chainId_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(  
            hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
            implementation_,
            hex"5af43d82803e903d91602b57fd5bf3",
            abi.encode(salt_, chainId_)
        );
    } 
    
    function _increaseCapacityOf(address facilitator, uint current, uint newCapacity) internal {
        // calculate delta, difference between old and new capacities
        uint delta = newCapacity - current;
        // increase total GHO locked in the contract 
        totalSupply += delta;      
        // more capacity, more GHO, deposit
        IGHO.transferFrom(facilitator, address(this), delta);
        // assign the new capacity to the facilitator
        //capacityOf[facilitator] = newCapacity;
        // set new capacity into the GHO contract
        IGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity));
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }    

    function _decreaseCapacityOf(address facilitator, uint current, uint newCapacity, uint level) internal {
        // calculate delta, difference between old and new capacities
        uint delta = current - newCapacity;
        // decrease total GHO locked in the contract 
        totalSupply -= delta;                
        // assign the new capacity to the facilitator
        //capacityOf[facilitator] = newCapacity;
        
        if (newCapacity == 0) {
            // remove the facilitator in the GHO contract
            IGHO.removeFacilitator(facilitator);
        } else {
            // set new capacity in the GHO contract
            IGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity));        
        }
        
        // less capacity, less GHO, withdraw 
        if (level > newCapacity) {
            // cannot withdraw full delta until decrease level
            // so, decreasing it by capturing remaining in USDC
            // it helps with diversification, USDC and GHO reserves
            IERC20(USDC).transferFrom(facilitator, address(this), level - newCapacity);
        }
        // less capacity, less GHO, withdraw 
        // last call to avoid reentrancy
        IGHO.transfer(facilitator, delta);
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }
    
    ////////////////////////////////////////////
    //        ONLY FROM FACILITATOR
    ///////////////////////////////////////////    
    
    // only callable from a Facilitator contract
    function setCapacity(uint newCapacity) public onlyFacilitator {
        (uint currentCapacity, uint level) = bucketOf(msg.sender);
        
        require(newCapacity != 0 && newCapacity != currentCapacity, "InvalidCapacity");
        
        if (newCapacity < currentCapacity) {
            _decreaseCapacityOf(msg.sender, currentCapacity, newCapacity, level);
        } else {
            _increaseCapacityOf(msg.sender, currentCapacity, newCapacity);
        }
    }
   
    ////////////////////////////////////////////
    //        ONLY FROM ADMIN
    /////////////////////////////////////////// 
    
    function setFacilitatorFee(uint _facilitatorFee) public onlyOwner {
        facilitatorFee = _facilitatorFee;
    }
/*    
    function setFacilitatorStableImpl(address _facilitatorStableImpl) public onlyOwner {
        facilitatorStableImpl = _facilitatorStableImpl;
    }
*/    
    function setMultichainListener(address _multichainListener, uint _destinationChain) public onlyOwner {
        multichainListeners[_destinationChain] = _multichainListener;
    }
    
    ////////////////////////////////////////////
    //        VIEW FUNCTIONS
    ///////////////////////////////////////////
    
    function bucketOf(address sender) public returns (uint capacity, uint level) {
        (capacity, level) = IGHO.getFacilitatorBucket(msg.sender);
    }
}
