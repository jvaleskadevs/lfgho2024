// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorMultichain} from "../src/FacilitatorMultichain.sol";


contract FacilitatorMultichainScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PK"));
        
        FacilitatorMultichain facilitatorImpl = new FacilitatorMultichain();
        
        vm.stopBroadcast();
    }
}

// forge script script/FacilitatorMultichain.s.sol:FacilitatorMultichainScript --rpc-url $OPTIMISM_GOERLI_URL --broadcast --verify -vvvv


// Deployments:
// 
//  Optimism Goerli -> 0x2651E8a897B340D64D8357756342B53ecfCc94ca (from MultichainListener)
//  Optimism Goerli -> 0x5a140e344C57cA6bcc506672e4EDFD9ede8eE808 (from this script) (impl)
//  Optimism Goerli -> 0x2651E8a897B340D64D8357756342B53ecfCc94ca (from MultichainListener) (proxy)
//  Optimism Goerli -> 0xaC514223BA87823346fC41340f3E639d7795E755 (from MultichainListener) (proxy)
//  Optimism Goerli -> 0xc902f62AF380D372A67aCC01f40BDb6483AEe5CF (from this script) (impl)
//  Optimism Goerli -> 0x825E62e439e17c270E99a959E1e9263A273228b4 (from this script) (impl)
//  Optimism Goerli -> 0x6dec820eD9007602e7EfA4BC6A668FdCE0Fd8Ad5 (from this script) (impl)
//  Optimism Goerli ->  (from MultichainListener) (proxy)
//  Optimism Goerli -> 0x6721c3439D98B99EB7580c7F27A977AE9f49dc38 (from this script) (impl)
//  Optimism Goerli -> 0x7a7cceff68b87ebe0fc981e58165791730485f76 (from MultichainListener) (proxy)
//  Optimism Goerli ->  (from MultichainListener) (proxy)
