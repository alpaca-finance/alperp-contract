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

interface IMiner {
  function setWhitelist(address _whitelisted, bool _allow) external;

  function setMiningPoint(address _point) external;

  function increasePosition(
    address _primaryAccount,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    uint256 _collateralDeltaUsd,
    bool _isLong
  ) external;

  function decreasePosition(
    address _primaryAccount,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    uint256 _collateralDelta,
    bool _isLong
  ) external;

  function liquidatePosition(
    address _primaryAccount,
    uint256 _subAccountId,
    address _collateralToken,
    address _indexToken,
    uint256 _size,
    uint256 _collateral,
    bool _isLong
  ) external;

  function swap(
    address _account,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _amountOut
  ) external;

  function addLiquidity(
    address _account,
    address _tokenIn,
    uint256 _amountIn,
    uint256 _liquidityAmount, // ALP amount
    address _receiver
  ) external;

  function removeLiquidity(
    address _account,
    address _tokenOut,
    uint256 _liquidityAmount, // ALP amount
    uint256 _receiverAmount,
    address _receiver
  ) external;
}
