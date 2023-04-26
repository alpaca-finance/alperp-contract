// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IOnchainPriceUpdater} from "@alperp/interfaces/IOnChainPriceUpdater.sol";

contract MockPythPriceFeed is IOnchainPriceUpdater {
  function setCachedPrices(
    bytes[] calldata _priceUpdateData,
    address[] calldata _tokens,
    uint256[] calldata _prices
  ) external {}

  function getUpdateFee(bytes[] memory /* updateData */ )
    external
    pure
    returns (uint256)
  {
    return 0;
  }

  function updatePrices(bytes[] calldata updateData) external payable {}
}
