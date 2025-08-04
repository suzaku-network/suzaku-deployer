// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2024 ADDPHO

pragma solidity 0.8.25;

import {PoAUpgradeConfig} from "@suzaku/contracts-lib/script/ValidatorManager/PoAUpgradeConfigTypes.s.sol";
import {UpgradePoAToBalancer} from "@suzaku/contracts-lib/script/ValidatorManager/UpgradePoAToBalancer.s.sol";
import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {DateTimeLib} from "../libraries/DateTimeLib.sol";

contract DeployUpgradePoAToBalancer is Script {
    using stdJson for string;

    function run(
        string memory inputJsonPath,
        uint256 proxyAdminOwnerKey
    ) external {
        string memory jsonPath = string.concat(vm.projectRoot(), "/configs/", inputJsonPath);
        string memory jsonData =  vm.readFile(jsonPath);

        PoAUpgradeConfig memory balancerConfig;
        balancerConfig.proxyAddress = jsonData.readAddress(
            ".deployed.proxyAddress"
        );
        balancerConfig.validatorManagerOwnerAddress = jsonData.readAddress(
            ".roles.validatorManagerOwner_balancer"
        );
        balancerConfig.initialSecurityModuleMaxWeight = uint64(
            jsonData.readUint(".balancer.initialSecurityModuleMaxWeight")
        );

        string[] memory rawValidators = jsonData.readStringArray(
            ".balancer.migratedValidators"
        );
        balancerConfig.migratedValidators = new bytes[](rawValidators.length);
        for (uint256 i = 0; i < rawValidators.length; i++) {
            balancerConfig.migratedValidators[i] = vm.parseBytes(
                rawValidators[i]
            );
        }

        balancerConfig.l1ID = bytes32(jsonData.readBytes32(".balancer.l1ID"));
        balancerConfig.churnPeriodSeconds = uint64(
            jsonData.readUint(".balancer.churnPeriodSeconds")
        );
        balancerConfig.maximumChurnPercentage = uint8(
            jsonData.readUint(".balancer.maximumChurnPercentage")
        );

        balancerConfig.proxyAdminOwnerAddress = vm.addr(proxyAdminOwnerKey);

        UpgradePoAToBalancer upgradeScript = new UpgradePoAToBalancer();
        (address finalProxy, address securityModule) = upgradeScript
            .executeUpgradePoAToBalancer(balancerConfig, proxyAdminOwnerKey);
        console2.log("Upgraded PoA proxy at:", finalProxy);
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

        string memory outFile = string.concat(path, "/poAUpgrade.json");
        string memory label = "PoAUpgrade";
        string memory data;

        data = vm.serializeAddress(
            label,
            "poAProxyAddress",
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
        data = vm.serializeBytes32(label, "l1ID", balancerConfig.l1ID);
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

        data = vm.serializeAddress(label, "UpgradedPoAProxy", finalProxy);
        data = vm.serializeAddress(label, "PoASecurityModule", securityModule);

        vm.writeJson(data, outFile);
        console2.log("Output JSON =>", outFile);
    }
}
