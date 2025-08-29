// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2024 ADDPHO

pragma solidity 0.8.25;

import {BalancerMigrationConfig} from "@suzaku/contracts-lib/script/ValidatorManager/BalancerConfigTypes.s.sol";

import {ExecutePoAValidatorManager} from "@suzaku/contracts-lib/script/ValidatorManager/ExecutePoAValidatorManager.s.sol";
import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";

/**
 * @dev Deploy a Validator Manager and PoA Manager as Validator Manager owner
 */
contract DeployPoAValidatorManager is Script {
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

        BalancerMigrationConfig memory poaConfig;

        poaConfig.subnetID = bytes32(jsonData.readBytes32(".subnetID"));
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

        ExecutePoAValidatorManager upgradeScript = new ExecutePoAValidatorManager();
        (
            address validatorManagerProxy,
            address poaManagerAddress
        ) = upgradeScript.executeDeployPoA(
                poaConfig,
                proxyAdminOwnerKey,
                validatorManagerOwnerKey
            );
        console2.log(
            "Deployed Validator Manager proxy at:",
            validatorManagerProxy
        );
        console2.log("Deployed PoA Manager at:", poaManagerAddress);

        // Update deployment file with the new validatorManager and poaManager addresses
        vm.writeJson(
            vm.toString(validatorManagerProxy),
            jsonPath,
            ".deployed.validatorManagerProxy"
        );
        vm.writeJson(
            vm.toString(poaManagerAddress),
            jsonPath,
            ".deployed.poaManagerAddress"
        );

        console2.log(
            "Updated deployment file with validatorManager:",
            validatorManagerProxy
        );
        console2.log(
            "Updated deployment file with poaManager:",
            poaManagerAddress
        );
    }
}
