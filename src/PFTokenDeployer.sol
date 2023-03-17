// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import './PFToken.sol';

contract PFTokenDeployer {
  /// @dev Deploys a new BToken contract for the given underlying token.
  function deploy(address _underlying) external returns (address) {
    bytes32 salt = keccak256(abi.encode(msg.sender, _underlying));
    return address(new PFToken{salt: salt}(msg.sender, _underlying));
  }

  /// @dev Returns the deterministic BToken address for the given BetaBank + underlying.
  function bTokenFor(address _betaBank, address _underlying) external view returns (address) {
    bytes memory args = abi.encode(_betaBank, _underlying);
    bytes32 code = keccak256(abi.encodePacked(type(PFToken).creationCode, args));
    bytes32 salt = keccak256(args);
    return address(uint160(uint(keccak256(abi.encodePacked(hex'ff', address(this), salt, code)))));
  }
}
