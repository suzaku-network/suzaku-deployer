// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2024 ADDPHO

pragma solidity 0.8.25;

import {BalancerMigrationConfig} from "@suzaku/contracts-lib/script/ValidatorManager/BalancerConfigTypes.s.sol";
import {MigratePoAToBalancer} from "@suzaku/contracts-lib/script/ValidatorManager/ExecuteMigratePoAToBalancer.s.sol";
import {ExtractValidators} from "@suzaku/contracts-lib/script/ValidatorManager/ExtractValidators.s.sol";
import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {DateTimeLib} from "../libraries/DateTimeLib.sol";

contract DeployUpgradePoAToBalancer is Script {
    using stdJson for string;

    function run(
        string memory inputJsonPath,
        uint256 proxyAdminOwnerKey,
        uint256 validatorManagerOwnerKey
    ) external {
        string memory jsonPath = string.concat(
            vm.projectRoot(),
            "/configs/",
            inputJsonPath
        );
        string memory jsonData = vm.readFile(jsonPath);

        BalancerMigrationConfig memory balancerConfig;
        balancerConfig.proxyAddress = jsonData.readAddress(
            ".deployed.validatorManagerProxy"
        );
        balancerConfig.initialSecurityModuleMaxWeight = uint64(
            jsonData.readUint(".balancer.initialSecurityModuleMaxWeight")
        );

        balancerConfig.subnetID = bytes32(jsonData.readBytes32(".subnetID"));
        balancerConfig.churnPeriodSeconds = uint64(
            jsonData.readUint(".churnPeriodSeconds")
        );
        balancerConfig.maximumChurnPercentage = uint8(
            jsonData.readUint(".maximumChurnPercentage")
        );

        balancerConfig.proxyAdminOwnerAddress = vm.addr(proxyAdminOwnerKey);
        balancerConfig.validatorManagerOwnerAddress = vm.addr(
            validatorManagerOwnerKey
        );

        balancerConfig.validatorManagerProxy = jsonData.readAddress(
            ".deployed.validatorManagerProxy"
        );
        balancerConfig.poaManager = jsonData.readAddress(
            ".deployed.poaManagerAddress"
        );

        // Build migratedValidators array using ExtractValidators
        ExtractValidators extractor = new ExtractValidators();

        bytes[] memory rawValidators = jsonData.readBytesArray(
            ".balancer.migratedValidators"
        );

        bytes[] memory migratedValidators = extractor
            .extractActiveOrPendingAdded(
                balancerConfig.validatorManagerProxy,
                rawValidators
            );

        balancerConfig.migratedValidators = migratedValidators;

        MigratePoAToBalancer upgradeScript = new MigratePoAToBalancer();
        (
            address balancerValidatorManagerProxy,
            address securityModule,

        ) = upgradeScript.executeMigratePoAToBalancer(
                balancerConfig,
                proxyAdminOwnerKey,
                validatorManagerOwnerKey
            );
        console2.log("Upgraded PoA proxy at:", balancerValidatorManagerProxy);
        console2.log("Deployed PoA security module at:", securityModule);

        // Write JSON output
        string memory chainId = vm.toString(block.chainid);
        string memory date = DateTimeLib.timestampToDate(block.timestamp);
        string memory path = string.concat(
            "./deployments/",
            chainId,
            "/",
            date
        );
        vm.createDir(path, true);

        string memory outFile = string.concat(
            path,
            "/upgradePoAToBalancer.json"
        );
        string memory label = "UpgradePoAToBalancer";
        string memory data;

        data = vm.serializeAddress(
            label,
            "ValidatorManagerProxy",
            balancerConfig.proxyAddress
        );
        data = vm.serializeUint(
            label,
            "initialSecurityModuleMaxWeight",
            balancerConfig.initialSecurityModuleMaxWeight
        );

        data = vm.serializeAddress(
            label,
            "proxyAdminOwnerAddress",
            balancerConfig.proxyAdminOwnerAddress
        );
        data = vm.serializeAddress(
            label,
            "validatorManagerOwnerAddress",
            balancerConfig.validatorManagerOwnerAddress
        );
        data = vm.serializeBytes32(label, "subnetID", balancerConfig.subnetID);
        data = vm.serializeUint(
            label,
            "churnPeriodSeconds",
            balancerConfig.churnPeriodSeconds
        );
        data = vm.serializeUint(
            label,
            "maximumChurnPercentage",
            balancerConfig.maximumChurnPercentage
        );

        data = vm.serializeAddress(
            label,
            "BalancerValidatorManagerProxy",
            balancerValidatorManagerProxy
        );
        data = vm.serializeAddress(label, "PoASecurityModule", securityModule);

        vm.writeJson(data, outFile);
        console2.log("Output JSON =>", outFile);
    }
}
