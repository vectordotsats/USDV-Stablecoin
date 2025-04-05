// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Stablecoin is Ownable, ERC20Burnable {
    /////////////////////
    ///// ERRORS ///////
    ///////////////////
    error Stablecoin_BalanceIsTooLowToBurn();
    error Stablecoin_BalanceMustBeGreaterThanBurnAmount();
    error Stablecoin_CantMintToZeroAddress();
    error Stablecoin_CantMintBelowZero();

    constructor() ERC20("Vector stablecoin", "vUSD") Ownable(msg.sender) {}

    function burn(uint _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (balance <= 0) {
            revert Stablecoin_BalanceIsTooLowToBurn();
        }

        if (balance <= _amount) {
            revert Stablecoin_BalanceMustBeGreaterThanBurnAmount();
        }
        super.burn(_amount);
    }

    function mint(
        address _to,
        uint256 _amount
    ) public onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert Stablecoin_CantMintToZeroAddress();
        }
        if (_amount <= 0) {
            revert Stablecoin_CantMintBelowZero();
        }

        _mint(_to, _amount);
        return true;
    }
}
