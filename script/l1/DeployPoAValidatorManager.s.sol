// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2024 ADDPHO

pragma solidity 0.8.25;

import {PoAUpgradeConfig} from "@suzaku/contracts-lib/script/ValidatorManager/PoAUpgradeConfigTypes.s.sol";

import {ExecutePoAValidatorManager} from "@suzaku/contracts-lib/script/ValidatorManager/PoAValidatorManager.s.sol";
import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

/**
 * @dev Deploy a PoA Validator Manager
 */
contract DeployPoAValidatorManager is Script {
    using stdJson for string;

    function run(
        string memory inputJsonPath,
        uint256 proxyAdminOwnerKey,
        uint256 validatorManagerOwnerKey
    ) external {
        string memory jsonPath = string.concat(vm.projectRoot(), "/configs/", inputJsonPath);
        string memory jsonData = vm.readFile(jsonPath);

        PoAUpgradeConfig memory poaConfig;
        poaConfig.proxyAddress = jsonData.readAddress(".deployed.proxyAddress");
        poaConfig.initialSecurityModuleMaxWeight = uint64(
            jsonData.readUint(".balancer.initialSecurityModuleMaxWeight")
        );

        string[] memory rawValidators = jsonData.readStringArray(
            ".balancer.migratedValidators"
        );
        poaConfig.migratedValidators = new bytes[](rawValidators.length);
        for (uint256 i = 0; i < rawValidators.length; i++) {
            poaConfig.migratedValidators[i] = vm.parseBytes(rawValidators[i]);
        }

        poaConfig.l1ID = bytes32(jsonData.readBytes32(".balancer.l1ID"));
        poaConfig.churnPeriodSeconds = uint64(
            jsonData.readUint(".balancer.churnPeriodSeconds")
        );
        poaConfig.maximumChurnPercentage = uint8(
            jsonData.readUint(".balancer.maximumChurnPercentage")
        );

        poaConfig.proxyAdminOwnerAddress = vm.addr(proxyAdminOwnerKey);
        poaConfig.validatorManagerOwnerAddress = vm.addr(
            validatorManagerOwnerKey
        );

        // vm.startBroadcast(proxyAdminOwnerKey);
        ExecutePoAValidatorManager upgradeScript = new ExecutePoAValidatorManager();
        address finalProxy = upgradeScript.executeDeployPoA(
            poaConfig,
            proxyAdminOwnerKey
        );
        console2.log("Deployed PoA proxy at:", finalProxy);

        // Update deployment file with the new validatorManager address
        vm.writeJson(vm.toString(finalProxy), jsonPath, ".deployed.proxyAddress");

        console2.log("Updated deployment file with validatorManager:", finalProxy);

        // vm.stopBroadcast();
    }
}
