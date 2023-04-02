// SPDX-License-Identifier: MIT
/**
 * ∩~~~~∩ 
 *   ξ ･×･ ξ 
 *   ξ　~　ξ 
 *   ξ　　 ξ 
 *   ξ　　 “~～~～〇 
 *   ξ　　　　　　 ξ 
 *   ξ ξ ξ~～~ξ ξ ξ 
 * 　 ξ_ξξ_ξ　ξ_ξξ_ξ
 * Alpaca Fin Corporation
 */

pragma solidity 0.8.17;

/// @title Alperp's Alpaca Point interface
interface IAP {
  function mint(address _to, uint256 _amount) external;

  function feed(uint256 _weekTimestamp, address _rewardToken, uint256 _amount)
    external;

  function bulkFeed(
    uint256[] memory _weekTimestamps,
    address[] memory _rewardTokens,
    uint256[] memory _amounts
  ) external;

  function claim(uint256 _weekTimestamp, address _rewardToken, address _to)
    external;

  function bulkClaim(
    uint256[] memory _weekTimestamps,
    address[] memory _rewardTokens,
    address[] memory _tos
  ) external;
}
