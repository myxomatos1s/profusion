// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import 'openzeppelin-contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';
import 'openzeppelin-contracts/token/ERC20/extensions/draft-ERC20Permit.sol';

contract ProfusionToken is ERC20PresetMinterPauser('Profusion Token', 'PFX'), ERC20Permit('PFX') {
  function _beforeTokenTransfer(
    address from,
    address to,
    uint amount
  ) internal virtual override(ERC20, ERC20PresetMinterPauser) {
    ERC20PresetMinterPauser._beforeTokenTransfer(from, to, amount);
  }
}
