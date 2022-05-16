// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "OpenZeppelin/openzeppelin-contracts@4.6.0/contracts/token/ERC20/ERC20.sol";

contract ERC20Token is ERC20 {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        _mint(msg.sender, 1000000 * 10e17);
    }
}
