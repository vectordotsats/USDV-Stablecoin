// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Stablecoin is Ownable, ERC20Burnable{
    constructor() ERC20("Vector stablecoin", "UsdV") Ownable(msg.sender){}
}