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

import "src/staking/interfaces/IRewarder.sol";

contract MockRewarder is IRewarder {
  function name() external view returns (string memory) {}

  function rewardRate() external view returns (uint256) {}

  function onDeposit(address user, uint256 shareAmount) external {}

  function onWithdraw(address user, uint256 shareAmount) external {}

  function onHarvest(address user, address receiver) external {}

  function pendingReward(address) external pure returns (uint256) {
    return 0;
  }
}
