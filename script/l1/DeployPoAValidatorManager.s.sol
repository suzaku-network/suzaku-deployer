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

    function readInput(
        string memory input
    ) internal view returns (string memory) {
        string memory path = string.concat(vm.projectRoot(), "/", input);
        return vm.readFile(path);
    }

    function run(
        string memory inputJsonPath,
        uint256 proxyAdminOwnerKey,
        uint256 validatorManagerOwnerKey
    ) external {
        string memory jsonData = readInput(inputJsonPath);

        PoAUpgradeConfig memory poaConfig;
        poaConfig.proxyAddress = jsonData.readAddress(".proxyAddress");
        poaConfig.initialSecurityModuleMaxWeight = uint64(
            jsonData.readUint(".initialSecurityModuleMaxWeight")
        );

        string[] memory rawValidators = jsonData.readStringArray(
            ".migratedValidations"
        );
        poaConfig.migratedValidations = new bytes32[](rawValidators.length);
        for (uint256 i = 0; i < rawValidators.length; i++) {
            poaConfig.migratedValidations[i] = vm.parseBytes32(
                rawValidators[i]
            );
        }

        poaConfig.l1ID = bytes32(jsonData.readBytes32(".l1ID"));
        poaConfig.churnPeriodSeconds = uint64(
            jsonData.readUint(".churnPeriodSeconds")
        );
        poaConfig.maximumChurnPercentage = uint8(
            jsonData.readUint(".maximumChurnPercentage")
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

        // vm.stopBroadcast();
    }
}
