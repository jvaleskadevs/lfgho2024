// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "./interfaces/IGhoToken.sol";
import {IFacilitator} from "./interfaces/IFacilitator.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


// Basic Stable Facilitator
// It swaps GHO:USDC, 1:1, while 0 < level < capacity
contract FacilitatorStable is Initializable, IFacilitator {
    IGhoToken public GHO_TOKEN;
    IERC20 public USDC_TOKEN;
    
    IFacilitator registry;
    
    address public admin;
    
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
/*
    /// initialize admin and token interfaces
    constructor (address _admin, address _gho, address _usdc) {
        admin = _admin;
        GHO_TOKEN = IGhoToken(_gho);
        USDC_TOKEN = IERC20(_usdc);
        registry = IFacilitator(msg.sender);
    }
*/    
    function initialize(address _admin, address _gho, address _usdc) initializer public {
        admin = _admin;
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
    
    function setFacilitatorFee(uint newFee) public onlyAdmin {
        facilitatorFee = newFee;
    }
    
    function setCapacity(uint newCapacity) public onlyAdmin {
        (uint currentCapacity, uint level) = GHO_TOKEN.getFacilitatorBucket(address(this));
        if (currentCapacity < newCapacity) {
            // this amount of GHO must be previously sent to the contract
            GHO_TOKEN.approve(address(registry), newCapacity - currentCapacity);
        } else {
            USDC_TOKEN.transfer(address(registry), level - newCapacity);
        }
        registry.setCapacity(newCapacity);
    }

    function withdrawFees(address recipient, uint amount) public onlyAdmin {
        GHO_TOKEN.transfer(recipient, amount);
    }
    
    function rescueToken(address token, address recipient, uint amount) public onlyAdmin {
        IERC20(token).transfer(recipient, amount);
    }
    
    function setNewAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Forbidden");
        _;
    }
}
