// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IProfusionInterestModel {
  /// @dev Returns the initial interest rate per year (times 1e18).
  function initialRate() external view returns (uint);

  /// @dev Returns the next interest rate for the market.
  /// @param prevRate The current interest rate.
  /// @param totalAvailable The current available liquidity.
  /// @param totalLoan The current outstanding loan.
  /// @param timePast The time past since last interest rate rebase in seconds.
  function getNextInterestRate(
    uint prevRate,
    uint totalAvailable,
    uint totalLoan,
    uint timePast
  ) external view returns (uint);
}
