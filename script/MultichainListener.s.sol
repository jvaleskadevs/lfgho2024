// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {MultichainListener} from "../src/MultichainListener.sol";


contract MultichainListenerScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PK"));
        
        MultichainListener ml = new MultichainListener(
            0xcc5a0B910D9E9504A7561934bed294c51285a78D, // CCIP_ROUTER // opt goerli
            0x0000000000000000000000000000000000000000  // registry placeholder
        );
        
        vm.stopBroadcast();
    }
}

// forge script script/MultichainListener.s.sol:MultichainListenerScript --rpc-url $OPTIMISM_GOERLI_URL --broadcast --verify -vvvv

