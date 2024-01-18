// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorMultichain} from "../src/FacilitatorMultichain.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {USDC_OPT_GOERLI, FLAMINGHO_OPT_GOERLI } from "../utils/Constants.sol";

/*
  
  IMPORTANT.
  
  no USDC to test on Optimism Goerli
  Circle just deprecated it...
  
  Anyway, it is passing the tests on a fork
*/
contract FacilitatorMultichainScript is Script {
    FacilitatorMultichain facilitator;
    address public facilitatorAddr = 0x7a7CceFF68B87EbE0fc981E58165791730485f76; // opt goerli
    
    IERC20 IUSDC;
    IGhoToken fGHO;
    
    function setUp() public {
        facilitator = FacilitatorMultichain(facilitatorAddr);
        
        IUSDC = IGhoToken(USDC_OPT_GOERLI);
        fGHO = IGhoToken(FLAMINGHO_OPT_GOERLI);
    }
    
    function run() public {
        uint amount = 42000;
        uint fee = facilitator.facilitatorFee();    
    
        vm.startBroadcast();
        
        IUSDC.approve(facilitatorAddr, amount+fee);
        
        facilitator.buy(amount);
        
        _sell(amount, fee);
        
        vm.stopBroadcast();
    }

    function _sell(uint amount, uint fee) internal {
        IUSDC.approve(facilitatorAddr, fee);
        fGHO.approve(facilitatorAddr, amount);
        
        facilitator.sell(amount);
    }
}

// forge script script/02_Buy_and_Sell_Multichain.s.sol:FacilitatorMultichainScript --rpc-url $OPTIMISM_GOERLI_URL --broadcast --verify -vvvv

