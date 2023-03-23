// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.17;

interface IOnchainPriceUpdater {
  function setFastPrices(
    bytes[] memory _priceUpdateData,
    address[] memory _tokens,
    uint256[] memory _prices
  ) external;

  function updatePrices(bytes[] memory _priceUpdateData) external payable;

  function getUpdateFee(bytes[] memory _priceUpdateData)
    external
    view
    returns (uint256);
}
