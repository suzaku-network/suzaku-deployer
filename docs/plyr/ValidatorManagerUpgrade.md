# Player Validator Manager Contract Upgrade

Since the [deployed version](https://snowscan.xyz/address/0xa61be1c29caceebcc677a6c4ddedb39e78d5ee99#code) was [v2.0.0](https://github.com/ava-labs/icm-contracts/blob/validator-manager-v2.0.0/contracts/validator-manager/ValidatorManager.sol), we need to upgrade to [v2.1.0](https://github.com/ava-labs/icm-contracts/blame/validator-manager-v2.1.0/contracts/validator-manager/ValidatorManager.sol) for its integration with Suzaku.

To do so, we added to the [`configs/plyr/ValidatorManagerUpgrade.json`](../../configs/plyr/ValidatorManagerUpgrade.json) configuration file the address of the [player validator manager proxy](https://snowscan.xyz/address/0x9b40cce8650cd839f926a1da78894805f19acf8e) (the script will just read `validatorManagerProxy` and write `poaManagerAddress`) :

### Underlying steps:

- Deploy the new `ValidatorManager` implementation
- Upgrade the implementation used by the proxy
- Deploy the `PoAManager`

### Execution:

The commands to test on anvil:
```bash
anvil --fork-url https://api.avax.network/ext/bc/C/rpc --host 0.0.0.0
# on another terminal:
forge script script/l1/UpgradeValidatorManagerToV2_1_0.s.sol:UpgradeValidatorManagerToV2_1_0 --sig "run(uint256,uint256,string)" $OWNER_PK $OWNER_PK "plyr/ValidatorManagerUpgrade.json" --broadcast --rpc-url http://127.0.0.1:8545 --private-key $OWNER_PK
# Check
cast call 0x9b40cce8650cd839f926a1da78894805f19acf8e 'owner()(address)' --rpc-url http://127.0.0.1:8545 # Should be the PoAManagerAddress
cast call <PoAManagerAddress> 'owner()(address)' --rpc-url http://127.0.0.1:8545 # Should be the OWNER_PK address
```
The command for the real upgrade:
```bash
export ETHERSCAN_API_KEY=
forge script script/l1/UpgradeValidatorManagerToV2_1_0.s.sol:UpgradeValidatorManagerToV2_1_0 --sig "run(uint256,uint256,string)" $OWNER_PK $OWNER_PK "plyr/ValidatorManagerUpgrade.json" --broadcast --rpc-url avalanche --private-key $OWNER_PK --verify --verifier custom
```

### Next step:

- Transfer the `PoAManager` ownership to the multisig
