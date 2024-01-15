// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {MultichainListener} from "../src/MultichainListener.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract MultichainListenerTest is Test {
    
    function setUp() public {}
    
    function test_MultichainListene() public {
        //MultichainListener ml = MultichainListener(payable(0x7E7DA3a8D45349110EeD866047307bD34BE85996));
        MultichainListener ml = new MultichainListener(
            0xcc5a0B910D9E9504A7561934bed294c51285a78D,
            0xD2d2A9CFa33c0141700F2c0D82f257a0147f6BD7
        );

        address admin = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
        uint256 capacity = 42000;
        bytes32 salt = keccak256(abi.encodePacked("lfgho2024", admin));
        
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: salt,
            sourceChainSelector: 16015286601757825753, // sepolia
            sender: abi.encode(0xD2d2A9CFa33c0141700F2c0D82f257a0147f6BD7),
            data: abi.encode(admin, capacity, salt),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        bytes memory data = abi.encode(admin, capacity, salt);
        
        (address _admin, uint256 _capacity, bytes32 _salt) = abi.decode(data, (address, uint256, bytes32));
        
        assertEq(admin, _admin);
        assertEq(capacity, _capacity);
        assertEq(salt, _salt);
        
        vm.prank(0xcc5a0B910D9E9504A7561934bed294c51285a78D);
        ml.ccipReceive(message);
    }
}
