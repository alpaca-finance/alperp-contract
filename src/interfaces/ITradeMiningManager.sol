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

import {IAP} from "@alperp/interfaces/IAP.sol";

interface ITradeMiningManager {
  function setAuth(address _user, bool _allow) external;

  function setAp(IAP _alpacaPoint) external;

  function onIncreasePosition(
    address _primaryAccount,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong
  ) external;

  function onDecreasePosition(
    address _primaryAccount,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong
  ) external;

  function onLiquidatePosition(
    address _primaryAccount,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _size,
    bool _isLong
  ) external;

  function onSwap(
    address _account,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _amountOut
  ) external;

  function onAddLiquidity(
    address _account,
    address _tokenIn,
    uint256 _amountIn,
    uint256 _liquidityAmount, // ALP amount
    address _receiver
  ) external;

  function onRemoveLiquidity(
    address _account,
    address _tokenOut,
    uint256 _liquidityAmount, // ALP amount
    uint256 _receiverAmount,
    address _receiver
  ) external;
}
