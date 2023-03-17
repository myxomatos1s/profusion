// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IExternalOracle {
  /// @dev Returns the price in terms of ETH for the given token, multiplifed by 2**112.
  function getETHPx(address token) external view returns (uint);
}
