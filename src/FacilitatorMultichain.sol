// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {IFacilitator} from "./interfaces/IFacilitator.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


// Basic Facilitator Multichain
// It swaps fGHO:USDC, 1:1, while 0 < level < capacity
contract FacilitatorMultichain is Initializable {
    IGhoToken public fGHO_TOKEN;
    IERC20 public USDC_TOKEN;
    
    address public admin;
    IFacilitator public bucketManager;
    
    // a fee must be paid on every mint/burn
    uint256 public facilitatorFee;
    
    /// Emited after a buy of fGHO trough the buy function
    event Bought(
        address indexed buyer,
        uint256 amount,
        bytes data
    );
    
    /// Emited after a sell of fGHO trough the sell function
    event Sold(
        address indexed seller,
        uint256 amount,
        bytes data
    );
 
    constructor () {
        _disableInitializers();
    }
/*   
    /// initialize variables, admin and token interfaces
    /// set max supply equals to capacity ensuring market neutrality
    constructor (address _admin, uint _fee, address _usdc) {
        admin = _admin;
        USDC_TOKEN = IERC20(_usdc);
        fGHO_TOKEN = IGhoToken(0x2B7dfEd198948d9d6A2B60BF79C6E2847fE1CDae);
        bucketManager = IFacilitator(0x9D49d7277E06e05130B79EC78BEF737C9d011d36);
        facilitatorFee = _fee;
    }
*/
    /// initialize variables, admin and token interfaces
    function initialize(address _admin, uint _capacity, address _usdc) initializer public {
        admin = _admin;
        USDC_TOKEN = IERC20(_usdc);
        fGHO_TOKEN = IGhoToken(0x2B7dfEd198948d9d6A2B60BF79C6E2847fE1CDae);
        bucketManager = IFacilitator(0x9D49d7277E06e05130B79EC78BEF737C9d011d36);
        facilitatorFee = 420;
    }

    /// Mints amount of fGHO to caller who deposits amount of USDC, stable swap 1:1
    function buy(uint amount) public {
        require(checkMintBucket(amount), "Bucket");
                
        // get USDC from the caller
        require(USDC_TOKEN.transferFrom(msg.sender, address(this), amount), "Transfer");
        
        if (facilitatorFee != 0) {
            // a fee every user must pay to use this facilitator
            require(USDC_TOKEN.transferFrom(msg.sender, address(this), facilitatorFee), "Fee");
        }
        
        // mint fGHO in exchange
        fGHO_TOKEN.mint(msg.sender, amount);

        emit Bought(msg.sender, amount, "");
    }
    
    /// Burns amount of fGHO from caller who withdraws amount of USDC, stable swap 1:1
    function sell(uint amount) public {
        require(checkBurnBucket(amount), "Bucket");
        
        // get GHO from the caller
        require(fGHO_TOKEN.transferFrom(msg.sender, address(this), amount), "Transfer");
        
        if (facilitatorFee != 0) {
            // a fee every user must pay to use this facilitator
            require(USDC_TOKEN.transferFrom(msg.sender, address(this), facilitatorFee), "Fee");
        }
        
        fGHO_TOKEN.burn(amount);
        
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
        return fGHO_TOKEN.getFacilitatorBucket(address(this));
    }
    
    ////////////////////////////////////////////
    //        ONLY FROM ADMIN
    ///////////////////////////////////////////   
     
    function setFacilitatorFee(uint newFee) public onlyAdmin {
        require(msg.sender == admin, "Forbidden");
        facilitatorFee = newFee;
    }
    
    function setCapacity(uint newCapacity) public onlyAdmin {
        require(msg.sender == admin, "Forbidden");
        (uint currentCapacity, uint level) = bucket();
        if (currentCapacity < newCapacity) {
            // this amount of fGHO must be previously sent to the contract
            fGHO_TOKEN.approve(address(bucketManager), newCapacity - currentCapacity);
        }
        bucketManager.setCapacity(newCapacity);
    }
    
    function setBucketManager(address _bucketManager) public onlyAdmin {
        require(msg.sender == admin, "Forbidden");
        bucketManager = IFacilitator(_bucketManager);
    }
    
    function withdrawFees(address recipient, uint amount) public onlyAdmin {
        fGHO_TOKEN.transfer(recipient, amount);
    }
    
    function rescueToken(address token, address recipient, uint amount) public onlyAdmin {
        IERC20(token).transfer(recipient, amount);
    }
    
    function setNewAdmin(address _admin) public onlyAdmin {
        require(msg.sender == admin, "Forbidden");
        admin = _admin;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Forbidden");
        _;
    }
}

