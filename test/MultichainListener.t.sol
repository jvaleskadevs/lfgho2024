// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {MultichainListener} from "../src/MultichainListener.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {FLAMINGHO_OPT_GOERLI} from "../utils/Constants.sol";

// OUTDATED TESTS
/*
contract MultichainListenerTest is Test {
    
    function setUp() public {}
   
    function test_MultichainListene() public {
        //MultichainListener ml = MultichainListener(payable(0x6BA96594e94d5B12F1ef689d5D69E006d056B1Ad));
        
        MultichainListener ml = new MultichainListener(
            0xcc5a0B910D9E9504A7561934bed294c51285a78D, // router // opt goerli
            0x9B340aDC9AB242bf4763B798D08e8455778cB4ac, // registry // sepolia
            0x2B7dfEd198948d9d6A2B60BF79C6E2847fE1CDae // flaminGHO
        );
        
        vm.prank(0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a);
        IGhoToken(FLAMINGHO_OPT_GOERLI).grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, 
            address(ml)
        ); 
        
        address admin = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
        uint256 capacity = 42000;
        bytes32 salt = keccak256(abi.encodePacked("lfgho_2024_clone", admin));
        
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: salt,
            sourceChainSelector: 16015286601757825753, // sepolia
            sender: abi.encode(0x9B340aDC9AB242bf4763B798D08e8455778cB4ac),
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
*/
