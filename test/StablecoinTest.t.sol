// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {DeployStablecoin} from "../script/DeployStablecoin.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {StablecoinEngine} from "../src/StablecoinEngine.sol";

contract StablecoinTest is Test {
    Stablecoin stablecoin;
    DeployStablecoin deployStablecoin;
    HelperConfig config;
    StablecoinEngine engine;
    address ethUsdPriceFeed;
    address weth;

    function setUp() public {
        deployStablecoin = new DeployStablecoin();
        (stablecoin, engine, config) = deployStablecoin.run();
        (ethUsdPriceFeed, , weth, , ) = config.activeNetworkConfig();
        vm.label(ethUsdPriceFeed, "ETH/USD Price Feed");
        vm.label(weth, "WETH");
    }

    /////////////////////
    //// CORE TESTS ////
    ///////////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 5e18; // 5ETH
        // 5 * 2000 = 10000 USD
        uint256 expectedValue = 10000e18; // 10000 USD

        uint256 actualValue = engine.getTokenInUsd(weth, ethAmount);
        assertEq(expectedValue, actualValue);
    }
}
