// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {MultichainListener} from "../src/MultichainListener.sol";
import {FLAMINGHO_OPT_GOERLI} from "../utils/Constants.sol";


contract SetRegistryScript is Script {
    MultichainListener multichainListener;
    
    function setUp() public {
        multichainListener = MultichainListener(0x9B340aDC9AB242bf4763B798D08e8455778cB4ac);
    }

    function run() public {
        vm.startBroadcast(vm.envUint("PK"));
        
        multichainListener.setVariablesTestOnlyFunction(
            0x2D97F21678d075C89ec0d253908d53F5A85802Ea, // registry
            FLAMINGHO_OPT_GOERLI
        );
        
        vm.stopBroadcast();
    }
}

/*

contract SetRegistryScript is Script {
    FacilitatorRegistry registry;
    
    function setUp() public {
        registry = new FacilitatorRegistry(0x02fBBa9BF8785400d8113Dda49A3F827927D235c);
    }

    function run() public {
        uint facilitatorFee = 420;
        vm.startBroadcast(vm.envUint("PK"));
        
        
        
        vm.stopBroadcast();
    }
}

*/

// forge script script/00_Set_Registry.s.sol:SetRegistryScript --rpc-url $OPTIMISM_GOERLI_URL --broadcast --verify -vvvv
