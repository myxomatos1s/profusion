// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import 'openzeppelin-contracts/access/Ownable.sol';
import 'openzeppelin-contracts/token/ERC20/IERC20.sol';
import 'openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol';
import 'openzeppelin-contracts/utils/math/Math.sol';

import './interfaces/IProfusionBank.sol';
import './interfaces/IWETH.sol';

contract ProfusionRunnerBase is Ownable {
  using SafeERC20 for IERC20;

  address public immutable profusionBank;
  address public immutable weth;

  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'ProfusionRunnerBase/not-eoa');
    _;
  }

  constructor(address _profusionBank, address _weth) {
    address bweth = IProfusionBank(_profusionBank).pfTokens(_weth);
    require(bweth != address(0), 'ProfusionRunnerBase/no-bweth');
    IERC20(_weth).safeApprove(_profusionBank, type(uint).max);
    IERC20(_weth).safeApprove(bweth, type(uint).max);
    profusionBank = _profusionBank;
    weth = _weth;
  }

  function _borrow(
    address _owner,
    uint _pid,
    address _underlying,
    address _collateral,
    uint _amountBorrow,
    uint _amountCollateral
  ) internal {
    if (_pid == type(uint).max) {
      _pid = IProfusionBank(profusionBank).open(_owner, _underlying, _collateral);
    } else {
      (address collateral, address bToken) = IProfusionBank(profusionBank).getPositionTokens(_owner, _pid);
      require(_collateral == collateral, '_borrow/collateral-not-_collateral');
      require(_underlying == IProfusionBank(profusionBank).underlyings(bToken), '_borrow/bad-underlying');
    }
    _approve(_collateral, profusionBank, _amountCollateral);
    IProfusionBank(profusionBank).put(_owner, _pid, _amountCollateral);
    IProfusionBank(profusionBank).borrow(_owner, _pid, _amountBorrow);
  }

  function _repay(
    address _owner,
    uint _pid,
    address _underlying,
    address _collateral,
    uint _amountRepay,
    uint _amountCollateral
  ) internal {
    (address collateral, address bToken) = IProfusionBank(profusionBank).getPositionTokens(_owner, _pid);
    require(_collateral == collateral, '_repay/collateral-not-_collateral');
    require(_underlying == IProfusionBank(profusionBank).underlyings(bToken), '_repay/bad-underlying');
    _approve(_underlying, bToken, _amountRepay);
    IProfusionBank(profusionBank).repay(_owner, _pid, _amountRepay);
    IProfusionBank(profusionBank).take(_owner, _pid, _amountCollateral);
  }

  function _transferIn(
    address _token,
    address _from,
    uint _amount
  ) internal {
    if (_token == weth) {
      require(_from == msg.sender, '_transferIn/not-from-sender');
      require(_amount <= msg.value, '_transferIn/insufficient-eth-amount');
      IWETH(weth).deposit{value: _amount}();
      if (msg.value > _amount) {
        (bool success, ) = _from.call{value: msg.value - _amount}(new bytes(0));
        require(success, '_transferIn/eth-transfer-failed');
      }
    } else {
      IERC20(_token).safeTransferFrom(_from, address(this), _amount);
    }
  }

  function _transferOut(
    address _token,
    address _to,
    uint _amount
  ) internal {
    if (_token == weth) {
      IWETH(weth).withdraw(_amount);
      (bool success, ) = _to.call{value: _amount}(new bytes(0));
      require(success, '_transferOut/eth-transfer-failed');
    } else {
      IERC20(_token).safeTransfer(_to, _amount);
    }
  }

  /// @dev Approves infinite on the given token for the given spender if current approval is insufficient.
  function _approve(
    address _token,
    address _spender,
    uint _minAmount
  ) internal {
    uint current = IERC20(_token).allowance(address(this), _spender);
    if (current < _minAmount) {
      if (current != 0) {
        IERC20(_token).safeApprove(_spender, 0);
      }
      IERC20(_token).safeApprove(_spender, type(uint).max);
    }
  }

  /// @dev Caps repay amount by current position's debt.
  function _capRepay(
    address _owner,
    uint _pid,
    uint _amountRepay
  ) internal returns (uint) {
    return Math.min(_amountRepay, IProfusionBank(profusionBank).fetchPositionDebt(_owner, _pid));
  }

  /// @dev Recovers lost tokens for whatever reason by the owner.
  function recover(address _token, uint _amount) external onlyOwner {
    if (_amount == type(uint).max) {
      _amount = IERC20(_token).balanceOf(address(this));
    }
    IERC20(_token).safeTransfer(msg.sender, _amount);
  }

  /// @dev Recovers lost ETH for whatever reason by the owner.
  function recoverETH(uint _amount) external onlyOwner {
    if (_amount == type(uint).max) {
      _amount = address(this).balance;
    }
    (bool success, ) = msg.sender.call{value: _amount}(new bytes(0));
    require(success, 'recoverETH/eth-transfer-failed');
  }

  receive() external payable {
    require(msg.sender == weth, 'receive/not-weth');
  }
}
