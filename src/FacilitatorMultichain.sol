// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract FacilitatorMultichain is Ownable, ERC20, ERC20Burnable, ERC20Permit {
    IERC20 public immutable USDC_TOKEN;
    
    // maxSupply == capacity, totalSupply == level
    uint256 public maxSupply;
    
    // fee paid on every mint/burn
    uint256 public facilitatorFee; // TODO it is undefined lol, need to reploy Listener, and Multichain
    
    /// Emited after a buy of mGHO trough the buy function
    event Bought(
        address indexed buyer,
        uint256 amount,
        bytes data
    );
    
    /// Emited after a sell of mGHO trough the sell function
    event Sold(
        address indexed seller,
        uint256 amount,
        bytes data
    );

    /// initialize variables, admin and token interfaces
    /// set max supply equals to capacity ensuring market neutrality
    constructor (address _admin, uint _capacity, address _usdc)
        ERC20("multichainGHO", "mGHO") ERC20Permit("mGHO") Ownable(_admin) {
            USDC_TOKEN = IERC20(_usdc);
            maxSupply = _capacity;
    }

    /// Mints amount of mGHO, pays amount of USDC, stable swap 1:1
    function buy(uint amount) public {
        require(checkMintBucket(amount), "Bucket");
        require(USDC_TOKEN.transferFrom(msg.sender, address(this), amount), "Transfer");
        // a fee every user must pay to use the service
        require(USDC_TOKEN.transferFrom(msg.sender, address(this), facilitatorFee), "Fee");

        // simulate facilitator call here
        _mint(msg.sender, amount);
        
        // event
        emit Bought(msg.sender, amount, "");
    }
    
    /// Burns amount of mGHO, gets amount of USDC, stable swap 1:1
    function sell(uint amount) public {
        require(checkBurnBucket(amount), "Bucket");
        require(transferFrom(msg.sender, address(this), amount), "Transfer");
        // a fee every user must pay to use the service
        require(USDC_TOKEN.transferFrom(msg.sender, address(this), facilitatorFee), "Fee");
        // simulate facilitator call here
        _burn(address(this), amount);
        
        // send USDC in exchange
        require(USDC_TOKEN.transfer(msg.sender, amount), "Transfer");
        
        // event
        emit Sold(msg.sender, amount, "");
    }
    
    ////////////////////////////////////////////
    //        VIEW FUNCTIONS
    ///////////////////////////////////////////
    
    function checkMintBucket(uint amount) public view returns (bool) {
        return amount != 0 && totalSupply() + amount <= maxSupply;
    }
    
    function checkBurnBucket(uint amount) public view returns (bool) {
        // will panick before return false, underflow operation
        // anyway, false will be force to revert later, we are safe 
        return amount != 0 && totalSupply() - amount >= 0;
    }
    
    receive() external payable {}
}
