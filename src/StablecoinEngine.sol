// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Stablecoin} from "./Stablecoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract StablecoinEngine is ReentrancyGuard {
    ///////////////////
    /// VARIABLES ////
    /////////////////
    mapping(address token => address priceFeed)
        private s_tokenToPriceFeedAddress;
    Stablecoin private immutable i_stable;
    address[] private s_collateralTokens;
    mapping(address user => mapping(address token => uint256 amount))
        private s_userToTokenCollateralAmount;
    mapping(address user => uint256 amount) private s_userToMintedStables;

    ///////////////////
    /// CONSTANTS ////
    /////////////////
    uint256 private constant ADDITIONAL_FEES = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_APPROXIMATOR = 100;
    uint256 private constant MINIMUM_HEALTHFACTOR = 1;

    ////////////////
    /// EVENTS ////
    //////////////
    event DepositedCollateral(
        address indexed user,
        address indexed tokenCollateeralAddress,
        uint256 indexed collateralAmount
    );

    event MintedStables(address indexed user, uint256 indexed mintedAmount);

    ////////////////
    /// ERRORS ////
    //////////////
    error Engine__TokenAndPriceFeedLengthMustBeEqual();
    error Engine__AmountCantBeLessThanZero();
    error Engine__TokenNotAllowed();
    error Engine__CollateralDepositFailed();
    error Engine__StablecoinMintFailed();
    error Engine__HealthFactorIsTooLow(address user);

    ////////////////////
    //// Modifiers ////
    //////////////////
    modifier isBelowZero(uint256 _amount) {
        if (_amount <= 0) {
            revert Engine__AmountCantBeLessThanZero();
        }
        _;
    }

    modifier isTokenAllowed(address _token) {
        if (s_tokenToPriceFeedAddress[_token] == address(0)) {
            revert Engine__TokenNotAllowed();
        }
        _;
    }

    ///////////////////////////////
    /// CONSTRUCTOR FUNCTIONS ////
    /////////////////////////////
    constructor(
        address[] memory tokenAddresses,
        address[] memory priceFeedAddresses,
        address stablecoinAddress
    ) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert Engine__TokenAndPriceFeedLengthMustBeEqual();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_tokenToPriceFeedAddress[tokenAddresses[i]] = priceFeedAddresses[
                i
            ];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_stable = Stablecoin(stablecoinAddress);
    }

    ///////////////////////////////
    /// CORE FUNCTIONS ///////////
    /////////////////////////////

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 collateralAmount
    ) external isTokenAllowed(tokenCollateralAddress) nonReentrant {
        s_userToTokenCollateralAmount[msg.sender][
            tokenCollateralAddress
        ] += collateralAmount;
        emit DepositedCollateral(
            msg.sender,
            tokenCollateralAddress,
            collateralAmount
        );

        // Transfer the collateral from the user to the contract
        bool success = IERC20(tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            collateralAmount
        );
        if (!success) {
            revert Engine__CollateralDepositFailed();
        }
    }

    function mintStables(
        uint256 collateralAmount
    ) external isBelowZero(collateralAmount) nonReentrant {
        s_userToMintedStables[msg.sender] += collateralAmount;
        emit MintedStables(msg.sender, collateralAmount);

        // Transfer the stablecoin from the contract to the user
        bool success = i_stable.mint(msg.sender, collateralAmount);
        if (!success) {
            revert Engine__StablecoinMintFailed();
        }
    }

    ///////////////////////////////
    /// SPECIAL FUNCTIONS ///////////
    /////////////////////////////
    function getAccountInformation(
        address user
    )
        private
        view
        returns (uint256 mintedStables, uint256 collateralDeposited)
    {
        mintedStables = s_userToMintedStables[user];
        collateralDeposited = getCollateralInUSD(user);
    }

    function getCollateralInUSD(
        address user
    ) public view returns (uint256 totalCollateralInUsd) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_userToTokenCollateralAmount[user][token];
            totalCollateralInUsd += getTokenInUsd(token, amount);
        }

        return totalCollateralInUsd;
    }

    function getTokenInUsd(
        address _token,
        uint256 _amount
    ) public view returns (uint256 tokenInUsd) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_tokenToPriceFeedAddress[_token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return ((uint256(price) * ADDITIONAL_FEES * _amount) / PRECISION);
    }

    function _healthFactor(address user) private view returns (uint256 hf) {
        (
            uint256 mintedStables,
            uint256 collateralDeposited
        ) = getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralDeposited *
            LIQUIDATION_THRESHOLD) / LIQUIDATION_APPROXIMATOR;
        return ((collateralAdjustedForThreshold * PRECISION) / mintedStables);
    }

    function revertIfHealthFactorIsTooLow(address user) internal view {
        uint256 healthFactor = _healthFactor(user);
        if (healthFactor < MINIMUM_HEALTHFACTOR) {
            revert Engine__HealthFactorIsTooLow(user);
        }
    }

    function getCollateralBalance(
        address user,
        address tokenAddress
    ) external view returns (uint256) {
        uint256 collateralAmount = s_userToTokenCollateralAmount[user][
            tokenAddress
        ];

        return collateralAmount;
    }

    function getMintedStables(address user) external view returns (uint256) {
        uint256 mintedStables = s_userToMintedStables[user];

        return mintedStables;
    }
}
