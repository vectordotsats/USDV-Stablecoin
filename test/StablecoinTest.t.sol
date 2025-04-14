// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Stablecoin} from "../src/Stablecoin.sol";
import {DeployStablecoin} from "../script/DeployStablecoin.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {StablecoinEngine} from "../src/StablecoinEngine.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StablecoinTest is Test {
    Stablecoin stablecoin;
    DeployStablecoin deployStablecoin;
    HelperConfig config;
    StablecoinEngine engine;
    address ethUsdPriceFeed;
    address weth;
    address USER = makeAddr("user");

    //////////////////
    /// CONSTANTS ///
    ////////////////
    error Engine__TokenNotAllowed();
    error Engine__AmountCantBeLessThanZero();

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

    function testGetUsdValue() public view {
        uint256 ethAmount = 5e18; // 5ETH
        // 5 * 2000 = 10000 USD
        uint256 expectedValue = 10000e18; // 10000 USD

        uint256 actualValue = engine.getTokenInUsd(weth, ethAmount);
        assertEq(expectedValue, actualValue);
    }

    function testCollateralDeposit() public {
        uint256 depositAmount = 1e18; // 1 ETH

        // Minting weth to the dummy address.
        deal(weth, USER, depositAmount);

        // Approving the StablecoinEngine to spend weth
        vm.startPrank(USER);
        IERC20(weth).approve(address(engine), depositAmount);

        // Depositing Collateral
        engine.depositCollateral(weth, depositAmount);

        // Checking the balance of the user
        uint256 userBalance = engine.getCollateralBalance(USER, weth);
        assertEq(userBalance, depositAmount);

        // Checking the balance of the engine contract
        uint256 engineBalance = IERC20(weth).balanceOf(address(engine));
        assertEq(engineBalance, depositAmount);
        vm.stopPrank();
    }

    function testMintedTokens() public {
        uint256 mintedAmount = 1e18; // 1 ETH
        uint256 depositAmount = 1e18; // 1 ETH

        deal(weth, USER, depositAmount);

        // Minting weth to the dummy address.
        vm.startPrank(USER);

        //aproving the spending of weth in the engine contract.
        IERC20(weth).approve(address(engine), depositAmount);

        // Ensuring the collateral is deposited.
        engine.depositCollateral(weth, depositAmount);

        engine.mintStables(mintedAmount); //

        uint256 userBalance = stablecoin.balanceOf(USER);
        uint256 userEngineStableBalance = engine.getMintedStables(USER);

        assertEq(userBalance, mintedAmount);
        assertEq(userEngineStableBalance, mintedAmount);
        vm.stopPrank();
    }

    function testIsTokenAllowedModifier() public {
        uint256 depositAmount = 1e18; // 1 ETH

        deal(weth, USER, depositAmount);

        // Minting and invalid address and expecting it to revert.
        vm.startPrank(USER);
        IERC20(weth).approve(address(engine), depositAmount);
        vm.expectRevert(Engine__TokenNotAllowed.selector);
        engine.depositCollateral(address(0), depositAmount);
        vm.stopPrank();
    }

    function testGreaterThanZeroModifier() public {
        uint256 depositAmount = 0; // 0 ETH
        deal(weth, USER, depositAmount);

        // Gonna be sending 0 ETH and expecting it to revert.
        vm.startPrank(USER);
        IERC20(weth).approve(address(engine), depositAmount);

        vm.expectRevert(Engine__AmountCantBeLessThanZero.selector);
        engine.mintStables(depositAmount);
        vm.stopPrank();
    }

    function testBurnWorks() public {
        uint256 burnAmount = 1e18; // 1 ETH
        uint256 mintedAmount = 2e18; // 2 ETH

        vm.startPrank(address(engine));
        stablecoin.mint(address(engine), mintedAmount);

        stablecoin.burn(burnAmount);

        uint256 userBalance = stablecoin.balanceOf(address(engine));
        assertEq(userBalance, mintedAmount - burnAmount);
        vm.stopPrank();
    }

    function testBurnFails() public {
        uint256 burnAmount = 2e18;
        uint256 mintedAmount = 1e18;

        vm.startPrank(address(engine));
        stablecoin.mint(address(engine), mintedAmount);

        vm.expectRevert(
            Stablecoin.Stablecoin_BalanceMustBeGreaterThanBurnAmount.selector
        );
        stablecoin.burn(burnAmount);
        vm.stopPrank();
    }
}
