// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {MultichainListener} from "../src/MultichainListener.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {FLAMINGHO_OPT_GOERLI, CCIP_ROUTER_OPT_GOERLI, USDC_OPT_GOERLI} from "../utils/Constants.sol";


contract MultichainListenerScript is Script {
    function setUp() public {}

    function run() public {
        address facilitatorRegistry = 0x02fBBa9BF8785400d8113Dda49A3F827927D235c; // sepolia

        vm.startBroadcast(vm.envUint("PK"));
        
        MultichainListener ml = new MultichainListener(
            CCIP_ROUTER_OPT_GOERLI,
            facilitatorRegistry, // sepolia
            FLAMINGHO_OPT_GOERLI // fGHO
        );
        
        IGhoToken(FLAMINGHO_OPT_GOERLI).grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, 
            address(ml)
        );        
        
        vm.stopBroadcast();
    }
}

// forge script script/MultichainListener.s.sol:MultichainListenerScript --rpc-url $OPTIMISM_GOERLI_URL --broadcast --verify -vvvv


// Deployments:
// 
//  Optimism Goerli -> 0x7E7DA3a8D45349110EeD866047307bD34BE85996
//  Optimism Goerli -> 0x6BA96594e94d5B12F1ef689d5D69E006d056B1Ad
//  Optimism Goelri -> 0xEBa15c28A6570407785D4547f191e92ea91F42e4
//  Optimism Goelri -> 0xdC8c8c8C6F360833F608acFC72D4593960d34Ce5
//  Optimism Goerli -> 0x9B340aDC9AB242bf4763B798D08e8455778cB4ac
