
## FlaminGHO

*let's flamingho!*

**FlaminGHO  (pronounced flamingo) is a multichain permissionless facilitator protocol that generates yield built on top of the GHO token**

**FlaminGHO was built in the LFGHO 2024 hackathon organized by EthGlobal and sponsored by AAVE, Chainlink and Family (Connectkit)**


## IMPORTANT (TEST ONLY - SKIP IN PRODUCTION)

Due to the nature of the event and the project requirements, some considerations must be taken in account:
 - The `CUSTOM_GHO` token represents the og GHO token deployed by AAVE. `CUSTOM_GHO == GHO`.
 - The `FLAMINGHO` token is a new token deployed by this protocol. `FLAMINGHO != GHO`. (tho, code is the same, just compliant with OpenZeppelin-v5)
 - Troughout the project we will see the reference 1 GHO == 1 USDC, but this is only true cause of we are conciously ignoring the decimals difference. (`10e6 == 10e18 (!)`).
 - The `FacilitatorRegistry` needs extra permissions to operate, we deployed `CUSTOM_GHO` to grant them, but the AAVE dao is in charge of grant them, in production (with og `GHO`).
 - The deployer address, also called admin, has some extra permissions too, but they are not a need in production. Just a way to easily mint some tokens for testing purposes.
 - There are some contracts that need to know each other like the `FacilitatorRegistry` and the `MultichainListener`, the latter includes an extra setter function to set the registry.
 - There are several pieces of code that need refactorization or are not 100% safe, please skip the use of this repository in production. It is a hackathon project.

## Flamingho protocol

![schema](https://github.com/jvaleskadevs/lfgho2024/blob/main/flamingho_schema.png?raw=true)

### 1 GHO == 1 Bucket Capacity

Flamingho allows anyone to create a custom facilitator while they deposit 1 GHO per 1 unit of bucket capacity assigned. (facilitators as plugins)

Flamingho protocol offers an innovative way to manage the bucket capacity ensuring every GHO minted is backed by the protocol, even multichain with the help of the Flamingho token.

### More Capacity, more locked GHO

When a facilitator increases its capacity must send the equivalent GHO (or fGHO in L2s) to the protocol.

### Less Capacity, less locked GHO

When a facilitator decreases its capacity must withdraw the equivalent GHO (or fGHO in L2s) from the protocol.

When a facilitator decreases its capacity under the bucket level the equivalent amount is captured from the facilitator.

(this is the only requirement for facilitators, to implement the `IFacilitator` interface and approve USDC to the `FacilitatorRegistry` or `BucketManager` in L2s)

### Captured USDC,... yield

Captured USDC is sent to the `Vault` (deployed from a clone of this repository: (Aave-vault)[https://github.com/aave/Aave-Vault/tree/main]),  and then sent to the AAVE protocol to generate yield. This yield could be used for funding public goods.

In L2s, captured USDC is currently locked in the protocol since there is no AAVE protocol. (space to exploration)

Locked GHO and flaminGHO tokens are currently locked in the protocol. (In the future, they could be sent to a Vault to generate yield like the one Aryan Godara is working on in this hackathon, lfgho!).

### Facilitator Stable and Facilitator Multichain

Basic examples of a facilitator implementation. 
They mint and burn GHO (L1) and flaminGHO (L2s) in exchange for USDC. `1 GHO == 1 USDC` and `1 fGHO == 1 USDC`.
Since the protocol is agnostic, endless facilitator implementations and strategies are possible. No need to be 1 == 1, more complex things could be done in the future.

The `FacilitatorStable` is deployed and managed trough the `FacilitatorRegistry` while the `FacilitatorMultichain` is deployed by the `MultichainListener` but managed by the `BucketManager`.

### BucketManager 

Capacity is controlled by the supply/demand of the flaminGHO token unlocking new market opportunities and probably new ways of exploration. (instead mint/burn on demand)
But, any other strategies could be implemented and have more than 1 `BucketManager` out there.


### Arbitrage, peg, stability and opportunies...

Flamingho protocol maximizes arbitrage opportunities when the gho price changes against the usdc. These limited opportunities, capped by the total capacity of the protocol, could be an interesting mechanism to help with the peg (minting when there is scarcity of gho (gho > usdc, will attract buyers to get 1 gho per 1 usdc, then sell it in the market for 1.01), burning in abundance (gho < usdc will attract sellers to get 1 usdc per 1 gho, after got it from the market for 0.99)), and of course, be very profitable.



## Deployments 

 - Deployer: 0xaa9d8FBaEC1704f3BFC672646A21fA67F28CCa3a

### Deployments (Sepolia)

 - `CustomGHO` token: 0xEBa15c28A6570407785D4547f191e92ea91F42e4
 - `FacilitatorRegistry`: 0x2D97F21678d075C89ec0d253908d53F5A85802Ea
 - `FacilitatorStable` (impl): 0xa7f696Cd0aD2EDc564eA249D014545278B9fa8Eb
 - `FacilitatorStable` (proxy): 0x4418E27448F6d1c87778543EC7F0A77c27202e75
 - `Vault`: 0x7Fdc932b7a717cBDc7979DBAB68061b20503243F


### Deployments (Optimism Goerli)

 - `FlaminGHO` token: 0x2B7dfEd198948d9d6A2B60BF79C6E2847fE1CDae
 - `MultichainListener`: 0x9B340aDC9AB242bf4763B798D08e8455778cB4ac
 - `FacilitatorMultichain` (impl): 0x12fc262bd99cb3f8a1cedb58bf9a760eea3427bc
 - `FacilitatorMultichain` (proxy): 0x12fc262bd99cb3f8a1cedb58bf9a760eea3427bc
 - `BucketManager`: 0x9D49d7277E06e05130B79EC78BEF737C9d011d36


## Development

```
git clone https://github.com/jvaleskadevs/lfgho2024
```

```
cd lfgho2024
forge install
npm install
```

### IMPORTANT (DON'T SKIP)

Before doing anything, after install dependencies, move these files to the right place, or everything will fail:
```
cp lib/IERC20Upgradeable.sol lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol
```

```
cp lib/IERC20MetadataUpgradeable.sol lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
```

```
cp lib/IERC4626Upgradeable.sol lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC4626Upgradeable.sol
```

```
cp lib/IERC20Upgradeable.sol lib/openzeppelin-contracts-upgradeable/contracts/interfaces/IERC20Upgradeable.sol
```

Then, copy the `.env.sample` file and fill the required environment variables in the `.env` file:
```
cp .env.sample .env
```

If you are going to run scripts you will need the PK, private key. Can skip for tests.
The same for etherscan keys if you are not going to verify contracts.
Can skip ethereum and optimism urls.

```
source .env
```

## Basic Tests (Sepolia)

Includes deployment and register of a new Facilitator Stable and a new Facilitator Multichain. It also test the Facilitator Stable.
```
forge test --match-path test/FacilitatorRegistry.t.sol --fork-url $SEPOLIA_URL -vvvv
```

## Basic Tests (Optimism Goerli)

Every test includes at the bottom the command to run it.

Flamingho token
```
forge test --match-path test/FlaminGHO.t.sol --fork-url $OPTIMISM_GOERLI_URL  -vvvvv
```

Facilitator Multichain (buy and sell)
```
forge test --match-path test/FacilitatorMultichain.t.sol --fork-url $OPTIMISM_GOERLI_URL  -vvvvv
```

Multichain Listener (CCIP message and deployment of FacilitatorMultichain)
```
forge test --match-path test/MultichainListener.t.sol --fork-url $OPTIMISM_GOERLI_URL  -vvvvv
```

Bucket Manager (changeCapacity):
```
forge test --match-path test/BucketManager.t.sol --fork-url $OPTIMISM_GOERLI_URL  -vvvv
```

## Scripts

Include the scripts used to deploy and test the protocol in testnets, Sepolia and Optimism Goerli.
Every script includes at the bottom the command to run it and a list of deployments made with the script. (being the last one, the last and current version)

No numbered scripts are deployments, must be done first. Then, just follow the order for executing ordered ones, 00_, _01, _02...

02 will fail since I do not own any USDC in the Optimism Goerli testnet and Circle deprecated the faucet, asked for a donation in the discord but.. if you own some usdc, even cents, will work, just use your address ;)

They show how to deploy the flaminGHO protocol, register some facilitators (stable and multichain) and perform some operations with them to mint/burn GHO and fGHO. It also includes an script
showing how to capture the USDC when decreasing the capacity under the bucket level.

It is importantto check the script to find the right command, they are not all executed in the same chain (!)

### Flamingho facilitator sample dapp

A very basic sample of a facilitator dapp where any user can buy (mint) and sell (burn) GHO (sepolia) and flaminGHO (optimism goerli) tokens (1 GHO == 1 USDC)(1 fGHO == 1 USDC).
```
cd app/flamingho-dapp
yarn
cp .env.sample .env
(fill your .env file)
yarn dev
```

or you can visit the live demo: https://flamingho.vercel.app

## Flamingho flow - Examples 

### Alice example (Sepolia)

 - Alice locks 42069 gho. And, register a 
facilitator stable on the registry.

 - Alice facilitator mint and burn gho on 
demand while the level is greater than zero and lower than capacity.
It is stable, 1 gho is equal to 1 usdc, takes an small fee.

 - Alice decreased capacity to 69 and got
42000 gho. but level was 2069, so
2000 usdc were captured from the
facilitator and sent to the vault and then, to aave.

### Bob example (Sepolia-OptimismGoerli)

 - Bob supplied enough usdc to aave
to mint 42069 gho (overcollateralized) in Sepolia.
Bob locks 42069 gho and registers a 
facilitator multichain on the registry.

 - Bob facilitator in Optimism Goerli mint & burn fgho on 
demand while the level is greater than zero and lower than capacity.
It is stable, 1 flamingho is equal to 1 usdc, takes an small fee.

 - Bob decreased capacity to 69 and got
42000 fgho, but level was 2069, so
2000 usdc were captured from the
facilitator and locked in the protocol.
