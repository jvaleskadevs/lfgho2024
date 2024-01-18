// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorRegistry} from "../src/FacilitatorRegistry.sol";
import {CUSTOM_GHO, USDC_SEPOLIA, CCIP_ROUTER_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";


contract FacilitatorRegistryScript is Script {
    function setUp() public {}

    function run() public {
        uint facilitatorFee = 420;
        address vaultAddr = 0x7Fdc932b7a717cBDc7979DBAB68061b20503243F;
        vm.startBroadcast(vm.envUint("PK"));
        
        FacilitatorRegistry registry = new FacilitatorRegistry(
            CUSTOM_GHO,
            USDC_SEPOLIA,
            vaultAddr,
            CCIP_ROUTER_SEPOLIA,
            facilitatorFee
        );
        
        setPermissions(address(registry));
        
        vm.stopBroadcast();
    }
    
    function setPermissions(address registry) internal {
        // Facilitator Role
        IGhoToken(CUSTOM_GHO).grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc,
            registry
        );
        
        // Bucket Role
        IGhoToken(CUSTOM_GHO).grantRole(
            0xc7f115822aabac0cd6b9d21b08c0c63819451a58157aecad689d1b5674fad408,
            registry
        );
    }
}

// forge script script/FacilitatorRegistry.s.sol:FacilitatorRegistryScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv
// Deployments
//
// Sepolia: 0xD2d2A9CFa33c0141700F2c0D82f257a0147f6BD7 (failed ccip message, encodePacked/decode)
// Sepolia: 0x9B340aDC9AB242bf4763B798D08e8455778cB4ac (working like a charm, deprecated)
// Sepolia: 0x02fBBa9BF8785400d8113Dda49A3F827927D235c (working like a charm, deprecated)
// Sepolia: 0x1f632B568bda01f4eD8A2849146cc97891512e6A (missing vault approval, lol)
// Sepolia: 0x2D97F21678d075C89ec0d253908d53F5A85802Ea
