// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {FacilitatorMultichain} from "../src/FacilitatorMultichain.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {USDC_OPT_GOERLI} from "../utils/Constants.sol";


contract FacilitatorMultichainTest is Test {
    FacilitatorMultichain facilitator;
    address public facilitatorAddr = 0x2651E8a897B340D64D8357756342B53ecfCc94ca;
    
    IERC20 IUSDC;
    
    function setUp() public {
        facilitator = FacilitatorMultichain(payable(facilitatorAddr)); // opt goerli
        
        IUSDC = IERC20(USDC_OPT_GOERLI);
    }
    
    function test_Buy() public {
        uint amount = 42000;
        uint fee = 420;
        
        IUSDC.approve(facilitatorAddr, amount+fee);
        
        facilitator.buy(amount);
        
        assertEq(IUSDC.balanceOf(facilitatorAddr), amount+fee);       
        assertEq(facilitator.checkMintBucket(1), false); 
    }

    function test_Sell() public {
        uint amount = 42000;
        uint fee = 420;
        
        IUSDC.approve(facilitatorAddr, fee);
        
        facilitator.sell(amount);
        
        assertEq(facilitator.checkBurnBucket(1), false);
    }










    function mintUSDC() public {
        uint prevBalance = IUSDC.balanceOf(address(this));
        vm.prank(0xCD2c33E2FAcFC36F0254FFb73AF0e8f4F81b26d5);
        
        IGhoToken(USDC_OPT_GOERLI).mint(address(this), 10e6 * 10e6); // 10M USDC
        assertEq(IUSDC.balanceOf(address(this)), prevBalance + 10e6 * 10e6); 
    }      
}
