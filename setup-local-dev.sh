#!/bin/bash

# Script to setup a local development environment for Suzaku Deployer
# This script will:
# 1. Install dependencies
# 2. Start Anvil
# 3. Deploy contracts to local Anvil network

# Exit on any error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Suzaku Deployer Local Setup ===${NC}"

# Check if Foundry is installed
if ! command -v forge &> /dev/null; then
    echo -e "${RED}Foundry not found. Please install Foundry first:${NC}"
    echo -e "curl -L https://foundry.paradigm.xyz | bash"
    echo -e "foundryup"
    exit 1
fi

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
forge install foundry-rs/forge-std --no-commit

# Check if remapping is set correctly
if ! grep -q "@suzaku/core" foundry.toml 2>/dev/null; then
    echo -e "${RED}WARNING: @suzaku/core remapping not found in foundry.toml${NC}"
    echo -e "Please ensure you have the correct remapping for suzaku-core in your foundry.toml file."
    echo -e "Example: @suzaku/core=path/to/suzaku/core"
fi

# Create directories if they don't exist
mkdir -p deployments configs script

# Check if we have the example configs
if [ ! -f "configs/anvil-example.json" ]; then
    echo -e "${RED}Example configuration files not found.${NC}"
    echo -e "Please make sure you have example configuration files in the configs directory."
    exit 1
fi

# Start Anvil in the background
echo -e "${BLUE}Starting Anvil...${NC}"
anvil --block-time 1 > anvil.log 2>&1 &
ANVIL_PID=$!

# Give it a moment to start
sleep 2

# Ensure Anvil gets killed if the script is interrupted
trap 'kill $ANVIL_PID; echo -e "${RED}Anvil was killed${NC}"; exit 1' INT TERM EXIT

echo -e "${GREEN}Anvil started on http://localhost:8545 (PID: $ANVIL_PID)${NC}"

# Export private key and RPC for deployment
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export ANVIL_RPC_URL=http://localhost:8545

# Deploy factories and registries
echo -e "${BLUE}Deploying factories and registries...${NC}"
forge script script/DeployFactoriesRegistriesOptinsX.s.sol:DeployFactoriesRegistriesOptinsX \
  --rpc-url $ANVIL_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --sig "run(string)" \
  "anvil-example.json"

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Factories and registries deployed successfully!${NC}"
else
    echo -e "${RED}Failed to deploy factories and registries.${NC}"
    kill $ANVIL_PID
    exit 1
fi

# Deploy vault
echo -e "${BLUE}Deploying vault...${NC}"
forge script script/DeployVaultFullX.s.sol:DeployVaultFullX \
  --rpc-url $ANVIL_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --sig "run(string,string)" \
  "anvil-example.json" "anvil"

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Vault deployed successfully!${NC}"
else
    echo -e "${RED}Failed to deploy vault.${NC}"
    kill $ANVIL_PID
    exit 1
fi

# Deploy middleware
echo -e "${BLUE}Deploying middleware...${NC}"
forge script script/DeployMiddlewareX.s.sol:DeployMiddlewareX \
  --rpc-url $ANVIL_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --sig "run(string,string)" \
  "anvil-example.json" "anvil"

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Middleware deployed successfully!${NC}"
else
    echo -e "${RED}Failed to deploy middleware.${NC}"
    kill $ANVIL_PID
    exit 1
fi

# Deploy L2
echo -e "${BLUE}Deploying L2...${NC}"
forge script script/DeployAvaxL2X.s.sol:DeployAvaxL2X \
  --rpc-url $ANVIL_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --sig "run(string,string)" \
  "l2-example.json" "anvil"

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}L2 deployed successfully!${NC}"
else
    echo -e "${RED}Failed to deploy L2.${NC}"
    kill $ANVIL_PID
    exit 1
fi

# Deploy validator
echo -e "${BLUE}Deploying validator...${NC}"
forge script script/DeployValidatorX.s.sol:DeployValidatorX \
  --rpc-url $ANVIL_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --sig "run(string,string,string)" \
  "validator-example.json" "anvil" "anvil"

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Validator deployed successfully!${NC}"
else
    echo -e "${RED}Failed to deploy validator.${NC}"
    kill $ANVIL_PID
    exit 1
fi

echo -e "${GREEN}All deployments completed successfully!${NC}"
echo -e "Anvil is still running with PID: $ANVIL_PID"
echo -e "To stop Anvil, run: kill $ANVIL_PID"

# Cleanup the trap since we want to leave Anvil running
trap - INT TERM EXIT

echo -e "${BLUE}=== Setup Complete ===${NC}"
echo -e "Deployment artifacts are saved in the 'deployments' directory."
echo -e "You can now interact with the deployed contracts." 
