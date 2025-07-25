// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {
    AvalancheL1Middleware,
    AvalancheL1MiddlewareSettings
} from "@suzaku/core/src/contracts/middleware/AvalancheL1Middleware.sol";
import {MiddlewareVaultManager} from "@suzaku/core/src/contracts/middleware/MiddlewareVaultManager.sol";
import {MiddlewareConfig} from "@suzaku/core/script/middleware/MiddlewareL1Types.s.sol";

contract DeployMiddlewareL1 is Script {
    using stdJson for string;

    function readInput(
        string memory input
    ) internal view returns (string memory) {
        string memory path = string.concat(
            vm.projectRoot(),
            "/",
            input
        );
        return vm.readFile(path);
    }

    function run(string memory input) external {
        // Read the JSON file
        string memory json = readInput(input);

        // Parse JSON into MiddlewareConfig struct
        MiddlewareConfig memory middlewareConfig;
        middlewareConfig.middlewareOwnerAddress = json.readAddress(".roles.middlewareOwner_middleware");
        middlewareConfig.validatorManager = json.readAddress(".deployed.validatorManager");
        middlewareConfig.operatorRegistry = json.readAddress(".deployed.operatorRegistry");
        middlewareConfig.vaultFactory = json.readAddress(".deployed.vaultFactory");
        middlewareConfig.operatorL1OptIn = json.readAddress(".deployed.operatorL1OptIn");
        middlewareConfig.primaryAsset = json.readAddress(".deployed.primaryAsset");
        middlewareConfig.primaryAssetMaxStake = json.readUint(".middleware.primaryAssetMaxStake");
        middlewareConfig.primaryAssetMinStake = json.readUint(".middleware.primaryAssetMinStake");
        middlewareConfig.primaryAssetWeightScaleFactor = json.readUint(".middleware.primaryAssetWeightScaleFactor");
        middlewareConfig.epochDuration = uint48(json.readUint(".middleware.epochDuration"));
        middlewareConfig.slashingWindow = uint48(json.readUint(".middleware.slashingWindow"));
        middlewareConfig.stakeUpdateWindow = uint48(json.readUint(".middleware.stakeUpdateWindow"));
        middlewareConfig.vaultRemovalEpochDelay = uint48(json.readUint(".middleware.vaultRemovalEpochDelay"));

        // Execute deployment with fixed broadcasting
        (address middlewareL1, address vaultManager) = executeMiddlewareL1DeploymentFixed(middlewareConfig);

        // Write deployment data
        string memory deploymentData = string.concat(
            "{\"middleware\": \"", vm.toString(middlewareL1), "\", ",
            "\"vaultManager\": \"", vm.toString(vaultManager), "\"}"
        );
        
        vm.writeFile("test_middleware_deployment.json", deploymentData);
        console2.log("Middleware deployment completed. L1 Middleware:", middlewareL1);
        console2.log("Vault Manager:", vaultManager);
    }

    function executeMiddlewareL1DeploymentFixed(
        MiddlewareConfig memory middlewareConfig
    ) public returns (address middlewareL1, address vaultManager) {
        vm.startBroadcast();

        // Deploy the AvalancheL1Middleware
        AvalancheL1Middleware middleware = new AvalancheL1Middleware(
            AvalancheL1MiddlewareSettings({
                l1ValidatorManager: middlewareConfig.validatorManager,
                operatorRegistry: middlewareConfig.operatorRegistry,
                vaultRegistry: middlewareConfig.vaultFactory,
                operatorL1Optin: middlewareConfig.operatorL1OptIn,
                epochDuration: middlewareConfig.epochDuration,
                slashingWindow: middlewareConfig.slashingWindow,
                stakeUpdateWindow: middlewareConfig.stakeUpdateWindow
            }),
            middlewareConfig.middlewareOwnerAddress, // Set the owner
            middlewareConfig.primaryAsset,
            middlewareConfig.primaryAssetMaxStake,
            middlewareConfig.primaryAssetMinStake,
            middlewareConfig.primaryAssetWeightScaleFactor
        );

        // Deploy the MiddlewareVaultManager
        MiddlewareVaultManager middlewareVaultManager = new MiddlewareVaultManager(
            middlewareConfig.vaultFactory, 
            middlewareConfig.middlewareOwnerAddress, 
            address(middleware), 
            middlewareConfig.vaultRemovalEpochDelay
        );

        // Don't stop broadcast - just use prank to set the vault manager
        // The broadcast context will maintain the same sender throughout
        
        vm.stopBroadcast();
        
        // Use prank to set vault manager as the owner
        vm.prank(middlewareConfig.middlewareOwnerAddress);
        middleware.setVaultManager(address(middlewareVaultManager));

        // Return addresses
        middlewareL1 = address(middleware);
        vaultManager = address(middlewareVaultManager);

        console2.log("AvalancheL1Middleware deployed at:", middlewareL1);
        console2.log("MiddlewareVaultManager deployed at:", vaultManager);
        console2.log("Using validatorManager at:", middlewareConfig.validatorManager);
        console2.log("Using operatorRegistry at:", middlewareConfig.operatorRegistry);
        console2.log("Using vaultFactory at:", middlewareConfig.vaultFactory);
        console2.log("Using operatorL1OptIn at:", middlewareConfig.operatorL1OptIn);
    }
}
