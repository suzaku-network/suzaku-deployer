// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {stdJson} from "forge-std/StdJson.sol";
import {Script, console2} from "forge-std/Script.sol";

import {MiddlewareConfig} from "@suzaku/core/script/middleware/MiddlewareL1Types.s.sol";
import {DeployTestAvalancheL1Middleware} from "@suzaku/core/script/middleware/MiddlewareL1.s.sol";

import {DateTimeLib} from "../libraries/DateTimeLib.sol";

contract DeployMiddlewareL1 is Script {
    using stdJson for string;

    function readInput(
        string memory input
    ) internal view returns (string memory) {
        string memory path = string.concat(vm.projectRoot(), "/", input);
        return vm.readFile(path);
    }

    function run(string memory input) external {
        string memory json = readInput(input);

        // Parse fields into MiddlewareConfig
        MiddlewareConfig memory middlewareConfig;
        middlewareConfig.l1MiddlewareOwnerAddress = json.readAddress(
            ".roles.l1MiddlewareOwner_middleware"
        );

        middlewareConfig.validatorManager = json.readAddress(
            ".deployed.validatorManager"
        );
        middlewareConfig.operatorRegistry = json.readAddress(
            ".deployed.operatorRegistry"
        );
        middlewareConfig.vaultFactory = json.readAddress(".deployed.vaultFactory");
        middlewareConfig.operatorL1OptIn = json.readAddress(".deployed.operatorL1OptIn");

        middlewareConfig.primaryAsset = json.readAddress(".deployed.primaryAsset");
        middlewareConfig.primaryAssetMaxStake = json.readUint(
            ".middleware.primaryAssetMaxStake"
        );
        middlewareConfig.primaryAssetMinStake = json.readUint(
            ".middleware.primaryAssetMinStake"
        );
        middlewareConfig.primaryAssetWeightScaleFactor = json.readUint(
            ".middleware.primaryAssetWeightScaleFactor"
        );
        middlewareConfig.epochDuration = uint48(
            json.readUint(".middleware.epochDuration")
        );
        middlewareConfig.slashingWindow = uint48(
            json.readUint(".middleware.slashingWindow")
        );
        middlewareConfig.stakeUpdateWindow = uint48(
            json.readUint(".middleware.stakeUpdateWindow")
        );
        middlewareConfig.vaultRemovalEpochDelay = uint48(
            json.readUint(".middleware.vaultRemovalEpochDelay")
        );

        // Deploy
        DeployTestAvalancheL1Middleware deploy = new DeployTestAvalancheL1Middleware();
        (address middlewareL1, address vaultManager) = deploy
            .executeMiddlewareL1Deployment(middlewareConfig);

        // Write to JSON
        string memory chainId = vm.toString(block.chainid);
        string memory date = DateTimeLib.timestampToDate(block.timestamp);
        string memory path = string.concat(
            "./deployments/",
            chainId,
            "/",
            date
        );
        vm.createDir(path, true);

        string memory label = "Middleware";
        string memory data = vm.serializeAddress(
            label,
            "l1MiddlewareOwnerAddress",
            middlewareConfig.l1MiddlewareOwnerAddress
        );

        data = vm.serializeAddress(
            label,
            "validatorManager",
            middlewareConfig.validatorManager
        );
        data = vm.serializeAddress(
            label,
            "operatorRegistry",
            middlewareConfig.operatorRegistry
        );
        data = vm.serializeAddress(
            label,
            "vaultFactory",
            middlewareConfig.vaultFactory
        );
        data = vm.serializeAddress(
            label,
            "operatorL1OptIn",
            middlewareConfig.operatorL1OptIn
        );

        data = vm.serializeAddress(
            label,
            "primaryAsset",
            middlewareConfig.primaryAsset
        );
        data = vm.serializeUint(
            label,
            "primaryAssetMaxStake",
            middlewareConfig.primaryAssetMaxStake
        );
        data = vm.serializeUint(
            label,
            "primaryAssetMinStake",
            middlewareConfig.primaryAssetMinStake
        );
        data = vm.serializeUint(
            label,
            "primaryAssetWeightScaleFactor",
            middlewareConfig.primaryAssetWeightScaleFactor
        );
        data = vm.serializeUint(
            label,
            "epochDuration",
            middlewareConfig.epochDuration
        );
        data = vm.serializeUint(
            label,
            "slashingWindow",
            middlewareConfig.slashingWindow
        );
        data = vm.serializeUint(
            label,
            "stakeUpdateWindow",
            middlewareConfig.stakeUpdateWindow
        );
        data = vm.serializeUint(
            label,
            "vaultRemovalEpochDelay",
            middlewareConfig.vaultRemovalEpochDelay
        );

        // newly deployed
        data = vm.serializeAddress(label, "middlewareL1", middlewareL1);
        data = vm.serializeAddress(label, "vaultManager", vaultManager);

        string memory outFile = string.concat(path, "/l1Middleware.json");
        vm.writeJson(data, outFile);
        console2.log("Deployed L1 middleware to:", middlewareL1);
        console2.log("Deployed VaultManager to:", vaultManager);
        console2.log("Output JSON =>", outFile);
    }
}
