// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {FacilitatorMultichain} from "../src/FacilitatorMultichain.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {USDC_OPT_GOERLI, FLAMINGHO_OPT_GOERLI } from "../utils/Constants.sol";


contract FacilitatorMultichainTest is Test {
    FacilitatorMultichain facilitator;
    address public facilitatorAddr = 0x36F63774335C7a39484f2cD466b2832C52e9c507; // opt goerli
    
    address deployer = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
    
    IERC20 IUSDC;
    IGhoToken fGHO;
    
    function setUp() public {
        facilitator = FacilitatorMultichain(facilitatorAddr);
        
        IUSDC = IGhoToken(USDC_OPT_GOERLI);
        fGHO = IGhoToken(FLAMINGHO_OPT_GOERLI);
        
        receiveUSDC();
    }
    
    function test_Buy_and_Sell() public {
        uint amount = 42000;
        uint fee = facilitator.facilitatorFee();
        

        IUSDC.approve(facilitatorAddr, amount+fee);

        facilitator.buy(amount);
        
        assertEq(fGHO.balanceOf(address(this)), 42000);
        
        assertEq(IUSDC.balanceOf(facilitatorAddr), amount+fee);       
        assertEq(facilitator.checkMintBucket(1), false); 
        
        _sell(amount, fee);
    }

    function _sell(uint amount, uint fee) public {
        IUSDC.approve(facilitatorAddr, fee);
        fGHO.approve(facilitatorAddr, amount);
        
        facilitator.sell(amount);
        
        assertEq(fGHO.balanceOf(address(this)), 0);
        assertEq(facilitator.checkBurnBucket(1), false);
        assertEq(IUSDC.balanceOf(facilitatorAddr), fee*2);
    }

/*
    function _deploy() internal returns (address){
        uint capacity = 42000;
        address admin = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
        bytes32 salt = keccak256(abi.encodePacked("test", admin));

        bytes memory code = _creationCode(
            facilitatorMultichainImpl, // impl
            block.chainid, 
            admin, // admin
            capacity, // capacity
            USDC_OPT_GOERLI,
            uint(salt)
        );

        address f = Create2.computeAddress(bytes32(salt), keccak256(code));
        
        if (f.code.length != 0) revert();

        f = Create2.deploy(0, salt, code);
        
        bytes memory initData = abi.encodeWithSignature("initialize(address,uint256,address)", admin, capacity, USDC_OPT_GOERLI);
        (bool success, ) = f.call(initData);
        if (!success) revert();
        
        
        return f;
    }  
    
    function _creationCode(
        address implementation_,
        uint256 chainId_,
        address admin_,
        uint256 capacity_,
        address token_,
        uint256 salt_
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(  
            hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
            implementation_,
            hex"5af43d82803e903d91602b57fd5bf3",
            abi.encode(salt_, chainId_, admin_, capacity_, token_)
        );
    }

*/
    function receiveUSDC() public {
        uint prevBalance = IUSDC.balanceOf(0x314d042d164BbEF71924f19A3913F65C0aCFb94E);
        vm.prank(0x314d042d164BbEF71924f19A3913F65C0aCFb94E);
        
        IGhoToken(USDC_OPT_GOERLI).transfer(address(this), prevBalance);
        //assertEq(IUSDC.balanceOf(address(this)), prevBalance + 10e6 * 10e6); 
    } 
/*
    function mintUSDC() public {
        uint prevBalance = IUSDC.balanceOf(address(this));
        vm.prank(0xE6b08c02Dbf3a0a4D3763136285B85A9B492E391);
        
        IGhoToken(USDC_OPT_GOERLI).mint(address(this), 10e6 * 10e6); // 10M USDC
        assertEq(IUSDC.balanceOf(address(this)), prevBalance + 10e6 * 10e6); 
    }      
*/
}

// forge test --match-path test/FacilitatorMultichain.t.sol --fork-url $OPTIMISM_GOERLI_URL  -vvvvv
