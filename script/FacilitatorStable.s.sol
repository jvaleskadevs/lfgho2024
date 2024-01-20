// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorStable} from "../src/FacilitatorStable.sol";


contract FacilitatorStableScript is Script {
    function setUp() public {}

    function run() public {

        vm.startBroadcast(vm.envUint("PK"));
        
        FacilitatorStable facilitatorImpl = new FacilitatorStable();
        
        vm.stopBroadcast();
    }
}

// forge script script/FacilitatorStable.s.sol:FacilitatorStableScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv


// Deployments:
// 
//  Sepolia: 0x92cd301eDc0F47900c4E5B3ED8668fd4B436C9C6 (impl)
//  Sepolia: 0x5D3156cf2CB74F98BD55505680276A05d6D6F633 (impl)
//  Sepolia: 0xa7f696Cd0aD2EDc564eA249D014545278B9fa8Eb (impl)
