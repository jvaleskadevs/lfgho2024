// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorRegistry} from "../src/FacilitatorRegistry.sol";
import {CUSTOM_GHO, USDC_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";


contract RegisterFacilitatorStableScript is Script {
    FacilitatorRegistry registry;
    IGhoToken gho;
    
    address deployer = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
    address facilitatorRegistry = 0x2D97F21678d075C89ec0d253908d53F5A85802Ea;
    address facilitatorStableImpl = 0xa7f696Cd0aD2EDc564eA249D014545278B9fa8Eb;

    function setUp() public {
        registry = FacilitatorRegistry(payable(facilitatorRegistry));
        gho = IGhoToken(CUSTOM_GHO);
    }

    function run() public {
        uint capacity = 42000;
        uint fee = registry.facilitatorFee();
    
        vm.startBroadcast(vm.envUint("PK"));

        gho.approve(address(registry), capacity+fee);
        
        registry.registerFacilitator(
            facilitatorStableImpl,
            uint128(capacity),
            "_lfgho_2024_", // label
            deployer, // admin
            0, // destination chain, skipping
            abi.encodeWithSignature(
                "initialize(address,address,address)", 
                deployer, 
                CUSTOM_GHO, 
                USDC_SEPOLIA
            )
        );
        
        vm.stopBroadcast();
    }
}

// forge script script/03_Register_Facilitator_Stable.s.sol:RegisterFacilitatorStableScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv
//
// FacilitatorStable deployed to: 0x530dBCd6f6e9097fB0169dAa1af4E6574385F1F6, on the Sepolia chain
// FacilitatorStable deployed to: 0x5b7A9a35E7c7f57a6cB5F96c75Ad5d1c382381FB, on the Sepolia chain
// FacilitatorStable deployed to: 0x4F0759377CadBa6021003bBE9D1f7272499b9558, on the Sepolia chain
// FacilitatorStable deployed to: 0x4153D0868e813AFD23820C0ac37143317dc58834, on the Sepolia chain
// FacilitatorStable deployed to: 0xa20b70ceA94e3d1978228d20212a18a3Ee540DAb, on the Sepolia chain
// FacilitatorStable deployed to: 0x4418E27448F6d1c87778543EC7F0A77c27202e75, on the Sepolia chain


