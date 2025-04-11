// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {DeployStablecoin} from "../script/DeployStablecoin.s.sol";

contract StablecoinTest is Test {
    Stablecoin stablecoin;
    DeployStablecoin deployStablecoin;

    function setUp() public {
        vm.startBroadcast();
        stablecoin = new Stablecoin();
        vm.stopBroadcast();
    }
}
