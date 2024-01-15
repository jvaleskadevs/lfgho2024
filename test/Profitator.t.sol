// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {Profitator} from "../src/Profitator.sol";
import {Swapper} from "../src/Swapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {IGhoFlashMinter} from "../src/interfaces/IGhoFlashMinter.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';


contract ProfitatorTest is Test, IERC3156FlashBorrower {
    Profitator public profitator;
    Swapper public swapper;
    //address public GHO = 0xc4bF5CbDaBE595361438F8c6a187bDc330539c60;  // sepolia
    address public GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f; // mainnet
    //address public USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8; // sepolia
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet
    //address public FM = 0xB5d0ef1548D9C70d3E7a96cA67A2d7EbC5b1173E; // sepolia
    address public FM = 0xb639D208Bcf0589D54FaC24E655C79EC529762B8; // mainnet
    // impersonate
    //address private GHO_MANAGER = 0xfA0e305E0f46AB04f00ae6b5f4560d61a2183E00; // sepolia
    address private GHO_MANAGER = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A; // mainnet
    address private USDC_OWNER = 0xC959483DBa39aa9E78757139af0e9a2EDEb3f42D;
    
    //address private UNISWAP_ROUTER = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD; // sepolia
    address private UNISWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // mainnet

    function setUp() public {
        profitator = new Profitator(GHO, USDC);
        swapper = new Swapper(ISwapRouter(UNISWAP_ROUTER));
        this.addFacilitatorImpersonate(GHO_MANAGER, address(profitator));
        //this.mintUSDCImpersonate(USDC_OWNER, 10e6);
        this.receiveETH(0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5, 420 * (10 ** 16));
        this.receiveUSDC(0x7eb6c83AB7D8D9B8618c0Ed973cbEF71d1921EF2, 42420 * (10 ** 6));
        //this.swap(USDC, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, 42000);
    }
    
    function addFacilitatorImpersonate(address target, address facilitator) public {
        vm.prank(target);
        
        // Now you can perform actions on behalf of the impersonated address
        // For example, you can call other contracts or send transactions
        IGhoToken(GHO).addFacilitator(facilitator, "profitator", 420000000);
    }
    
    function mintUSDCImpersonate(address target, uint amount) public {
        uint prevBalance = IERC20(USDC).balanceOf(address(this));
        
        vm.prank(target);
        
        IGhoToken(USDC).mint(address(this), amount);
        assertEq(IERC20(USDC).balanceOf(address(this)), prevBalance + amount); 
    }
    
    function receiveETH(address target, uint amount) public {
        uint prevBalance = address(this).balance;
        vm.prank(target);
        
        (bool success, bytes memory data) = payable(address(this)).call{value: amount}("");
        assertEq(address(this).balance, prevBalance + amount);
    }
    
    receive() external payable {}
    
    function receiveUSDC(address target, uint amount) public {
        uint prevBalance = IERC20(USDC).balanceOf(address(this));
        vm.prank(target);
        
        IERC20(USDC).transfer(address(this), amount);
        assertEq(IERC20(USDC).balanceOf(address(this)), prevBalance + amount); 
    }
    
    
    /////////////////////////////
    //      functions
    /////////////////////////////
   
    function buy(uint amount) public {
        IERC20(USDC).approve(address(profitator), amount);
        profitator.buy(amount);        

    }  
    
    function sell(uint amount) public {
        IERC20(GHO).approve(address(profitator), amount);
        profitator.sell(amount);
    }  

    /////////////////////////////
    //      tests
    /////////////////////////////
/*   
    function test_Buy() public {
        buy(1);
        
        (uint capacity, uint level) = profitator.bucket();
        assertEq(level, 1);
        assertEq(IGhoToken(GHO).balanceOf(address(this)), 1);
        assertEq(IERC20(USDC).balanceOf(address(this)), 10e6 - 1);
        assertEq(IERC20(USDC).balanceOf(address(profitator)), 1);
    }
    
    function test_Sell() public {
        buy(1);
        sell(1);
        
        (uint capacity, uint level) = profitator.bucket();
        assertEq(level, 0);
        assertEq(IGhoToken(GHO).balanceOf(address(this)), 0);
        assertEq(IERC20(USDC).balanceOf(address(this)), 10e6);
        assertEq(IERC20(USDC).balanceOf(address(profitator)), 0);
    }
    
    function testFail_Buy() public {
        buy(420000001);
    }
    
    function testFail_Sell() public {
        sell(1);
    }
*/    
    function test_FlashLoan() public {
        bool success = IGhoFlashMinter(FM).flashLoan(
            IERC3156FlashBorrower(address(this)),
            GHO,
            420,
            ""
        );
        assertEq(success, true);
        assertEq(IERC20(GHO).balanceOf(address(this)), 0); 
        assertEq(IERC20(USDC).balanceOf(address(this)), 42419999580);
    }
    
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        //sell(amount); // 42420, 42000 + 420
        assertEq(IERC20(GHO).balanceOf(address(this)), amount);
        // uniswap sell, take profits
        //simulateSwap(amount+fee);
        swap(GHO, USDC, amount+fee);
        
        console2.log(IERC20(USDC).balanceOf(address(this))); // 42420000000
        
        //sell(amount);
        buy(amount+fee); // 420
        
        IGhoToken(token).approve(FM, amount+fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
    
    function simulateSwap(uint amount) public {
        // simulating swap, sending gho out to another account
        IGhoToken(GHO).transfer(USDC_OWNER, amount);
        
        // simulating the USDC returns from the swap, 1.01 per GHO sent out
        mintUSDCImpersonate(USDC_OWNER, amount + 4242);
    }
    
    function swap(address tokenIn, address tokenOut, uint amount) public {
        IERC20(tokenIn).balanceOf(address(this));
        IERC20(tokenIn).approve(address(swapper), amount);
        uint amountOut = swapper.swapExactInputSingle(tokenIn, tokenOut, 3000, amount);    
    }
/*    
    function lockAcquired(address lockCaller, bytes calldata data) external returns (bytes memory) {
        
    }
*/
/*
    function testFuzz_Buy(uint256 x) public {
        if (x == 0) {
          return;
        }
        profitator.buy(x); 
        (uint capacity, uint level) = profitator.bucket();
        assertEq(level, x);
    }
    
    function testFuzz_Sell(uint256 x) public {
        if (x == 0) {
          return;
        }
        profitator.sell(x); 
        (uint capacity, uint level) = profitator.bucket();
        assertEq(level, 0);
    }
*/
}
