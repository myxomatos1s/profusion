// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import 'openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol';

import './PFToken.sol';
import './interfaces/IWETH.sol';

contract WETHGateway {
  using SafeERC20 for IERC20;

  address public immutable pfweth;
  address public immutable weth;

  /// @dev Initializes the PFWETH contract
  /// @param _pfweth PFWETH token address
  constructor(address _pfweth) {
    address _weth = PFToken(_pfweth).underlying();
    IERC20(_weth).safeApprove(_pfweth, type(uint).max);
    pfweth = _pfweth;
    weth = _weth;
  }

  /// @dev Wraps the given ETH to WETH and calls mint action on PFWETH for the caller.
  /// @param _to The address to receive PFToken.
  /// @return credit The BWETH amount minted to the caller.
  function mint(address _to) external payable returns (uint credit) {
    IWETH(weth).deposit{value: msg.value}();
    credit = PFToken(pfweth).mint(_to, msg.value);
  }

  /// @dev Performs burn action on PFWETH and unwraps WETH back to ETH for the caller.
  /// @param _to The address to send ETH to.
  /// @param _credit The amount of PFToken to burn.
  /// @return amount The amount of ETH to be received.
  function burn(address _to, uint _credit) public returns (uint amount) {
    IERC20(pfweth).safeTransferFrom(msg.sender, address(this), _credit);
    amount = PFToken(pfweth).burn(address(this), _credit);
    IWETH(weth).withdraw(amount);
    (bool success, ) = _to.call{value: amount}(new bytes(0));
    require(success, 'burn/eth-transfer-failed');
  }

  /// @dev Similar to burn function, but with an additional call to BToken's EIP712 permit.
  function burnWithPermit(
    address _to,
    uint _credit,
    uint _approve,
    uint _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (uint amount) {
    PFToken(pfweth).permit(msg.sender, address(this), _approve, _deadline, _v, _r, _s);
    amount = burn(_to, _credit);
  }

  receive() external payable {
    require(msg.sender == weth, '!weth');
  }
}
