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

1. **Vault Deployment**: Deploy vaults using externally provided factories and registries
2. **Middleware L1 Deployment**: Deploy the L1 middleware components
3. **Middleware L2 Deployment**: Deploy the L2 middleware components
4. **Validator Deployment**: Deploy validators connected to the middleware

Each step saves its deployment artifacts that are used by subsequent steps.

## Configuration Files

Configuration files are stored in the `configs/` directory. Examples are provided for:

- Anvil (Local Development): `anvil-example.json`
- Fuji (Testnet): `fuji-example.json`
- Avalanche (Mainnet): `avalanche-example.json`
- L2 Configuration: `l2-example.json`
- Validator Configuration: `validator-example.json`

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
# Add other required factory/registry addresses
```

## Deployment Scripts

The deployment scripts are stored in the `script/` directory:

- `DeployVaultFullX.s.sol`: Deploys a vault with its delegator and slasher components
- `DeployMiddlewareX.s.sol`: Deploys L1 middleware components
- `DeployAvaxL2X.s.sol`: Deploys L2 middleware components for Avalanche
- `DeployValidatorX.s.sol`: Deploys validator contracts

## Deployment Process

### 1. Deploy Vault

```sh
forge script script/DeployVaultFullX.s.sol:DeployVaultFullX \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --sig "run(string,string)" \
  "fuji-example.json" "fuji"
```

### 2. Deploy L1 Middleware

```sh
forge script script/DeployMiddlewareX.s.sol:DeployMiddlewareX \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --sig "run(string,string)" \
  "fuji-example.json" "fuji"
```

### 3. Deploy L2 Middleware

```sh
forge script script/DeployAvaxL2X.s.sol:DeployAvaxL2X \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --sig "run(string,string)" \
  "l2-example.json" "fuji"
```

### 4. Deploy Validator

```sh
forge script script/DeployValidatorX.s.sol:DeployValidatorX \
  --rpc-url $FUJI_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --sig "run(string,string,string)" \
  "validator-example.json" "fuji" "fuji"
```

## Deployment Artifacts

Deployment artifacts are saved in the `deployments/` directory with the following naming convention:

- Vaults: `vault-{network}-{timestamp}.json` and `vault-{network}-latest.json`
- Middleware: `middleware-{network}-{timestamp}.json` and `middleware-{network}-latest.json`

## Troubleshooting

### Missing forge-std

If you encounter errors about missing `forge-std` or `Script.sol`, make sure you've installed the dependencies:

```sh
forge install foundry-rs/forge-std --no-commit
```

### Missing suzaku-core

If you encounter errors about missing `@suzaku/core`, make sure your `foundry.toml` has the correct remapping:

```toml
remappings = [
  "@suzaku/core=path/to/suzaku/core",
]
```

## License

MIT 
