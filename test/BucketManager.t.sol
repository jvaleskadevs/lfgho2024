// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {BucketManager} from "../src/BucketManager.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {FLAMINGHO_OPT_GOERLI} from "../utils/Constants.sol";

contract BucketManagerTest is Test {
    BucketManager bm;
    IGhoToken fGHO;
    
    function setUp() public {
        bm = BucketManager(0x9D49d7277E06e05130B79EC78BEF737C9d011d36);
        
        fGHO = IGhoToken(FLAMINGHO_OPT_GOERLI);  
    }
   
    function test_BucketManager() public {
        address facilitator = 0x6dec820eD9007602e7EfA4BC6A668FdCE0Fd8Ad5;
        uint capacity = 42000;
        uint delta = 420;
        
        address admin = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
        vm.startPrank(admin);
        fGHO.grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc, 
            admin
        );
        fGHO.grantRole(
            0xc7f115822aabac0cd6b9d21b08c0c63819451a58157aecad689d1b5674fad408, 
            admin
        );
        fGHO.addFacilitator(admin, "admin", uint128(delta));
        fGHO.addFacilitator(facilitator, "facilitator", uint128(capacity));
        fGHO.setFacilitatorBucketCapacity(admin, uint128(delta));
        fGHO.mint(facilitator, delta);
        vm.stopPrank();
        
        vm.startPrank(facilitator);  
        
        (uint currentCapacity, uint level) = bm.bucketOf(facilitator);
        
        fGHO.approve(address(bm), delta);
        
        bm.setCapacity(currentCapacity+delta);
        
        (uint newCapacity, ) = bm.bucketOf(facilitator);
        
        assertEq(newCapacity, currentCapacity+delta);
        assertEq(fGHO.balanceOf(address(bm)), delta);
        assertEq(fGHO.balanceOf(address(facilitator)), 0);
        
        bm.setCapacity(newCapacity-delta);
        
        (newCapacity, ) = bm.bucketOf(facilitator);
        
        vm.stopPrank();
        
        assertEq(newCapacity, capacity);
        assertEq(fGHO.balanceOf(address(bm)), 0);
    }
}
