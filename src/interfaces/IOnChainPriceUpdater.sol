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

interface IOnchainPriceUpdater {
  function setCachedPrices(
    bytes[] calldata _priceUpdateData,
    address[] calldata _tokens,
    uint256[] calldata _prices
  ) external;

  function updatePrices(bytes[] calldata _priceUpdateData) external payable;

  function getUpdateFee(bytes[] calldata _priceUpdateData)
    external
    view
    returns (uint256);
}
