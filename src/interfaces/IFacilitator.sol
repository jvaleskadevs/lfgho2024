// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// On increasing capacity, must send GHO/fGHO equals to the difference
// On decreasing will receive the difference in GHO/fGHO tokens
// On decreasing, any amount > level will be captured in USDC  
interface IFacilitator {  
    // set a new capacity for a facilitator
    function setCapacity(uint newCapacity) external;
    // get the capacity and level of a facilitator
    function bucket() external view returns (uint capacity, uint level);
}
