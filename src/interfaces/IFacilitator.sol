// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


interface IFacilitator {
    // On increasing capacity, must send GHO equals to the difference
    // On decreasing will receive the difference in GHO tokens
    function setCapacity(uint newCapacity) external;
    // level must be 0, or an amount of GHO equals to level must be deducted, or it will revert
    function removeFacilitator(uint amount) external;
}
