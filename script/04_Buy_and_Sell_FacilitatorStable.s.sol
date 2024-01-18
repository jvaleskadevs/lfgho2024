// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorStable} from "../src/FacilitatorStable.sol";
import {CUSTOM_GHO, USDC_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract BuyandSellFacilitatorStableScript is Script {
    address facilitatorAddr = 0x4418E27448F6d1c87778543EC7F0A77c27202e75;    
    FacilitatorStable facilitator;
    
    IGhoToken GHO;
    IERC20 IUSDC;
    
    function setUp() public {        
        facilitator = FacilitatorStable(facilitatorAddr);
        
        GHO = IGhoToken(CUSTOM_GHO);
        IUSDC = IERC20(USDC_SEPOLIA);
    }
    
    function run() public {
        uint amount = 4200;
        uint fee = facilitator.facilitatorFee();
        
        vm.startBroadcast(vm.envUint("PK"));
        
        IUSDC.approve(facilitatorAddr, amount+fee);
        
        facilitator.buy(amount);
        
        _sell(amount, fee);
        
        vm.stopBroadcast();
    }
    
    function _sell(uint amount, uint fee) internal {
        IUSDC.approve(facilitatorAddr, fee);
        GHO.approve(facilitatorAddr, amount);
        
        facilitator.sell(amount);
    }
}

// forge script script/04_Buy_and_Sell_FacilitatorStable.s.sol:BuyandSellFacilitatorStableScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv
//
