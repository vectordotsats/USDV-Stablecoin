// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Stablecoin} from "./Stablecoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract StablecoinEngine is ReentrancyGuard {
    ///////////////////
    /// VARIABLES ////
    /////////////////
    mapping(address token => address priceFeed)
        private s_tokenToPriceFeedAddress;
    Stablecoin private immutable i_stable;
    address[] private s_collateralTokens;

    ////////////////
    /// ERRORS ////
    //////////////
    error Engine__TokenAndPriceFeedLengthMustBeEqual();
    error Engine__AmountCantBeLessThanZero();
    error Engine__TokenNotAllowed();

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

    ///////////////////
    /// FUNCTIONS ////
    /////////////////
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
}
