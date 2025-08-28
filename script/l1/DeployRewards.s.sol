// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {stdJson} from "forge-std/StdJson.sol";
import {Script, console2} from "forge-std/Script.sol";

import {RewardsConfig} from "@suzaku/core/script/rewards/RewardsTypes.s.sol";
import {DeployRewards} from "@suzaku/core/script/rewards/RewardsDeployment.s.sol";

import {DateTimeLib} from "../libraries/DateTimeLib.sol";

contract DeployRewardsL1 is Script {
    using stdJson for string;

    function readInput(
        string memory input
    ) internal view returns (string memory) {
        string memory path = string.concat(vm.projectRoot(), "/", input);
        return vm.readFile(path);
    }

    function run(string memory input) external {
        string memory json = readInput(input);

        // Parse fields into RewardsConfig
        RewardsConfig memory rewardsConfig;
        rewardsConfig.admin = json.readAddress(".roles.rewardsAdmin_rewards");
        rewardsConfig.protocolOwner = json.readAddress(
            ".roles.protocolOwner_rewards"
        );
        rewardsConfig.middleware = json.readAddress(".deployed.middleware");
        rewardsConfig.protocolFee = uint16(
            json.readUint(".rewards.protocolFee")
        );
        rewardsConfig.operatorFee = uint16(
            json.readUint(".rewards.operatorFee")
        );
        rewardsConfig.curatorFee = uint16(json.readUint(".rewards.curatorFee"));
        rewardsConfig.minRequiredUptime = json.readUint(
            ".rewards.minRequiredUptime"
        );

        // Deploy
        DeployRewards deploy = new DeployRewards();
        (address rewards, address uptimeTracker) = deploy
            .executeRewardsDeployment(rewardsConfig);

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

        string memory label = "Rewards";
        string memory data = vm.serializeAddress(
            label,
            "admin",
            rewardsConfig.admin
        );

        data = vm.serializeAddress(
            label,
            "protocolOwner",
            rewardsConfig.protocolOwner
        );
        data = vm.serializeAddress(
            label,
            "middleware",
            rewardsConfig.middleware
        );
        data = vm.serializeUint(
            label,
            "protocolFee",
            rewardsConfig.protocolFee
        );
        data = vm.serializeUint(
            label,
            "operatorFee",
            rewardsConfig.operatorFee
        );
        data = vm.serializeUint(label, "curatorFee", rewardsConfig.curatorFee);
        data = vm.serializeUint(
            label,
            "minRequiredUptime",
            rewardsConfig.minRequiredUptime
        );

        // newly deployed
        data = vm.serializeAddress(label, "rewards", rewards);
        data = vm.serializeAddress(label, "uptimeTracker", uptimeTracker);

        string memory outFile = string.concat(path, "/rewards.json");
        vm.writeJson(data, outFile);
        console2.log("Deployed Rewards to:", rewards);
        console2.log("Deployed UptimeTracker to:", uptimeTracker);
        console2.log("Output JSON =>", outFile);
    }
}
