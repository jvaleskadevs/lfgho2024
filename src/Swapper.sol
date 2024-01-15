// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

import {Test, console2} from "forge-std/Test.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract Swapper {
    ISwapRouter public immutable swapRouter;
    
    constructor(ISwapRouter _router) {
        swapRouter = ISwapRouter(_router);
    }
    
    function swapExactInputSingle(address tokenIn, address tokenOut, uint24 poolFee, uint amountIn) external returns (uint amountOut) {
        // msg.sender must approve this contract
        
        // Transfer the specified amount of token to this contract.
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        
        // Approve the router to spend the token.
        TransferHelper.safeApprove(tokenIn, address(swapRouter), amountIn);
        
        // Naively set amountOutMinimum to 0. In production, use an oracle to be safe.
        // sqrtPriceLimitx96 is 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp + 3000,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });        
        
        // Execute the swap.        
        amountOut = swapRouter.exactInputSingle(params);
    }
}
