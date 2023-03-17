// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import 'openzeppelin-contracts/access/Ownable.sol';
import 'openzeppelin-contracts/token/ERC20/ERC20.sol';

contract ERC20Contract is ERC20, Ownable {
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

  function mint(address account, uint amount) external onlyOwner {
    _mint(account, amount);
  }

  function burn(address account, uint amount) external onlyOwner {
    _burn(account, amount);
  }
}
