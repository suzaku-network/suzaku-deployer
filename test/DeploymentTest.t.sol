// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";

import {DeployMiddlewareL1} from "../script/l1/DeployMiddleware.s.sol";
import {DeployRewardsL1} from "../script/l1/DeployRewards.s.sol";
import {DeployVaultFull} from "../script/curator/DeployCurator.s.sol";
import {DeployPoAValidatorManager} from "../script/l1/DeployPoAValidatorManager.s.sol";

import {DeployFactoriesRegistriesOptIns} from "@suzaku/core/script/deploy/FactoryRegistryOptins.s.sol";
import {BootstraperConfig} from "@suzaku/core/script/deploy/FactoriesRegistriesOptinsTypes.s.sol";
import {GeneralConfig, FactoryConfig, OptinConfig, L1RegistryConfig} from "@suzaku/core/script/deploy/FactoriesRegistriesOptinsTypes.s.sol";

import {Token} from "@suzaku/core/test/mocks/MockToken.sol";

contract DeploymentTest is Test {
    using stdJson for string;

    address constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant PROTOCOL_OWNER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // Deployed contract addresses
    address vaultFactory;
    address delegatorFactory;
    address slasherFactory;
    address l1Registry;
    address operatorRegistry;
    address operatorVaultOptInService;
    address operatorL1OptInService;
    address collateralToken;

    function setUp() public {
        // Deploy mock collateral token
        collateralToken = address(new Token("TestToken"));
        console2.log("Mock collateral deployed at:", collateralToken);

        // Deploy core factories and registries first
        _deployFactoriesAndRegistries();
    }

    function _deployFactoriesAndRegistries() internal {
        DeployFactoriesRegistriesOptIns deployer = new DeployFactoriesRegistriesOptIns();
        
        BootstraperConfig memory config = BootstraperConfig({
            generalConfig: GeneralConfig({
                owner: OWNER,
                initialVaultVersion: 1,
                defaultIncludeSlasher: false
            }),
            factoryConfig: FactoryConfig({
                vaultFactory: address(0),
                delegatorFactory: address(0),
                slasherFactory: address(0),
                l1Registry: address(0),
                operatorRegistry: address(0)
            }),
            optinConfig: OptinConfig({
                operatorVaultOptInService: address(0),
                operatorL1OptInService: address(0)
            }),
            l1RegistryConfig: L1RegistryConfig({
                feeCollector: OWNER,
                initialRegisterFee: 0.01 ether,
                maxRegisterFee: 1 ether,
                owner: OWNER
            })
        });

        (
            vaultFactory,
            delegatorFactory,
            slasherFactory,
            l1Registry,
            operatorRegistry,
            operatorVaultOptInService,
            operatorL1OptInService
        ) = deployer.executeFactoriesDeployment(config);

        console2.log("Core contracts deployed:");
        console2.log("- VaultFactory:", vaultFactory);
        console2.log("- DelegatorFactory:", delegatorFactory);
        console2.log("- L1Registry:", l1Registry);
        console2.log("- OperatorRegistry:", operatorRegistry);
    }

    function test_VaultDeployment() public {
        // Create test vault config file
        string memory vaultConfig = string.concat(
            '{"factoriesFile":"protocolExample.json",',
            '"vault":{"name":"Test Vault","symbol":"TV","epochDuration":3600,"depositWhitelist":false,"depositLimit":"1000000000000000000000","initialVaultVersion":1,',
            '"delegatorConfig":{"delegatorIndex":0,"resolverEpochsDelay":10},',
            '"slasherConfig":{"slasherIndex":0,"vetoDuration":600,"includeSlasher":false}},',
            '"collateral":{"underlyingToken":"', vm.toString(collateralToken), '"},',
            '"roles":{"vaultOwner_vault":"', vm.toString(OWNER), '",',
            '"depositWhitelistSetRoleHolder_vault":"', vm.toString(OWNER), '",',
            '"depositLimitSetRoleHolder_vault":"', vm.toString(OWNER), '",',
            '"depositorWhitelistRoleHolder_vault":"', vm.toString(OWNER), '",',
            '"isDepositLimitSetRoleHolder_vault":"', vm.toString(OWNER), '",',
            '"l1LimitSetRoleHolders_delegator":"', vm.toString(OWNER), '",',
            '"operatorL1SharesSetRoleHolders_delegator":"', vm.toString(OWNER), '"},',
            '"deployed":{"vaultFactory":"', vm.toString(vaultFactory), '",',
            '"delegatorFactory":"', vm.toString(delegatorFactory), '",',
            '"slasherFactory":"', vm.toString(slasherFactory), '",',
            '"l1Registry":"', vm.toString(l1Registry), '",',
            '"operatorRegistry":"', vm.toString(operatorRegistry), '",',
            '"operatorVaultOptInService":"', vm.toString(operatorVaultOptInService), '",',
            '"operatorL1OptInService":"', vm.toString(operatorL1OptInService), '"}}'
        );
        
        vm.writeJson(vaultConfig, "./test_vault_deployment.json");

        // Test vault deployment
        DeployVaultFull vaultDeployer = new DeployVaultFull();
        
        vm.expectEmit(false, false, false, false);
        emit log("Testing vault deployment...");
        
        // This should not revert
        vaultDeployer.run("test_vault_deployment.json");

        // Clean up
        vm.removeFile("./test_vault_deployment.json");

        console2.log("SUCCESS: Vault deployment test passed");
    }

    function test_RewardsDeployment() public {
        // Deploy a mock middleware first
        address mockMiddleware = address(0x123);
        
        // Create test rewards config
        string memory rewardsConfig = string.concat(
            '{"factoriesFile":"protocolExample.json",',
            '"rewards":{"protocolFee":1000,"operatorFee":2000,"curatorFee":1000,"minRequiredUptime":11520},',
            '"roles":{"rewardsAdmin_rewards":"', vm.toString(OWNER), '",',
            '"protocolOwner_rewards":"', vm.toString(PROTOCOL_OWNER), '"},',
            '"deployed":{"l1Middleware":"', vm.toString(mockMiddleware), '",',
            '"l1ChainID":"0x66226f76a8fb608290afeadc795bf8fe1e54779285228833d489ebf21ca06a07"}}'
        );
        
        vm.writeJson(rewardsConfig, "./test_rewards_deployment.json");

        // Test rewards deployment
        DeployRewardsL1 rewardsDeployer = new DeployRewardsL1();
        
        vm.expectEmit(false, false, false, false);
        emit log("Testing rewards deployment...");
        
        // This should not revert
        rewardsDeployer.run("test_rewards_deployment.json");

        // Clean up
        vm.removeFile("./test_rewards_deployment.json");

        console2.log("SUCCESS: Rewards deployment test passed");
    }

    function test_MiddlewareDeployment() public {
        // Create test middleware config
        string memory middlewareConfig = string.concat(
            '{"factoriesFile":"protocolExample.json",',
            '"middleware":{"primaryAssetMaxStake":5000000000000000000000,"primaryAssetMinStake":100000000000000000000,',
            '"primaryAssetWeightScaleFactor":20000000000000000,"epochDuration":1800,"slashingWindow":2100,',
            '"stakeUpdateWindow":900,"vaultRemovalEpochDelay":24},',
            '"roles":{"l1MiddlewareOwner_middleware":"', vm.toString(OWNER), '"},',
            '"deployed":{"validatorManager":"', vm.toString(address(0x456)), '",',
            '"operatorRegistry":"', vm.toString(operatorRegistry), '",',
            '"vaultFactory":"', vm.toString(vaultFactory), '",',
            '"operatorL1OptIn":"', vm.toString(operatorL1OptInService), '",',
            '"primaryAsset":"', vm.toString(collateralToken), '"}}'
        );
        
        vm.writeJson(middlewareConfig, "./test_middleware_deployment.json");

        // Test middleware deployment
        DeployMiddlewareL1 middlewareDeployer = new DeployMiddlewareL1();
        
        vm.expectEmit(false, false, false, false);
        emit log("Testing middleware deployment...");
        
        // This should not revert
        middlewareDeployer.run("test_middleware_deployment.json");

        // Clean up
        vm.removeFile("./test_middleware_deployment.json");

        console2.log("SUCCESS: Middleware deployment test passed");
    }

    function test_ConfigStructureCompatibility() public {
        // Test that our example configs have the right structure for the scripts
        
        // Test middleware config structure
        string memory middlewareJson = vm.readFile("configs/middlewareExample.json");
        
        // Should not revert when accessing nested fields
        middlewareJson.readAddress(".roles.l1MiddlewareOwner_middleware");
        middlewareJson.readUint(".middleware.epochDuration");
        middlewareJson.readAddress(".deployed.vaultFactory");
        
        // Test rewards config structure  
        string memory rewardsJson = vm.readFile("configs/rewardsExample.json");
        rewardsJson.readAddress(".roles.rewardsAdmin_rewards");
        rewardsJson.readUint(".rewards.protocolFee");
        rewardsJson.readAddress(".deployed.l1Middleware");
        
        // Test vault config structure
        string memory vaultJson = vm.readFile("configs/vaultExample.json");
        vaultJson.readAddress(".roles.vaultOwner_vault");
        vaultJson.readUint(".vault.epochDuration");
        vaultJson.readAddress(".deployed.vaultFactory");

        console2.log("SUCCESS: All config structures are compatible with deployment scripts");
    }
} 
