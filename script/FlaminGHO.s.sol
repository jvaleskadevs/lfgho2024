// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FlaminGHO} from "../src/FlaminGHO.sol";


contract FlaminGHOScript is Script {
    function setUp() public {}

    function run() public {
        address deployer = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
        vm.startBroadcast(vm.envUint("PK"));
        
        FlaminGHO flaminGHO = new FlaminGHO(deployer);
        
        /*
        flaminGHO.grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, 
            multichainListener
        );
        */
        
        vm.stopBroadcast();
    }
}

// forge script script/FlaminGHO.s.sol:FlaminGHOScript --rpc-url $OPTIMISM_GOERLI_URL --broadcast --verify -vvvv


// Deployments:
// 
// Optimism Goerli -> 0x2B7dfEd198948d9d6A2B60BF79C6E2847fE1CDae

