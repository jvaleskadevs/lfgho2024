// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {FlaminGHO} from "../src/FlaminGHO.sol";

contract FlaminGHOTest is Test { 
    FlaminGHO fGHO;
    
    function setUp() public {        
        fGHO = new FlaminGHO(address(this));
        
        fGHO.grantRole(0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, address(this));
        
        fGHO.addFacilitator(address(this), "lfgho", 42000);
    }
    
    function test_Mint_and_Burn() public {
        uint amount = 42000;
        
        fGHO.mint(address(this), amount);
        
        assertEq(fGHO.balanceOf(address(this)), amount);
        
        _burn(amount);
    }

    function _burn(uint amount) internal {
        fGHO.burn(amount);
        
        assertEq(fGHO.balanceOf(address(this)), 0);
    } 
}
