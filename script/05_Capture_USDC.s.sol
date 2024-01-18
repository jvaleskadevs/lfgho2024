// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorRegistry} from "../src/FacilitatorRegistry.sol";
import {FacilitatorStable} from "../src/FacilitatorStable.sol";
import {IFacilitator} from "../src/interfaces/IFacilitator.sol";
import {CUSTOM_GHO, USDC_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract CaptureUSDCScript is Script {
    FacilitatorRegistry registry;
    IGhoToken gho;
    IERC20 usdc;
    FacilitatorStable facilitator;
    
    address deployer = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
    address facilitatorRegistry = 0x2D97F21678d075C89ec0d253908d53F5A85802Ea;
    address facilitatorStableAddr = 0x4418E27448F6d1c87778543EC7F0A77c27202e75;

    function setUp() public {
        registry = FacilitatorRegistry(facilitatorRegistry);
        gho = IGhoToken(CUSTOM_GHO);
        usdc = IERC20(USDC_SEPOLIA);
        
        facilitator = FacilitatorStable(facilitatorStableAddr);
    }

    function run() public {
        uint amount = 4200;
        uint delta = 420;
        (uint currentCapacity, uint level) = gho.getFacilitatorBucket(facilitatorStableAddr);
    
        vm.startBroadcast(vm.envUint("PK"));
        
        usdc.approve(facilitatorStableAddr, amount);
        facilitator.buy(amount);       

        gho.transfer(facilitatorStableAddr, delta);        
        facilitator.setCapacity(currentCapacity+delta);
        
        facilitator.setCapacity(1);
        
        vm.stopBroadcast();
    }
}

// forge script script/05_Capture_USDC.s.sol:CaptureUSDCScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv


