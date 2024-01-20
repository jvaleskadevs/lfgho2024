// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script, console2} from "forge-std/Script.sol";
import {FacilitatorRegistry} from "../src/FacilitatorRegistry.sol";
import {CUSTOM_GHO, USDC_SEPOLIA, USDC_OPT_GOERLI, CCIP_ROUTER_SEPOLIA} from "../utils/Constants.sol";
import {IGhoToken} from "../src/interfaces/IGhoToken.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";


contract RegisterFacilitatorMultichainScript is Script {
    FacilitatorRegistry registry;
    IGhoToken gho;
    
    address deployer = 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a;
    // sepolia
    address facilitatorRegistry = 0x2D97F21678d075C89ec0d253908d53F5A85802Ea;
    // opt-goerli
    address multichainListener = 0x9B340aDC9AB242bf4763B798D08e8455778cB4ac;
    // opt-goerli
    address facilitatorMultichainImpl = 0x6721c3439D98B99EB7580c7F27A977AE9f49dc38;
    
    uint64 OPT_GOERLI_DESTINATION_CHAIN = 2664363617261496610;

    function setUp() public {
        registry = FacilitatorRegistry(payable(facilitatorRegistry));
        gho = IGhoToken(CUSTOM_GHO);
    }

    function run() public {
        uint capacity = 42069;
        uint fee = registry.facilitatorFee();
        
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,uint256,address)", 
            deployer, 
            capacity, 
            USDC_OPT_GOERLI
        );

        uint ccipFee = _simulateCCIPFees(facilitatorMultichainImpl, capacity, initData);
    
        vm.startBroadcast(vm.envUint("PK"));

        //registry.setMultichainListener(multichainListener, 2664363617261496610);

        gho.approve(address(registry), capacity+fee);
        
        registry.registerFacilitator{value: ccipFee}(
            facilitatorMultichainImpl,
            uint128(capacity),
             "letsFlaminGHO!", // label
            deployer, //admin
            OPT_GOERLI_DESTINATION_CHAIN, // ccip
            initData
        );
        
        vm.stopBroadcast();
    }
    
    function _simulateCCIPFees(address impl, uint capacity, bytes memory initData) internal returns (uint) {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(multichainListener),
            data: abi.encode(impl, capacity, initData),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 3000000})),
            feeToken: address(0)//LINK
        });
        
        IRouterClient router = IRouterClient(CCIP_ROUTER_SEPOLIA);
        return router.getFee(OPT_GOERLI_DESTINATION_CHAIN, message);
    }
}

// forge script script/01_Register_FacilitatorMultichain.s.sol:RegisterFacilitatorMultichainScript --rpc-url $SEPOLIA_URL --broadcast --verify -vvvv
//
// FacilitatorMultichain deployed to: 0x2651E8a897B340D64D8357756342B53ecfCc94ca, to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: 0xFd69dDc2933e2BA0686fE5A4Ac6821D92f2AeCBc, to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: 0xaC514223BA87823346fC41340f3E639d7795E755, to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: , to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: , to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: 0xBB149C05739F5017A46F49FFB24F2961c7dc3109, to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: 0x36f63774335c7a39484f2cd466b2832c52e9c507, to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: 0x7a7cceff68b87ebe0fc981e58165791730485f76, to the Optimism Goerli chain from the Sepolia chain
// FacilitatorMultichain deployed to: 0x12fc262bd99cb3f8a1cedb58bf9a760eea3427bc, to the Optimism Goerli chain from the Sepolia chain


