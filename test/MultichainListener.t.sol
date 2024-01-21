// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {MultichainListener} from "../src/MultichainListener.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {FLAMINGHO_OPT_GOERLI, USDC_OPT_GOERLI} from "../utils/Constants.sol";


contract MultichainListenerTest is Test {
    
    function setUp() public {}
   
    function test_MultichainListene() public {
        MultichainListener ml = MultichainListener(0x9B340aDC9AB242bf4763B798D08e8455778cB4ac);
        
        /*
        MultichainListener ml = new MultichainListener(
            0xcc5a0B910D9E9504A7561934bed294c51285a78D, // router // opt goerli
            0x9B340aDC9AB242bf4763B798D08e8455778cB4ac, // registry // sepolia
            0x2B7dfEd198948d9d6A2B60BF79C6E2847fE1CDae // flaminGHO
        );
        */
        address admin = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
        uint256 capacity = 42000;        
        
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,uint256,address)",
            admin, capacity, USDC_OPT_GOERLI
        ); 

        vm.prank(admin);                
        IGhoToken(FLAMINGHO_OPT_GOERLI).grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, 
            address(ml)
        );        
        
        address facilitatorImpl = 0x12fC262Bd99Cb3f8A1cEdb58bf9A760Eea3427bC;
        
        bytes memory data = abi.encode(facilitatorImpl, capacity, initData);        
        (address _impl, uint256 _capacity, bytes memory _initData) = abi.decode(data, (address, uint256, bytes));
        
        assertEq(facilitatorImpl, _impl);
        assertEq(capacity, _capacity);
        assertEq(initData, _initData);
        
        address registryAddr = 0x2D97F21678d075C89ec0d253908d53F5A85802Ea;
        
        Client.Any2EVMMessage memory message = Client.Any2EVMMessage({
            messageId: keccak256("messageID"),
            sourceChainSelector: 16015286601757825753, // sepolia
            sender: abi.encode(registryAddr),
            data: abi.encode(facilitatorImpl, capacity, initData),
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });
        
        vm.prank(0xcc5a0B910D9E9504A7561934bed294c51285a78D);
        ml.ccipReceive(message);
    }
}
// forge test --match-path test/MultichainListener.t.sol --fork-url $OPTIMISM_GOERLI_URL  -vvvvv
