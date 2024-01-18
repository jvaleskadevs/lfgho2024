// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IGhoToken} from "./interfaces/IGhoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// BucketManager
// Potential implementation of a BucketManager
// where capacity depends on supply and demand.
// _decreaseCapacity will revert if there is not
// enough fGHO locked in this contract.
// this unlocks liquidity strategies,
// and becomes an use case for the fGHO.
// other option is mint/burn on demand.
// No AAVEE, USDC captured could be reallocated to
// other Facilitator, Vault, swaps, lm, lp..
contract BucketManager {   
    IGhoToken public immutable fGHO;
    address public immutable USDC;  
    
    // total amount of fGHO locked in this contract
    uint256 public totalSupply;   
    
    // emited after successfully change the Facilitator capacity
    event CapacityChanged(address indexed facilitator, uint oldCapacity, uint newCapacity);
    
    constructor (address _gho, address _usdc) {
        fGHO = IGhoToken(_gho);
        USDC = _usdc;        
    }
    
    ////////////////////////////////////////////
    //        ONLY FROM FACILITATOR
    ///////////////////////////////////////////    
    
    // only callable from a Facilitator contract
    function setCapacity(uint newCapacity) public {
        (uint currentCapacity, uint level) = bucketOf(msg.sender);
        
        require(currentCapacity > 0, "Forbidden");
        require(newCapacity != currentCapacity, "NothingChanged");
        
        if (newCapacity <= currentCapacity) {
            _decreaseCapacityOf(msg.sender, currentCapacity, newCapacity, level);
        } else {
            _increaseCapacityOf(msg.sender, currentCapacity, newCapacity);
        }
    }

    ////////////////////////////////////////////
    //        INTERNAL FUNCTIONS
    ///////////////////////////////////////////
    
    function _increaseCapacityOf(address facilitator, uint current, uint newCapacity) internal {
        // calculate delta, difference between old and new capacities
        uint delta = newCapacity - current;
        // increase total fGHO locked in the contract 
        totalSupply += delta;      
        // more capacity, more fGHO, deposit
        fGHO.transferFrom(facilitator, address(this), delta);
        //other option:
        // fGHO.burn(facilitator, delta);
        // set new capacity into the fGHO contract
        fGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity));
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }    

    function _decreaseCapacityOf(address facilitator, uint current, uint newCapacity, uint level) internal {
        // calculate delta, difference between old and new capacity
        uint delta = current - newCapacity;
        // decrease total fGHO locked in the contract 
        totalSupply -= delta;
        
        if (newCapacity == 0) {
            // remove the facilitator in the fGHO contract
            fGHO.removeFacilitator(facilitator);
        } else {
            // set new capacity in the fGHO contract
            fGHO.setFacilitatorBucketCapacity(facilitator, uint128(newCapacity));        
        }
        
        // less capacity, less fGHO, withdraw 
        if (level > newCapacity) {
            // cannot withdraw full delta until decrease level
            // so, decreasing it by capturing the remaining in USDC
            // it helps with diversification, USDC and fGHO reserves
            IERC20(USDC).transferFrom(facilitator, address(this), level - newCapacity);
            /// TODO: think about this USDC, no AAVE protocol on every chain, so (?)
        }
        // less capacity, less fGHO, withdraw 
        // need to be the last call to avoid reentrancy
        fGHO.transfer(facilitator, delta);
        //other option:
        // fGHO.mint(facilitator, delta);
        
        emit CapacityChanged(facilitator, current, newCapacity);
    }
    
    ////////////////////////////////////////////
    //        VIEW FUNCTIONS
    ///////////////////////////////////////////
    
    function bucketOf(address sender) public view returns (uint capacity, uint level) {
        (capacity, level) = fGHO.getFacilitatorBucket(sender);
    }
}
