// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2024 ADDPHO

pragma solidity 0.8.25;

import {stdJson} from "forge-std/StdJson.sol";
import {ValidatorManager} from "@avalabs/icm-contracts/validator-manager/ValidatorManager.sol";
import {PoAManager} from "@avalabs/icm-contracts/validator-manager/PoAManager.sol";
import {ICMInitializable} from "@avalabs/icm-contracts/utilities/ICMInitializable.sol";
import {UnsafeUpgrades} from "@openzeppelin/foundry-upgrades/Upgrades.sol";
import {Script, console2} from "forge-std/Script.sol";
import {IValidatorManagerExternalOwnable} from
    "@avalabs/icm-contracts/validator-manager/interfaces/IValidatorManagerExternalOwnable.sol";

/**
 * @dev Deploy a Validator Manager and PoA Manager then upgrade.
 * @param proxyAdminOwnerKey the private key of the ProxyAdmin owner
 * @param validatorManagerOwnerKey the private key of the ValidatorManager owner
 * @param inputJsonPath the path to the configuration file. Should fit configs/balancerExample.json schema
 */
contract UpgradeValidatorManagerToV2_1_0 is Script {
    using stdJson for string;

    function run(
        uint256 proxyAdminOwnerKey,
        uint256 validatorManagerOwnerKey,
        string memory deploymentFile
    ) external {
        // Read deployment file
        string memory deploymentPath = string.concat(vm.projectRoot(), "/configs/", deploymentFile);
        string memory deploymentJson = vm.readFile(deploymentPath);
        // Get validatorManagerProxy address from deployment file
        address validatorManagerProxy = deploymentJson.readAddress(".deployed.validatorManagerProxy");

        vm.startBroadcast(proxyAdminOwnerKey);
        // Deploy ValidatorManager v2.1.0
        ValidatorManager validatorManagerImpl = new ValidatorManager(ICMInitializable.Allowed);
        // Change the implementation target of the validatorManagerProxy
        UnsafeUpgrades.upgradeProxy(validatorManagerProxy, address(validatorManagerImpl), "");
        // Deploy PoAManager
        PoAManager PoAMng = new PoAManager( vm.addr(validatorManagerOwnerKey), IValidatorManagerExternalOwnable(validatorManagerProxy));
        // Transfer the validatorManagerProxy ownership from proxyAdminOwner to the PoAManager
        IValidatorManagerExternalOwnable(validatorManagerProxy).transferOwnership(address(PoAMng));
        vm.stopBroadcast();
        // Check if deployment file exists
        try vm.readFile(deploymentPath) {
            // File exists, update the fields
            vm.writeJson(vm.toString(address(PoAMng)), deploymentPath, ".deployed.poaManagerAddress");
        } catch {
            revert(
                string.concat(
                    "ERROR: Deployment file '", deploymentFile, "' not found. ",
                    "Please create it by copying configs/balancerExample.json ",
                    "and configuring all required values for your deployment."
                )
            );
        }

        console2.log("PoAManager deployed and saved in the deployment file:", address(PoAMng));
        console2.log("validator Manager v2.1.0 deployed:", address(validatorManagerImpl));
        console2.log("Proxy implementation upgraded");
    }
}
