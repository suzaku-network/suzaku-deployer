# Troubleshooting Guide

This document contains common issues and their solutions that you might encounter when using the Suzaku Deployer.

## Environment Setup Issues

### Missing Forge-Std Library

**Error:**
```
Source "forge-std/Script.sol" not found: File not found. Searched the following locations: ""
```

**Solution:**
Install the forge-std library using the following command:
```bash
forge install foundry-rs/forge-std --no-commit
```

### Missing Suzaku Core

**Error:**
```
Source "@suzaku/core/script/deploy/FactoryRegistryOptins.s.sol" not found: File not found
```

**Solution:**
1. Make sure you have the suzaku-core repository cloned or available.
2. Update your `foundry.toml` to include the proper remapping:
```toml
remappings = [
  "@suzaku/core=path/to/suzaku/core",
]
```

3. Alternatively, you can use a git submodule:
```bash
git submodule add https://github.com/your-org/suzaku-core.git
```

Then update your `foundry.toml` remapping to:
```toml
remappings = [
  "@suzaku/core=suzaku-core",
]
```

## Deployment Issues

### Failed Transactions

**Error:**
```
Transaction reverted without a reason
```

**Solution:**
1. Check that your account has enough funds for the deployment
2. Verify that the correct configuration values are set in your config file
3. Make sure any previous deployment steps have been completed successfully

### Missing Previous Deployment Artifacts

**Error:**
```
Failed to read file: deployments/factories-fuji-latest.json
```

**Solution:**
Make sure you've completed all previous deployment steps in order. Each script expects the artifacts from the previous step to be available.

### Gas Estimation Failed

**Error:**
```
Gas estimation failed: 'execution reverted'
```

**Solution:**
1. Increase the gas limit in your forge command:
```bash
forge script ... --gas-limit 10000000
```

2. Check for any configuration errors in your JSON file

## Configuration Issues

### Invalid JSON Format

**Error:**
```
Failed to parse JSON
```

**Solution:**
Validate your JSON file with a JSON validator to ensure it's properly formatted.

### Missing Configuration Keys

**Error:**
```
Failed to decode JSON field: .middlewareConfig.primaryAsset
```

**Solution:**
Make sure your config file includes all required fields. Check the example configuration files for reference.

## Network Connectivity Issues

### RPC Connection Failed

**Error:**
```
Could not connect to RPC endpoint
```

**Solution:**
1. Verify your RPC URL is correct in your .env file
2. Check your internet connection
3. Try an alternative RPC provider

### Contract Verification Failed

**Error:**
```
Contract verification failed: API key invalid
```

**Solution:**
1. Ensure you have set the correct API key in your .env file
2. Check that contract verification is supported on the network you're deploying to
3. For Fuji/Avalanche, make sure you have a valid Snowtrace API key

## Common Testing Issues

### Anvil Node Not Running

**Error:**
```
Failed to connect to local RPC
```

**Solution:**
Start an Anvil node in a separate terminal:
```bash
anvil
```

### Test Deployment Fails

**Error:**
```
Test failed: Deployment reverted
```

**Solution:**
1. Use `--verbose` flag to see detailed output:
```bash
forge test --verbose
```

2. Make sure your test is properly set up with the right testing account and environment

## Foundry Issues

### Incompatible Foundry Version

**Error:**
```
Incompatible Solidity compiler version
```

**Solution:**
Update your Foundry installation:
```bash
foundryup
```

### Out of Date Dependencies

**Error:**
```
Incompatible library version
```

**Solution:**
Update your dependencies:
```bash
forge update
```

## Additional Help

If you encounter issues not covered in this guide:

1. Check the [Foundry Book](https://book.getfoundry.sh/) for general Foundry troubleshooting
2. Review the Suzaku Core documentation for specific protocol details
3. Open an issue in the repository with detailed information about your problem 
