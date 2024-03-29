// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {IGhoToken} from "./interfaces/IGhoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IATokenVault} from "./interfaces/IATokenVault.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";


// FacilitatorRegistry
// Deploy facilitators and manage their capacity
// 1 GHO == 1 capacity, it ensures market neutrality
// earn fees, capture USDC on decreasing capacity,
// then, send the USDC to a Vault, and
// the Vault supplies it to the AAVE protocol.
// generated yield can be used to fund public goods 
// ah, it also can deploy Facilitators on other chains!
// need FACILITATOR ROLES on GHO
// owner should be a DAO
contract FacilitatorRegistry is Ownable {
    error InitializationFailed();
    
    ////////////////////////////////////////////
    //        VARIABLES
    ///////////////////////////////////////////
    
    IGhoToken public immutable IGHO;        
    address public immutable USDC;
    IATokenVault public vault;
   
    // total amount of GHO locked in this contract
    uint256 public totalSupply; 

    // every new Facilitator must pay this fee
    uint256 public facilitatorFee; 
    
    // ccip router
    address immutable CCIP_ROUTER;
    // destination chain => multichainListener
    mapping (uint => address) public multichainListeners;

    ////////////////////////////////////////////
    //        EVENTS
    ///////////////////////////////////////////
    
    // emited after successfully create a new Facilitator
    event NewFacilitator(address indexed facilitator, string label, uint capacity);
    // emited after successfully change the Facilitator capacity
    event CapacityChanged(address indexed facilitator, uint oldCapacity, uint newCapacity);
    
    // init interfaces and variables
    constructor(address _gho, address _usdc, address _vault, address _router, uint256 _fee) 
        Ownable(msg.sender) {
            IGHO = IGhoToken(_gho);
            vault = IATokenVault(_vault);
            CCIP_ROUTER = _router;
            facilitatorFee = _fee;
            // opt goerli MultichainListener, will receive CCIP messages 
            multichainListeners[2664363617261496610] = 0x9B340aDC9AB242bf4763B798D08e8455778cB4ac;
            // max allowance for the vault
            IERC20(_usdc).approve(_vault, type(uint).max); 
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
        // increase the total amount of GHO locked in this contract
        totalSupply += capacity;
        // transfer the GHO (amount=capacity) from the caller
        // it ensures market neutrality of the Facilitator
        IGHO.transferFrom(msg.sender, address(this), capacity); // TODO: send to external treasury
        // transfer an small amount of GHO as fee from the caller
        IGHO.transferFrom(msg.sender, owner(), facilitatorFee);
        
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
        IGHO.transferFrom(facilitator, address(this), delta); // TODO: send to external treasury
        // set new capacity into the GHO contract
        IGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity));
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }    

    function _decreaseCapacityOf(address facilitator, uint current, uint newCapacity, uint level) internal {
        // calculate delta, difference between old and new capacity
        uint delta = current - newCapacity;
        // decrease total GHO locked in the contract 
        totalSupply -= delta;
        
        if (newCapacity == 0) {
            // remove the facilitator in the GHO contract
            IGHO.removeFacilitator(facilitator);
        } else {
            // set new capacity in the GHO contract
            IGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity)); // TODO: send to external treasury       
        }
        
        if (current > level && level > newCapacity) {
            // cannot withdraw full delta until decrease level
            // so, decreasing it by capturing the remaining in USDC
            // it helps with diversification, USDC and GHO reserves
            // it sends the USDC to a Vault supplying it to the AAVE protocol
            vault.deposit(level - newCapacity, owner());
            // other option:
            //IERC20(USDC).transferFrom(facilitator, address(this), level - newCapacity); 
        }
        // less capacity, less GHO, withdraw 
        // need to be the last call to avoid reentrancy
        IGHO.transfer(facilitator, delta);
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }
    
    ////////////////////////////////////////////
    //        ONLY FROM FACILITATOR
    ///////////////////////////////////////////    
    
    // only callable from a Facilitator contract
    function setCapacity(uint newCapacity) public onlyFacilitator {
        (uint currentCapacity, uint level) = bucketOf(msg.sender);
        
        require(newCapacity != currentCapacity, "NothingChanged");
        
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
  
    function setMultichainListener(address _multichainListener, uint _destinationChain) public onlyOwner {
        multichainListeners[_destinationChain] = _multichainListener;
    }
    
    ////////////////////////////////////////////
    //        VIEW FUNCTIONS
    ///////////////////////////////////////////
    
    function bucketOf(address sender) public view returns (uint capacity, uint level) {
        (capacity, level) = IGHO.getFacilitatorBucket(sender);
    }
}
