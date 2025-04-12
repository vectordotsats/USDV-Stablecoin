// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Stablecoin} from "../src/Stablecoin.sol";
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {StablecoinEngine} from "../src/StablecoinEngine.sol";

contract DeployStablecoin is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() public returns (Stablecoin, StablecoinEngine, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (
            address ethUsdPriceFeed,
            address btcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) = config.activeNetworkConfig();

        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [ethUsdPriceFeed, btcUsdPriceFeed];

        vm.startBroadcast(deployerKey);
        Stablecoin stablecoin = new Stablecoin();
        StablecoinEngine engine = new StablecoinEngine(
            tokenAddresses,
            priceFeedAddresses,
            address(stablecoin)
        );
        stablecoin.transferOwnership(address(engine));
        vm.stopBroadcast();

        return (stablecoin, engine, config);
    }
}
