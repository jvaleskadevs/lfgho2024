// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "./interfaces/IGhoToken.sol";
import {IFacilitator} from "./interfaces/IFacilitator.sol";


// Basic Stable Facilitator
// It swaps GHO:USDC, 1:1, while 0 < level < capacity
contract FacilitatorStable is IFacilitator, Ownable {
    IGhoToken public immutable GHO_TOKEN;
    IERC20 public immutable USDC_TOKEN;
    
    IFacilitator registry;
    
    // fee paid on every mint/burn
    uint256 public facilitatorFee;
    
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

    /// initialize admin and token interfaces
    constructor (address _admin, address _gho, address _usdc) Ownable(_admin) {
        GHO_TOKEN = IGhoToken(_gho);
        USDC_TOKEN = IERC20(_usdc);
        registry = IFacilitator(msg.sender);
    }
    
    ////////////////////////////////////////////
    //        WRITE FUNCTIONS
    ///////////////////////////////////////////

    /// Mints amount of GHO, pays amount of USDC, stable swap 1:1
    function buy(uint amount) public {
        require(checkMintBucket(amount), "Bucket");
        require(USDC_TOKEN.transferFrom(msg.sender, address(this), amount), "Transfer");
        
        // a fee every user must pay to use the service
        require(GHO_TOKEN.transferFrom(msg.sender, address(this), facilitatorFee), "Fee");

        GHO_TOKEN.mint(msg.sender, amount);
        
        emit Bought(msg.sender, amount, "");
    }
    
    /// Burns amount of GHO, gets amount of USDC, stable swap 1:1
    function sell(uint amount) public {
        require(checkBurnBucket(amount), "Bucket");
        require(GHO_TOKEN.transferFrom(msg.sender, address(this), amount), "Transfer");

        // a fee every user must pay to use the service
        require(GHO_TOKEN.transferFrom(msg.sender, address(this), facilitatorFee), "Fee");

        GHO_TOKEN.burn(amount);
        
        // send USDC in exchange
        require(USDC_TOKEN.transfer(msg.sender, amount), "Transfer");
        
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
        return amount != 0 && amount <= level;
    }
    
    function bucket() public view returns (uint capacity, uint level) {
        return GHO_TOKEN.getFacilitatorBucket(address(this));
    }   
    
    ////////////////////////////////////////////
    //        ADMIN FUNCTIONS
    ///////////////////////////////////////////
    
    function setFacilitatorFee(uint newFee) public onlyOwner {
        facilitatorFee = newFee;
    }
    
    function setCapacity(uint newCapacity) public onlyOwner {
        (uint currentCapacity, uint level) = GHO_TOKEN.getFacilitatorBucket(address(this));
        if (currentCapacity < newCapacity) {
            GHO_TOKEN.approve(address(registry), newCapacity - currentCapacity);
        }
        registry.setCapacity(newCapacity);
    }
    
    function removeFacilitator(uint amount) public onlyOwner {
        if (amount != 0) {
            GHO_TOKEN.approve(address(registry), amount);
        }
        registry.removeFacilitator(amount);
    }

    function rescueGHO(address recipient, uint amount) public onlyOwner {
        GHO_TOKEN.transfer(recipient, amount);
    }
}
