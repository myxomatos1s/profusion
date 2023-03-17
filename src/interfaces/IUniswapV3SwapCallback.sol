// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IUniswapV3SwapCallback {
  function uniswapV3SwapCallback(
    int amount0Delta,
    int amount1Delta,
    bytes calldata data
  ) external;
}
