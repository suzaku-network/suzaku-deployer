# Suzaku Deployer

A deployment framework for Suzaku Protocol smart contracts. This repository provides wrapper scripts and configuration examples to simplify the deployment process across different networks.

## Overview

This deployer framework serves as a thin wrapper around the core deployment scripts found in the `suzaku-core` repository. It provides:

1. Configuration-driven deployments through JSON files
2. Deployment scripts for all Suzaku components
3. Automatic saving of deployment artifacts
4. Multi-network support (Anvil, Fuji, Avalanche)

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Suzaku Core as a dependency (added via remapping in `foundry.toml`)

## Installation

1. Clone the repository:
```sh
git clone https://github.com/your-org/suzaku-deployer.git
cd suzaku-deployer
```

2. Install the dependencies:
```sh
forge install
```

3. Set up your environment variables in a `.env` file:
```
PRIVATE_KEY=your_private_key
AVALANCHE_RPC_URL=your_avalanche_rpc_url
FUJI_RPC_URL=your_fuji_rpc_url
SNOWTRACE_API_KEY=your_snowtrace_api_key
```

## Deployment Architecture

The deployment process is divided into several steps that should be executed in sequence:

2. **Vault Deployment**: Deploy vaults using externally provided factories and registries
3. **Middleware L1 Deployment**: Deploy the L1 middleware components
4. **Validator Deployment**: Deploy validators connected to the middleware
5. **Upgrade Deployment**: Upgrade PoA validators to Balancer validators (optional)

Each step saves its deployment artifacts that are used by subsequent steps.

## Configuration Files

Configuration files are stored in the `configs/` directory. Examples are provided for:

- Anvil (Local Development): `anvil-example.json`
- Avalanche (Mainnet): `avalanche-example.json`
- Vault Configuration: `vaultExample.json`
- Middleware Configuration: `middlewareExample.json`
- Balancer Upgrade Configuration: `balancerExample.json`

These files should be customized for your specific deployment needs.

## Environment Setup

This framework expects the addresses of factories and registries to be provided in your `.env` file:

```
PRIVATE_KEY=your_private_key
AVALANCHE_RPC_URL=your_avalanche_rpc_url
FUJI_RPC_URL=your_fuji_rpc_url
SNOWTRACE_API_KEY=your_snowtrace_api_key

# Factory and Registry addresses 
VAULT_FACTORY_ADDRESS=0x...
DELEGATOR_FACTORY_ADDRESS=0x...
SLASHER_FACTORY_ADDRESS=0x...
REGISTRY_ADDRESS=0x...

# Additional private keys for validator deployment
PROXY_ADMIN_OWNER_KEY=your_proxy_admin_owner_private_key
VALIDATOR_MANAGER_OWNER_KEY=your_validator_manager_owner_private_key
# Add other required factory/registry addresses
```

## Deployment Scripts

The deployment scripts are stored in the `script/` directory:

- `script/curator/DeployCurator.s.sol`: Deploys a vault with its delegator and slasher components
- `script/l1/DeployMiddleware.s.sol`: Deploys L1 middleware components
- `script/l1/DeployPoAValidatorManager.s.sol`: Deploys PoA validator manager contracts
- `script/l1/UpgradePoAToBalancer.s.sol`: Upgrades PoA validators to Balancer validators

## Deployment Process

### 1. Deploy Vault

```sh
forge script \
  script/curator/DeployCurator.s.sol:DeployVaultFull \
  --sig "run(string)" "vaultExample.json" \
  --broadcast \
  --rpc-url fuji \
  --private-key "$PRIVATE_KEY" \
  --via-ir \
  --verify

```

### 2. Deploy L1 Middleware

```sh
forge script script/l1/DeployMiddleware.s.sol:DeployMiddlewareL1 \
  --sig "run(string)" "middlewareExample.json" \
  --broadcast \
  --rpc-url fuji \
  --private-key "$PRIVATE_KEY" \
  --verify
```

### 3. Deploy Validator

```sh
forge script script/l1/DeployPoAValidatorManager.s.sol:DeployPoAValidatorManager \
  --sig "run(string,uint256,uint256)" "balancerExample.json" $PROXY_ADMIN_OWNER_KEY $VALIDATOR_MANAGER_OWNER_KEY \
  --broadcast \
  --rpc-url fuji \
  --private-key "$PRIVATE_KEY" \
  --verify
```

### 4. Upgrade PoA to Balancer (Optional)

To upgrade an existing PoA validator to a Balancer validator:

```sh
forge script script/l1/UpgradePoAToBalancer.s.sol:DeployUpgradePoAToBalancer \
  --sig "run(string,uint256)" "balancerExample.json" $PROXY_ADMIN_OWNER_KEY \
  --broadcast \
  --rpc-url fuji \
  --private-key "$PRIVATE_KEY" \
  --verify
```

## Deployment Artifacts

Deployment artifacts are saved in the `deployments/` directory with the following naming convention:

- Vaults: `vault-{network}-{timestamp}.json` and `vault-{network}-latest.json`
- Middleware: `middleware-{network}-{timestamp}.json` and `middleware-{network}-latest.json`
- Upgrades: `poAUpgrade.json` in `deployments/{chainId}/{date}/` directory structure
