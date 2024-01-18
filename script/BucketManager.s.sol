// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {BucketManager} from "../src/BucketManager.sol";
import {IGhoToken} from "../src//interfaces/IGhoToken.sol";
import {FLAMINGHO_OPT_GOERLI, USDC_OPT_GOERLI} from "../utils/Constants.sol";


contract BucketManagerScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast(vm.envUint("PK"));
        
        BucketManager bm = new BucketManager(
            FLAMINGHO_OPT_GOERLI, // fGHO
            USDC_OPT_GOERLI
        );
        
        IGhoToken(FLAMINGHO_OPT_GOERLI).grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, 
            address(bm)
        );        

        IGhoToken(FLAMINGHO_OPT_GOERLI).grantRole(
            0xc7f115822aabac0cd6b9d21b08c0c63819451a58157aecad689d1b5674fad408, 
            address(bm)
        );
        
        vm.stopBroadcast();
    }
}

// forge script script/BucketManager.s.sol:BucketManagerScript --rpc-url $OPTIMISM_GOERLI_URL --broadcast --verify -vvvv


// Deployments:
// 
//  Optimism Goerli -> 0xA1688A98f2eFd3Af302C008f3Ab471c5E8512421
//  Optimism Goerli -> 0x9D49d7277E06e05130B79EC78BEF737C9d011d36
