// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import {FacilitatorRegistry} from "../src/FacilitatorRegistry.sol";
import {FacilitatorStable} from "../src/FacilitatorStable.sol";
import {FacilitatorMultichain} from "../src/FacilitatorMultichain.sol"; 
import {MultichainListener}  from "../src/MultichainListener.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {GHO, USDC, CCIP_ROUTER_SEPOLIA, GHO_ADMIN, USDC_OWNER} from "../utils/Constants.sol";
import {Profitator} from "../src/Profitator.sol";

// OUTDATED TESTS
/*
contract FacilitatorRegistryTest is Test {
    FacilitatorRegistry registry;
    Profitator profitator; // used for swap tokens
    address multichainListener;
    
    IGhoToken IGHO;
    IERC20 IUSDC;
    
    
    function setUp() public {
        //receiveETH();
        IGHO = IGhoToken(GHO);
        IUSDC = IERC20(USDC);
        // we need USDC to get GHO
        mintUSDC();
        //receiveUSDC();
        
        // we need GHO to register the facilitator
        receiveGHO();
        
        
        createFacilitatorRegistry(); 
    }
    
    function createFacilitatorRegistry() public {
        uint fee = 420; // every new registered facilitator will pay it
        registry = new FacilitatorRegistry(GHO, USDC, CCIP_ROUTER_SEPOLIA, fee);
        
        // the Registry needs some permissions to operate
        addFacilitatorRoleImpersonate(GHO_ADMIN, address(registry));
        
        //multichainListener = 0x7E7DA3a8D45349110EeD866047307bD34BE85996;
        multichainListener = 0x6BA96594e94d5B12F1ef689d5D69E006d056B1Ad;
        registry.setMultichainListener(multichainListener, 2664363617261496610);
    }
    
    
    function test_RegisterFacilitator() public {
        uint128 capacity = 42000;
        
        IGHO.approve(address(registry), capacity+registry.facilitatorFee());
        
        address facilitator = registry.registerFacilitator(
            "lfgho2024_fs", capacity, address(this), 0, address(0)
        );
        
        (uint cap, uint lvl) = registry.bucketOf(facilitator);
        assertEq(cap, capacity);
        
        FacilitatorStable fs = FacilitatorStable(facilitator);
        
        // buy GHO
        IUSDC.approve(address(facilitator), 420);
        fs.buy(420); // get GHO, pay USDC, 1:1
        
        assertEq(IUSDC.balanceOf(facilitator), 420);
        
        // sell GHO
        IGHO.approve(address(facilitator), 420);
        fs.sell(420); // get USDC, pay GHO, 1:1
        
        assertEq(IUSDC.balanceOf(facilitator), 0);
        
        // change capacity
        uint newCapacity = 42000 * 7;
        IGHO.transfer(facilitator, 42000 * 6);
        fs.setCapacity(newCapacity);
        
        (cap, lvl) = registry.bucketOf(facilitator);
        assertEq(cap, newCapacity);
        
        // remove facilitator
        fs.setCapacity(0);
        
        (cap, lvl) = registry.bucketOf(facilitator);
        assertEq(cap, 0);
        
        // register again
        IGHO.approve(address(registry), capacity+registry.facilitatorFee());
        address newFacilitator = registry.registerFacilitator(
            "lfgho2024_fs", capacity, address(this), 0, address(facilitator)
        );
        
        (cap, lvl) = registry.bucketOf(newFacilitator);
        assertEq(cap, capacity);
        assertEq(newFacilitator, facilitator);
    }
    
    
    function test_RegisterFacilitatorMultichain() public {
        uint128 capacity = 42000;
        
        IGHO.approve(address(registry), capacity+registry.facilitatorFee());
        
        uint ccip_fees = _simulateCCIPFees();
        
        address facilitator = registry.registerFacilitator{value: ccip_fees}(
            "lfgho2024", capacity, address(this), 2664363617261496610, //opt goerli
            address(0)
        );
      
        (uint cap, uint lvl) = registry.bucketOf(facilitator);
        assertEq(cap, capacity);
        
        bytes32 salt = keccak256(
          abi.encodePacked("lfgho2024", address(this))
        );
        
        address computedFacilitator = Create2.computeAddress(
            salt, 
            keccak256(abi.encodePacked(type(FacilitatorMultichain).creationCode)),
            multichainListener
        );
        
        assertEq(facilitator, computedFacilitator);
    }
    
    
    function _simulateCCIPFees() internal returns (uint) {    
        uint capacity = 42000;
        address admin = address(this);
        bytes32 salt = keccak256(abi.encodePacked("lfgho2024", address(this)));
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(multichainListener),
            data: abi.encode(admin, capacity, salt),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 3000000})),
            feeToken: address(0)//LINK
        });
        
        IRouterClient router = IRouterClient(CCIP_ROUTER_SEPOLIA);
        return router.getFee(2664363617261496610, message);
    }   
    
    
    receive() external payable {}
    
    
   
    
    
    
   // IMPERSONATE
   
   function addFacilitatorImpersonate(address target, address facilitator) public {
        vm.prank(target);

        IGHO.addFacilitator(facilitator, "profitator", 42420 * 10e6);
    }   
    
    function addFacilitatorRoleImpersonate(address target, address recipient) public {
        vm.prank(target);
        // Facilitator Role
        IGHO.grantRole(
            0x5e20732f79076148980e17b6ce9f22756f85058fe2765420ed48a504bef5a8bc,
            recipient
        );
        vm.prank(target);
        /// Bucket Role
        IGHO.grantRole(
            0xc7f115822aabac0cd6b9d21b08c0c63819451a58157aecad689d1b5674fad408,
            recipient
        );
    }
    // just migrating to foundry, found initial-balance now haha
    function receiveETH() public {
        //uint prevBalance = address(this).balance;
        address target = 0x95222290DD7278Aa3Ddd389Cc1E1d165CC4BAfe5;
        vm.prank(target);
        
        (bool success, bytes memory data) = 
            payable(address(this)).call{
                value: address(target).balance
            }("");
        require(success, "receiveETH");
        console2.log(address(this).balance);
        //assertEq(address(this).balance, prevBalance + amount);
    }
    
    function receiveUSDC() public {
        //uint prevBalance = IERC20(USDC).balanceOf(address(this));
        address target = 0x7eb6c83AB7D8D9B8618c0Ed973cbEF71d1921EF2;
        vm.prank(target);
        
        IUSDC.transfer(address(this), 42420);
        //assertEq(IERC20(USDC).balanceOf(address(this)), prevBalance + amount); 
    }
    
    function mintUSDC() public {
        //uint prevBalance = IERC20(USDC).balanceOf(address(this));
        vm.prank(USDC_OWNER);
        
        IGhoToken(USDC).mint(address(this), 10e6 * 10e6); // 10M USDC
        //assertEq(IERC20(USDC).balanceOf(address(this)), prevBalance + 10e6 * 10e6); 
    }  
    
    function receiveGHO() public {
        profitator = new Profitator(GHO, USDC);
        addFacilitatorImpersonate(GHO_ADMIN, address(profitator));
        
        IUSDC.approve(address(profitator), 42420 * 10e6);
        profitator.buy(42420 * 10e6); // get GHO, pay USDC, 1:1
        assertEq(IGHO.balanceOf(address(this)), 42420 * 10e6);       
    }
    
    // utils
    function printCreationCode() public {
        console2.log(uint(keccak256(abi.encodePacked(type(FacilitatorMultichain).creationCode))));
        // 41649023707695669685951008336737405697760759915946860671833789022829076591445 
        // cast to-hex -> 0x5c148315112e20a140c861f62da9d0d47c41ca1ff60aab7bdf46c88e448cb355    
    }

}
*/
