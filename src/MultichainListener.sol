// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IGhoToken} from "./interfaces/IGhoToken.sol";
import "@openzeppelin/contracts/utils/Create2.sol";


contract MultichainListener is CCIPReceiver {
    error InitializationFailed();
    
    address /*immutable*/ facilitatorRegistry;
    IGhoToken /*immutable*/ fGHO;
    
    event NewFacilitator(address indexed facilitator, uint256 capacity, bytes32 messageId);
    
    constructor(
        address _router, 
        address _registry,
        address _fgho
    ) CCIPReceiver(_router) {
        facilitatorRegistry = _registry;
        fGHO = IGhoToken(_fgho);
    }
    
    // receives CCIP messages from the FacilitatorRegistry on Mainnet or Sepolia
    function _ccipReceive(Client.Any2EVMMessage memory receivedMessage) internal override {
        // check the sender is the Registry, or revert
        (address sender) = abi.decode(receivedMessage.sender, (address));
        require(sender == facilitatorRegistry, "OnlyFromRegistry");
        
        // check the message comes from Mainnet or Sepolia, or revert
        uint64 sourceChainSelector = receivedMessage.sourceChainSelector;
        require(
            sourceChainSelector == 5009297550715157269 || // mainnet
            sourceChainSelector == 16015286601757825753,  // sepolia /// TODO TESTONLY
        "OnlyFromMainnet");
        
        // decode the received message
        (address impl, uint256 capacity, bytes memory initData) = abi.decode(
            receivedMessage.data, 
            (address, uint256, bytes)
        );
        
        // calc salt from initData and capacity
        bytes32 salt = keccak256(abi.encodePacked(capacity, initData));
        
        // build the creationCode to be deployed with Create2
        bytes memory code = _creationCode(
            impl, 
            block.chainid,
            uint(salt)
        );

        // precompute the address for the Facilitator contract
        address facilitator = Create2.computeAddress(salt, keccak256(code));
        // revert if the contract was previously deployed
        if (facilitator.code.length != 0) revert InitializationFailed();

        // deploy the Facilitator
        facilitator = Create2.deploy(0, salt, code);
        // initialize
        (bool success, ) = facilitator.call(initData);
        if (!success) revert InitializationFailed();
        
        // add the Facilitator to the flaminGHO token contract
        fGHO.addFacilitator(facilitator, string(abi.encodePacked(salt)), uint128(capacity));
        
        emit NewFacilitator(facilitator, capacity, receivedMessage.messageId);
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
    
    /// TODO TODO TODO remove, TESTONLY
    function setVariablesTestOnlyFunction(address _registry, address _fgho) public {
        facilitatorRegistry = _registry;
        fGHO = IGhoToken(_fgho);         
    }
}
