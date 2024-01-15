// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorRegistry} from "../src/FacilitatorRegistry.sol";
import {CUSTOM_GHO, USDC_SEPOLIA, CCIP_ROUTER_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";


contract RegisterFacilitatorMultichainScript is Script {
    FacilitatorRegistry registry;
    IGhoToken gho;
    
    address deployer = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
    address facilitatorRegistry = 0x9B340aDC9AB242bf4763B798D08e8455778cB4ac;
    address multichainListener = 0x7E7DA3a8D45349110EeD866047307bD34BE85996;

    function setUp() public {
        registry = FacilitatorRegistry(payable(facilitatorRegistry));
        gho = IGhoToken(CUSTOM_GHO);
    }

    function run() public {
        uint capacity = 42000;
        uint fee = registry.facilitatorFee();
        uint ccipFee = _simulateCCIPFees();
    
        vm.startBroadcast(vm.envUint("PK"));

        registry.setMultichainListener(multichainListener);

        gho.approve(address(registry), capacity+fee);
        
        registry.registerFacilitator{value: ccipFee}(
            "lfgho_2024", // label
            uint128(capacity),
            deployer, //admin
            2664363617261496610, // opt goerli destination chain, ccip
            address(0)
        );
        
        vm.stopBroadcast();
    }
    
    function _simulateCCIPFees() internal returns (uint) {    
        uint capacity = 42000;
        address admin = deployer;
        bytes32 salt = keccak256(abi.encodePacked("lfgho_2024", deployer));
        
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
}

// forge script script/01_Register_FacilitatorMultichain.s.sol:RegisterFacilitatorMultichainScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv
// FacilitatorMultichain deployed to: 0x2651E8a897B340D64D8357756342B53ecfCc94ca, to the Optimism Goerli chain from the Sepolia chain

