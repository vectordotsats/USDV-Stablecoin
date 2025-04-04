// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Stablecoin} from "../src/Stablecoin.sol";
import {Script, console} from "forge-std/Script.sol";

contract DeployStablecoin is Script {
    function run() external {
        vm.startBroadcast();
        Stablecoin stablecoin = new Stablecoin();
        console.log("Stablecoin deployed to: ", address(stablecoin));
        vm.stopBroadcast();
    }
}