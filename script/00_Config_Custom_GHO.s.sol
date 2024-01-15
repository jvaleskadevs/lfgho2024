// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {CUSTOM_GHO, USDC_SEPOLIA, CCIP_ROUTER_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";


contract ConfigCustomGHOScript is Script {
    IGhoToken gho;
    
    address deployer = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;

    function setUp() public {
        gho = IGhoToken(CUSTOM_GHO);
    }

    function run() public {    
        vm.startBroadcast(vm.envUint("PK"));
        
        gho.grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, 
            deployer
        );
        
        gho.addFacilitator(deployer, "freegholol", type(uint128).max);
        
        gho.mint(deployer, 42069 * 10e18);
        
        vm.stopBroadcast();
    }
}

// forge script script/00_Config_Custom_GHO.s.sol:ConfigCustomGHOScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv

