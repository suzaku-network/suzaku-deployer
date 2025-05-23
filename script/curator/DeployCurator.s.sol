// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2024 ADDPHO

pragma solidity 0.8.25;

import {stdJson} from "forge-std/StdJson.sol";
import {Script, console2} from "forge-std/Script.sol";
import {VaultConfig, DelegatorConfig, SlasherConfig, FactoryConfig, RolesConfig} from "@suzaku/core/script/deploy/VaultConfigTypes.s.sol";
import {VaultFull} from "@suzaku/core/script/deploy/VaultFull.s.sol";
import {DateTimeLib} from "../libraries/DateTimeLib.sol";

contract DeployVaultFull is Script {
    using stdJson for string;

    // Reads the JSON file from ./config/input/<input> (the <input> itself can include ".json")
    function readInput(
        string memory input
    ) internal view returns (string memory) {
        string memory path = string.concat(
            vm.projectRoot(),
            "/configs/",
            input
        );
        return vm.readFile(path);
    }

    // Overload run() to accept a string argument
    function run(string memory input) external {
        // Read the JSON file
        string memory json = readInput(input);

        // Parse JSON into VaultConfig struct
        VaultConfig memory vaultCfg;
        vaultCfg.owner = json.readAddress(".owner");
        vaultCfg.collateralAsset = json.readAddress(".collateralAsset");
        vaultCfg.epochDuration = uint48(json.readUint(".epochDuration"));
        vaultCfg.depositWhitelist = json.readBool(".depositWhitelist");
        vaultCfg.depositLimit = uint256(json.readUint(".depositLimit"));
        vaultCfg.initialVaultVersion = uint16(
            json.readUint(".initialVaultVersion")
        );
        vaultCfg.name = json.readString(".name");
        vaultCfg.symbol = json.readString(".symbol");

        // Parse DelegatorConfig
        vaultCfg.delegatorConfig = DelegatorConfig({
            delegatorIndex: uint16(
                json.readUint(".delegatorConfig.delegatorIndex")
            ),
            operator: json.readAddress(".delegatorConfig.operator"),
            resolverEpochsDelay: uint32(
                json.readUint(".delegatorConfig.resolverEpochsDelay")
            )
        });

        // Parse SlasherConfig
        vaultCfg.slasherConfig = SlasherConfig({
            slasherIndex: uint64(json.readUint(".slasherConfig.slasherIndex")),
            vetoDuration: uint48(json.readUint(".slasherConfig.vetoDuration")),
            includeSlasher: json.readBool(".slasherConfig.includeSlasher")
        });

        // Parse FactoryConfig
        vaultCfg.factoryConfig = FactoryConfig({
            vaultFactory: json.readAddress(".factoryConfig.vaultFactory"),
            delegatorFactory: json.readAddress(
                ".factoryConfig.delegatorFactory"
            ),
            slasherFactory: json.readAddress(".factoryConfig.slasherFactory"),
            l1Registry: json.readAddress(".factoryConfig.l1Registry"),
            operatorRegistry: json.readAddress(
                ".factoryConfig.operatorRegistry"
            ),
            operatorVaultOptInService: json.readAddress(
                ".factoryConfig.operatorVaultOptInService"
            ),
            operatorL1OptInService: json.readAddress(
                ".factoryConfig.operatorL1OptInService"
            )
        });

        // Parse RolesConfig
        vaultCfg.rolesConfig = RolesConfig({
            depositWhitelistSetRoleHolder: json.readAddress(
                ".rolesConfig.depositWhitelistSetRoleHolder"
            ),
            depositLimitSetRoleHolder: json.readAddress(
                ".rolesConfig.depositLimitSetRoleHolder"
            ),
            depositorWhitelistRoleHolder: json.readAddress(
                ".rolesConfig.depositorWhitelistRoleHolder"
            ),
            isDepositLimitSetRoleHolder: json.readAddress(
                ".rolesConfig.isDepositLimitSetRoleHolder"
            ),
            l1LimitSetRoleHolders: json.readAddress(
                ".rolesConfig.l1LimitSetRoleHolders"
            ),
            operatorL1SharesSetRoleHolders: json.readAddress(
                ".rolesConfig.operatorL1SharesSetRoleHolders"
            )
        });

        // Deploy Core contract
        VaultFull vaultFull = new VaultFull();

        // Execute deployment with parsed config
        (address vaultTokenized, address delegator, address slasher) = vaultFull
            .executeCoreDeployment(vaultCfg);

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

        // Start serializing
        string memory vaultKey = "vaultContracts";
        string memory data = vm.serializeAddress(
            vaultKey,
            "Owner",
            vaultCfg.owner
        );
        data = vm.serializeAddress(vaultKey, "Vault", vaultTokenized);
        data = vm.serializeAddress(vaultKey, "Delegator", delegator);

        if (slasher != address(0)) {
            data = vm.serializeAddress(vaultKey, "Slasher", slasher);
        }

        data = vm.serializeAddress(
            vaultKey,
            "CollateralAsset",
            vaultCfg.collateralAsset
        );
        data = vm.serializeAddress(
            vaultKey,
            "VaultFactory",
            vaultCfg.factoryConfig.vaultFactory
        );
        data = vm.serializeAddress(
            vaultKey,
            "DelegatorFactory",
            vaultCfg.factoryConfig.delegatorFactory
        );
        data = vm.serializeAddress(
            vaultKey,
            "SlasherFactory",
            vaultCfg.factoryConfig.slasherFactory
        );
        data = vm.serializeAddress(
            vaultKey,
            "L1Registry",
            vaultCfg.factoryConfig.l1Registry
        );
        data = vm.serializeAddress(
            vaultKey,
            "OperatorRegistry",
            vaultCfg.factoryConfig.operatorRegistry
        );
        data = vm.serializeAddress(
            vaultKey,
            "OperatorVaultOptInService",
            vaultCfg.factoryConfig.operatorVaultOptInService
        );
        data = vm.serializeAddress(
            vaultKey,
            "OperatorL1OptInService",
            vaultCfg.factoryConfig.operatorL1OptInService
        );

        // Write to JSON file
        string memory outFile = string.concat(path, "/vaultContracts.json");
        vm.writeJson(data, outFile);

        console2.log(
            "DeployCore script finished. Deployment data written to",
            outFile
        );
    }
}
