// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {IGhoToken} from "./interfaces/IGhoToken.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {FacilitatorStable} from "./FacilitatorStable.sol"; // TODO: use proxy

// need FACILITATOR ROLES OR ADMIN
// owner should be a DAO
contract FacilitatorRegistry is Ownable {
    IGhoToken public immutable IGHO;        
    address public immutable USDC;
    
    // facilitator => capacity
    mapping (address => uint) public capacityOf;   
    
    // total amount of GHO locked in this contract
    uint256 public totalSupply; 
    // Implementation for the FacilitatorStable
    address public facilitatorStableImpl; // TODO use proxy
    // FacilitatorMultichain creation code hash, used by Create2
    bytes32 immutable FM_HASH = 
        0x5c148315112e20a140c861f62da9d0d47c41ca1ff60aab7bdf46c88e448cb355;
    // every new Facilitator must pay this fee
    uint256 public facilitatorFee; 
    
    // ccip router
    address immutable CCIP_ROUTER;
    // ccip receiver
    address multichainListener;
    // ccip mainnet/sepolia chain selector, this chain
    //uint64 CHAIN_SELECTOR = 5009297550715157269; // mainnet
    uint64 immutable CHAIN_SELECTOR = 16015286601757825753; // sepolia
    
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
    }
    
    // only callable from a registered facilitator contract
    modifier onlyFacilitator() {
        require(capacityOf[msg.sender] > 0, "Forbidden");
        _;
    }
    
    ////////////////////////////////////////////
    //        WRITE FUNCTIONS
    ///////////////////////////////////////////
    
    // Create and Register a new Facilitator,
    // or register a custom one created by the caller,
    // caller must supply an amount of GHO equals to capacity + fee,
    // caller must approve this amount of GHO, or it will revert  
    /// @param   customAddress    ZeroAddress, or custom Facilitator address
    /// ZeroAddress will create a new Facilitator 
    /// while the custom facilitator address will register it
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
        IGHO.transferFrom(msg.sender, address(this), capacity);
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
                    new FacilitatorStable(admin, address(IGHO), address(USDC))
                );
            }  
        }
        // it will revert if the Facilitator has already been registered
        require(capacityOf[facilitator] == 0, "AlreadyRegistered"); // TODO think about it, CCIP
        // assign the capacity to the facilitator
        capacityOf[facilitator] = capacity;
        // add the new Facilitator to the GHO contract
        IGHO.addFacilitator(facilitator, label, capacity);       
                
        emit NewFacilitator(facilitator, label, capacity);  
    }
    
    ////////////////////////////////////////////
    //        INTERNAL FUNCTIONS
    /////////////////////////////////////////// 
    
    // Send a message to the MultichainListener with CCIP
    // it will create a new Facilitator in the destinatation chain
    function _deployFacilitatorMultichain(
        uint128 capacity, 
        address admin, 
        uint64 destinationChainSelector,
        bytes32 salt
    ) internal {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(multichainListener),
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
    
    function _increaseCapacityOf(address facilitator, uint current, uint newCapacity) internal {
        // calculate delta, difference between old and new capacities
        uint delta = newCapacity - current;
        // increase total GHO locked in the contract 
        totalSupply += delta;      
        // more capacity, more GHO, deposit
        IGHO.transferFrom(facilitator, address(this), delta);
        // assign the new capacity to the facilitator
        capacityOf[facilitator] = newCapacity;
        // set new capacity into the GHO contract
        IGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity));
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }    

    function _decreaseCapacityOf(address facilitator, uint current, uint newCapacity) internal {
        // calculate delta, difference between old and new capacities
        uint delta = current - newCapacity;
        // decrease total GHO locked in the contract 
        totalSupply -= delta;       
        // less capacity, less GHO, withdraw
        IGHO.transfer(facilitator, delta);
        // assign the new capacity to the facilitator
        capacityOf[facilitator] = newCapacity;
        // set new capacity into the GHO contract
        IGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity));
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }
    
    ////////////////////////////////////////////
    //        ONLY FROM FACILITATOR
    ///////////////////////////////////////////    
    
    // only callable from a Facilitator contract
    function setCapacity(uint newCapacity) public onlyFacilitator {
        (uint currentCapacity, uint level) = IGHO.getFacilitatorBucket(msg.sender);
        
        require(newCapacity != 0 && newCapacity != currentCapacity, "InvalidCapacity");
        
        if (newCapacity < currentCapacity) {
            _decreaseCapacityOf(msg.sender, currentCapacity, newCapacity);
        } else {
            _increaseCapacityOf(msg.sender, currentCapacity, newCapacity);
        }
    }
    
    // only callable from a Facilitator contract
    // it will remove the Facilitator from the registry, could be added again
    function removeFacilitator(uint amount) public onlyFacilitator {
        (uint capacity, uint level) = IGHO.getFacilitatorBucket(msg.sender);
        require(level == 0 || amount == level, "NonZeroLevel");
        
        if (level > 0) {
            // deposit the missing GHO supplied by the facilitator to the market
            // it ensures the level is 0 to preserve the market neutrality of the facilitator
            IGHO.transferFrom(msg.sender, address(0), level);
        }
        
        // reset capacity and refund 
        _decreaseCapacityOf(msg.sender, capacity, 0);
        
        IGHO.removeFacilitator(msg.sender);
    }
   
    ////////////////////////////////////////////
    //        ONLY FROM ADMIN
    /////////////////////////////////////////// 
    
    function setFacilitatorFee(uint _facilitatorFee) public onlyOwner {
        facilitatorFee = _facilitatorFee;
    }
    
    function setMultichainListener(address _multichainListener) public onlyOwner {
        multichainListener = _multichainListener;
    }
    
    function setFacilitatorStableImpl(address _facilitatorStableImpl) public onlyOwner {
        facilitatorStableImpl = _facilitatorStableImpl;
    }
}
