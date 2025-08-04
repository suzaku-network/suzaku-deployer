// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {MiddlewareConfig} from "@suzaku/core/script/middleware/MiddlewareL1Types.s.sol";
import {DeployTestAvalancheL1Middleware} from "@suzaku/core/script/middleware/MiddlewareL1.s.sol";

contract DeployMiddlewareL1 is Script {
    using stdJson for string;

    function run(string memory inputJsonPath) external {
        // Read the JSON file
        string memory jsonPath = string.concat(vm.projectRoot(), "/configs/", inputJsonPath);
        string memory jsonData = vm.readFile(jsonPath);

        // Parse JSON into MiddlewareConfig struct
        MiddlewareConfig memory middlewareConfig;
        middlewareConfig.middlewareOwnerAddress = jsonData.readAddress(".roles.middlewareOwner_middleware");
        middlewareConfig.validatorManager = jsonData.readAddress(".deployed.validatorManager");
        middlewareConfig.operatorRegistry = jsonData.readAddress(".deployed.operatorRegistry");
        middlewareConfig.vaultFactory = jsonData.readAddress(".deployed.vaultFactory");
        middlewareConfig.operatorL1OptIn = jsonData.readAddress(".deployed.operatorL1OptIn");
        middlewareConfig.primaryAsset = jsonData.readAddress(".deployed.primaryAsset");
        middlewareConfig.primaryAssetMaxStake = jsonData.readUint(".middleware.primaryAssetMaxStake");
        middlewareConfig.primaryAssetMinStake = jsonData.readUint(".middleware.primaryAssetMinStake");
        middlewareConfig.primaryAssetWeightScaleFactor = jsonData.readUint(".middleware.primaryAssetWeightScaleFactor");
        middlewareConfig.epochDuration = uint48(jsonData.readUint(".middleware.epochDuration"));
        middlewareConfig.slashingWindow = uint48(jsonData.readUint(".middleware.slashingWindow"));
        middlewareConfig.stakeUpdateWindow = uint48(jsonData.readUint(".middleware.stakeUpdateWindow"));
        middlewareConfig.vaultRemovalEpochDelay = uint48(jsonData.readUint(".middleware.vaultRemovalEpochDelay"));

        // Deploy
        console2.log("Deploying middleware...");
        DeployTestAvalancheL1Middleware deployMiddleware = new DeployTestAvalancheL1Middleware();
        (address middleware, address vaultManager) = deployMiddleware.executeMiddlewareL1Deployment(middlewareConfig);
        
        // Update deployment file with the new middlewareL1 and vaultManager address
        vm.writeJson(vm.toString(middleware), jsonPath, ".deployed.middleware");
        vm.writeJson(vm.toString(vaultManager), jsonPath, ".deployed.vaultManager");

        console2.log("Updated deployment file");

        console2.log("Middleware deployment completed.");
    }

}
