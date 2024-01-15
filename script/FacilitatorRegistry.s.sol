// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorRegistry} from "../src/FacilitatorRegistry.sol";
import {CUSTOM_GHO, USDC_SEPOLIA, CCIP_ROUTER_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";


contract FacilitatorRegistryScript is Script {
    function setUp() public {}

    function run() public {
        uint newFacilitatorFee = 420;
        vm.startBroadcast(vm.envUint("PK"));
        
        FacilitatorRegistry registry = new FacilitatorRegistry(
            CUSTOM_GHO,
            USDC_SEPOLIA,
            CCIP_ROUTER_SEPOLIA,
            newFacilitatorFee
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
// Sepolia: 0x9B340aDC9AB242bf4763B798D08e8455778cB4ac
