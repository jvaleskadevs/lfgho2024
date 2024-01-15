// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "./interfaces/IGhoToken.sol";

contract Profitator {
    IGhoToken public immutable GHO_TOKEN;  // 0xc4bF5CbDaBE595361438F8c6a187bDc330539c60
    IERC20 public immutable USDC_TOKEN; // 0x94a9d9ac8a22534e3faca9f4e7f2e2cf85d5e4c8
    
    /// Emited after a buy of GHO trough the buy function
    event Bought(
        address indexed buyer,
        uint256 amount,
        bytes data
    );
    
    /// Emited after a sell of GHO trough the sell function
    event Sold(
        address indexed seller,
        uint256 amount,
        bytes data
    );

    /// initialize the token interfaces
    constructor (address _gho, address _usdc) {
        GHO_TOKEN = IGhoToken(_gho);
        USDC_TOKEN = IERC20(_usdc);
    }

    /// Mints amount of GHO, pays amount in USDC, stable swap 1:1
    function buy(uint amount) public {
        require(checkMintBucket(amount), "Bucket");
        require(USDC_TOKEN.transferFrom(msg.sender, address(this), amount), "Transfer");

        // call facilitator here
        GHO_TOKEN.mint(msg.sender, amount);
        
        // event
        emit Bought(msg.sender, amount, "");
    }
    
    /// Burns amount of GHO, gets amount in USDC, stable swap 1:1
    function sell(uint amount) public {
        require(checkBurnBucket(amount), "Bucket");
        require(GHO_TOKEN.transferFrom(msg.sender, address(this), amount), "Transfer");

        // call facilitator here
        GHO_TOKEN.burn(amount);
        
        // send USDC in exchange
        require(USDC_TOKEN.transfer(msg.sender, amount), "Transfer");
        
        // event
        emit Sold(msg.sender, amount, "");
    }
    
    
    ////////////////////////////////////////////
    //        VIEW FUNCTIONS
    ///////////////////////////////////////////
    
    function checkMintBucket(uint amount) public view returns (bool) {
        (uint256 capacity, uint256 level) = bucket();
        return amount != 0 && level + amount <= capacity;
    }
    
    function checkBurnBucket(uint amount) public view returns (bool) {
        (uint capacity, uint level) = bucket();
        return amount != 0 && level - amount >= 0;
    }
    
    function bucket() public view returns (uint capacity, uint level) {
        return GHO_TOKEN.getFacilitatorBucket(address(this));
    }
}
