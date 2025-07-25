# Configuration File Structure Guide

This document explains the required structure for deployment configuration files used by the Suzaku deployment scripts.

## Key Requirements

### 1. Vault Deployment (DeployVaultFull)

Required fields in the `deployed` section:
- `vaultFactory`: Address of the deployed VaultFactory
- `delegatorFactory`: Address of the deployed DelegatorFactory  
- `slasherFactory`: Address of the deployed SlasherFactory
- `l1Registry`: Address of the deployed L1Registry
- `operatorRegistry`: Address of the deployed OperatorRegistry
- `operatorVaultOptInService`: Address of the deployed OperatorVaultOptInService
- `operatorL1OptInService`: Address of the deployed OperatorL1OptInService

### 2. Middleware Deployment (DeployMiddlewareL1)

Required fields in the `deployed` section:
- `validatorManager`: Address of the deployed ValidatorManager
- `operatorRegistry`: Address of the deployed OperatorRegistry
- `vaultFactory`: Address of the deployed VaultFactory
- `operatorL1OptIn`: Address of the deployed OperatorL1OptInService (note: different key name!)
- `primaryAsset`: Address of the primary asset (collateral token)

### 3. Rewards Deployment (DeployRewardsL1)

Required fields in the `deployed` section:
- `middleware`: Address of the deployed L1 Middleware (must deploy middleware first!)
- `l1ID`: The L1 chain ID as bytes32 (e.g., "0x66226f76a8fb608290afeadc795bf8fe1e54779285228833d489ebf21ca06a07")

### 4. Balancer Deployment (UpgradePoAToBalancer)

Required fields in the `deployed` section:
- `proxyAddress`: Address of the deployed ValidatorManager proxy

## Deployment Order

Due to dependencies, deployments should be done in this order:

1. **Protocol Infrastructure** (if not already deployed)
   - Deploy factories and registries using DeployFactoriesRegistriesOptIns

2. **Validator Manager** (if using PoA)
   - Deploy using DeployPoAValidatorManager

3. **Vault**
   - Deploy using DeployVaultFull
   - Requires all factory addresses

4. **Middleware**
   - Deploy using DeployMiddlewareL1
   - Requires validator manager and factory addresses

5. **Rewards** 
   - Deploy using DeployRewardsL1
   - Requires deployed middleware address

6. **Balancer Upgrade** (if upgrading from PoA)
   - Deploy using UpgradePoAToBalancer
   - Requires validator manager proxy address

## Example Workflow

1. Deploy protocol infrastructure (one-time)
2. Update config with deployed factory addresses
3. Deploy vault
4. Update config with deployed vault address (if needed by other components)
5. Deploy middleware
6. Update config with deployed middleware address
7. Deploy rewards

## Notes

- The `anvilTest.json` includes all sections and deployed addresses for testing
- Production deployments will need to update addresses after each deployment step
- Always verify addresses before deploying dependent components 
