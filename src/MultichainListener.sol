// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {FacilitatorMultichain} from "./FacilitatorMultichain.sol";
import {USDC} from "../utils/Constants.sol";


contract MultichainListener is CCIPReceiver {
    address /*immutable*/ FACILITATOR_REGISTRY;
    
    event NewFacilitator(address facilitator, uint256 capacity, bytes32 messageId, address admin);
    
    constructor(address _router, address _registry) CCIPReceiver(_router) {
        FACILITATOR_REGISTRY = _registry;
    }
    
    function _ccipReceive(Client.Any2EVMMessage memory receivedMessage) internal override {
        
        (address sender) = abi.decode(receivedMessage.sender, (address));
        require(sender == FACILITATOR_REGISTRY, "OnlyFromRegistry");
        
        uint64 sourceChainSelector = receivedMessage.sourceChainSelector;
        require(
            sourceChainSelector == 5009297550715157269 || // mainnet
            sourceChainSelector == 16015286601757825753,  // sepolia /// TODO remove, TESTONLY
        "OnlyFromMainnet");
        
        (address admin, uint256 capacity, bytes32 salt) = abi.decode(
            receivedMessage.data, 
            (address, uint256, bytes32)
        );
        
        FacilitatorMultichain facilitator = new FacilitatorMultichain{salt: salt}(admin, capacity, USDC);
        
        emit NewFacilitator(address(facilitator), capacity, receivedMessage.messageId, admin);
    }
    
    receive() external payable {}
    
    
    /// TODO TODO TODO remove, TESTONLY
    function setVariablesTestOnlyFunction(address _registry) public {
        FACILITATOR_REGISTRY = _registry;            
    }
}

// Deployments:
// 
//  Optimism Goerli -> 0x7E7DA3a8D45349110EeD866047307bD34BE85996
