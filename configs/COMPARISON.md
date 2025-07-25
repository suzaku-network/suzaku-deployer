# JSON Structure Comparison

## First JSON (Full Deployment Config)

This appears to be a complete deployment configuration with:
- `factoriesFile: "anvilFactories.json"` - References external factory addresses
- Full configuration sections (vault, middleware, rewards, etc.)
- `deployed` section with deployed contract instances

## Second JSON (Factory Deployment Output)

This appears to be the output from deploying factories and registries:
- All factory addresses (vaultFactory, delegatorFactory, etc.)
- Service addresses (operatorVaultOptInService, operatorL1OptInService)
- Infrastructure components

## Key Differences

### 1. Variable Name Mismatches

| What Scripts Expect | First JSON Has | Second JSON Has |
|-------------------|----------------|-----------------|
| `deployed.vaultFactory` | ❌ Missing | ✅ `vaultFactory` |
| `deployed.delegatorFactory` | ❌ Missing | ✅ `delegatorFactory` |
| `deployed.slasherFactory` | ❌ Missing | ✅ `slasherFactory` |
| `deployed.l1Registry` | ❌ Missing | ✅ `l1Registry` |
| `deployed.operatorRegistry` | ❌ Missing | ✅ `operatorRegistry` |
| `deployed.operatorVaultOptInService` | ❌ Missing | ✅ `operatorVaultOptInService` |
| `deployed.operatorL1OptInService` | ❌ Missing | ✅ `operatorL1OptInService` |
| `deployed.operatorL1OptIn` | ❌ Missing | ✅ `operatorL1OptInService` (same address) |
| `deployed.primaryAsset` | ✅ `collateral` | ❌ Missing |
| `deployed.middleware` | ✅ `middleware` | ❌ Missing |
| `deployed.l1ID` | ❌ Missing | ❌ Missing |
| `deployed.validatorManager` | ✅ Has it | ❌ Missing |

### 2. Additional Variables

First JSON `deployed` section has:
- `collateral` - The collateral token address
- `vault` - Deployed vault instance
- `delegator` - Deployed delegator instance  
- `middleware` - Deployed middleware instance
- `vaultManager` - Deployed vault manager
- `rewards` - Deployed rewards contract
- `uptimeTracker` - Deployed uptime tracker

Second JSON has:
- `defaultCollateralFactory` - Not used by current scripts
- `owner` - The protocol owner address

### 3. Missing Connection

The first JSON references `anvilFactories.json` but doesn't include the factory addresses in its `deployed` section. The deployment scripts expect ALL addresses to be in the `deployed` section.

## Solution

These two JSONs should be merged. The `deployed` section should include:

```json
"deployed": {
  // From second JSON (factories)
  "vaultFactory": "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  "delegatorFactory": "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
  "slasherFactory": "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
  "l1Registry": "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707",
  "operatorRegistry": "0x0165878A594ca255338adfa4d48449f69242Eb8F",
  "operatorVaultOptInService": "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853",
  "operatorL1OptInService": "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6",
  "operatorL1OptIn": "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6", // Same as above
  
  // From first JSON (deployed instances)
  "collateral": "0x9f1ac54BEF0DD2f6f3462EA0fa94fC62300d3a8e",
  "primaryAsset": "0x9f1ac54BEF0DD2f6f3462EA0fa94fC62300d3a8e", // Same as collateral
  "vault": "0x36658a07F03E3e9c1299a27d83653c38158e8C2b",
  "delegator": "0x6c38670602dF1fc4e438D4162188e3007344582C",
  "middleware": "0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE", // Same as middleware
  "middleware": "0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE",
  "vaultManager": "0x68B1D87F95878fE05B998F19b66F4baba5De1aed",
  "rewards": "0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1",
  "uptimeTracker": "0x59b670e9fA9D0A427751Af201D676719a970857b",
  "validatorManager": "0x8464135c8F25Da09e49BC8782676a84730C318bC",
  "l1ID": "0x..." // Need to add this
}
```

## Key Issues

1. **Separate Files**: Having factory addresses in a separate file makes deployment scripts fail because they expect everything in the `deployed` section.

2. **Name Mismatches**: 
   - `collateral` vs `primaryAsset` (scripts expect `primaryAsset`)
   - `middleware` vs `middleware` (scripts expect `middleware` for rewards)
   - `operatorL1OptInService` vs `operatorL1OptIn` (middleware script expects `operatorL1OptIn`)

3. **Missing Fields**:
   - `l1ID` is required for rewards deployment
   - Factory addresses are not in the main config's `deployed` section 
