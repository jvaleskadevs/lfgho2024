// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
//import {FacilitatorMultichain} from "./FacilitatorMultichain.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IFacilitator} from "./interfaces/IFacilitator.sol";
import {USDC} from "../utils/Constants.sol";


interface IFacilitatorInitializer {
    function initialize(address admin, uint capacity, address token) external;
}


contract MultichainListener is CCIPReceiver {
    address /*immutable*/ FACILITATOR_REGISTRY; /// TODO TESTONLY
    address facilitatorMultichainImpl;
    
    event NewFacilitator(address indexed facilitator, uint256 capacity, bytes32 messageId, address admin);
    event CapacityChanged(address indexed facilitator, uint256 capacity, bytes32 messageId);
    
    constructor(address _router, address _registry, address[] memory _impls) CCIPReceiver(_router) {
        FACILITATOR_REGISTRY = _registry;
        facilitatorMultichainImpl = _impls[0];
        // other implementation = _impls[1]; 
        // another implementation = _impls[2]; ...
    }
    
    function _ccipReceive(Client.Any2EVMMessage memory receivedMessage) internal override {        
        (address sender) = abi.decode(receivedMessage.sender, (address));
        require(sender == FACILITATOR_REGISTRY, "OnlyFromRegistry");
        
        uint64 sourceChainSelector = receivedMessage.sourceChainSelector;
        require(
            sourceChainSelector == 5009297550715157269 || // mainnet
            sourceChainSelector == 16015286601757825753,  // sepolia /// TODO TESTONLY
        "OnlyFromMainnet");
        
        uint8 taskSelector = uint8(bytes1(receivedMessage.data));
        
        if (taskSelector == 0) {
            (address admin, uint256 capacity, bytes32 salt) = abi.decode(
                receivedMessage.data, 
                (address, uint256, bytes32)
            );
            
            _deployFacilitator(admin, capacity, salt, receivedMessage.messageId);            
        } else {
            (address facilitator, uint256 newCapacity) = abi.decode(
                receivedMessage.data, 
                (address, uint256)
            );
            
            _configFacilitator(facilitator, newCapacity, receivedMessage.messageId);            
        }
    }

    function _deployFacilitator(address admin, uint capacity, bytes32 salt, bytes32 messageId) internal {
        // deploy a new Facilitator clone with create2
        address facilitator = Clones.cloneDeterministic(facilitatorMultichainImpl, salt);
        
        // initialize the facilitator
        IFacilitatorInitializer(facilitator).initialize(admin, capacity, USDC);
        
        //FacilitatorMultichain facilitator = new FacilitatorMultichain{salt: salt}(admin, capacity, USDC);
        
        emit NewFacilitator(address(facilitator), capacity, messageId, admin);    
    }
    
    function _configFacilitator(address facilitator, uint newCapacity, bytes32 messageId) internal {
        IFacilitator(facilitator).setCapacity(newCapacity);
        
        emit CapacityChanged(facilitator, newCapacity, messageId);
    }
    
    
    /// TODO TODO TODO remove, TESTONLY
    function setVariablesTestOnlyFunction(address _registry) public {
        FACILITATOR_REGISTRY = _registry;            
    }
}
