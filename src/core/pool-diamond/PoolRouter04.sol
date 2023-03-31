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

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import { IWNative } from "../../interfaces/IWNative.sol";
import { LiquidityFacetInterface } from "./interfaces/LiquidityFacetInterface.sol";
import { GetterFacetInterface } from "./interfaces/GetterFacetInterface.sol";
import { PerpTradeFacetInterface } from "./interfaces/PerpTradeFacetInterface.sol";
import { IOnchainPriceUpdater } from "../../interfaces/IOnChainPriceUpdater.sol";
import { PoolOracle } from "../PoolOracle.sol";
import { IMiner } from "../../interfaces/IMiner.sol";

/// @title PoolRouter04 is responsible for swapping tokens and managing liquidity
/// @notice  This Router will apply pyth oracle mechanism
contract PoolRouter04 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  IWNative public WNATIVE;
  address public pool;
  IOnchainPriceUpdater public oraclePriceUpdater;

  IMiner miner;

  event SetMiner(address _miner);

  error PoolRouter_InsufficientOutputAmount(
    uint256 expectedAmount,
    uint256 actualAmount
  );
  error PoolRouter_MarkPriceTooHigh(
    uint256 acceptablePrice,
    uint256 actualPrice
  );
  error PoolRouter_MarkPriceTooLow(
    uint256 acceptablePrice,
    uint256 actualPrice
  );
  error PoolRouter_InsufficientUpdatedFee(
    uint256 expectedFee,
    uint256 msgValue
  );

  function initialize(
    address wNative_,
    address pool_,
    address oraclePriceUpdater_
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    WNATIVE = IWNative(wNative_);
    pool = pool_;
    oraclePriceUpdater = IOnchainPriceUpdater(oraclePriceUpdater_);
  }

  function _updatePrices(bytes[] memory _priceUpdateData)
    internal
    returns (uint256)
  {
    uint256 fee = oraclePriceUpdater.getUpdateFee(_priceUpdateData);
    if (fee == 0) return 0;
    if (fee > msg.value)
      revert PoolRouter_InsufficientUpdatedFee(fee, msg.value);
    oraclePriceUpdater.updatePrices{ value: fee }(_priceUpdateData);
    return fee;
  }

  function _validatePrice(
    address indexToken,
    bool isLong,
    bool isIncreasePosiiton,
    uint256 acceptablePrice
  ) internal view {
    PoolOracle oracle = PoolOracle(GetterFacetInterface(pool).oracle());
    if (isIncreasePosiiton) {
      if (isLong) {
        uint256 actualPrice = oracle.getMaxPrice(indexToken);
        if (!(actualPrice <= acceptablePrice))
          revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
      } else {
        uint256 actualPrice = oracle.getMinPrice(indexToken);
        if (!(actualPrice >= acceptablePrice))
          revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
      }
      return;
    }

    if (isLong) {
      uint256 actualPrice = oracle.getMinPrice(indexToken);
      if (!(actualPrice >= acceptablePrice))
        revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
    } else {
      uint256 actualPrice = oracle.getMaxPrice(indexToken);
      if (!(actualPrice <= acceptablePrice))
        revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
    }
  }

  function setMiner(address _miner) external onlyOwner {
    miner = IMiner(_miner);

    emit SetMiner(_miner);
  }

  function addLiquidity(
    address token,
    uint256 amount,
    address receiver,
    uint256 minLiquidity,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    _updatePrices(_priceUpdateData);
    IERC20Upgradeable(token).safeTransferFrom(
      msg.sender,
      address(pool),
      amount
    );

    uint256 receivedAmount = LiquidityFacetInterface(pool).addLiquidity(
      msg.sender,
      token,
      receiver
    );

    if (receivedAmount < minLiquidity)
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);

    return receivedAmount;
  }

  function addLiquidityNative(
    address token,
    address receiver,
    uint256 minLiquidity,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    uint256 fee = _updatePrices(_priceUpdateData);
    uint256 actualMsgValue = msg.value - fee;
    WNATIVE.deposit{ value: actualMsgValue }();
    IERC20Upgradeable(address(WNATIVE)).safeTransfer(
      address(pool),
      actualMsgValue
    );

    uint256 receivedAmount = LiquidityFacetInterface(pool).addLiquidity(
      msg.sender,
      token,
      receiver
    );

    if (receivedAmount < minLiquidity)
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);

    return receivedAmount;
  }

  function removeLiquidity(
    address tokenOut,
    uint256 liquidity,
    address receiver,
    uint256 minAmountOut,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    _updatePrices(_priceUpdateData);
    IERC20Upgradeable(address(GetterFacetInterface(pool).alp()))
      .safeTransferFrom(msg.sender, address(pool), liquidity);

    uint256 receivedAmount = LiquidityFacetInterface(pool).removeLiquidity(
      msg.sender,
      tokenOut,
      receiver
    );

    if (receivedAmount < minAmountOut)
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);

    return receivedAmount;
  }

  function removeLiquidityNative(
    address tokenOut,
    uint256 liquidity,
    address receiver,
    uint256 minAmountOut,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    _updatePrices(_priceUpdateData);
    IERC20Upgradeable(address(GetterFacetInterface(pool).alp()))
      .safeTransferFrom(msg.sender, address(pool), liquidity);

    uint256 receivedAmount = LiquidityFacetInterface(pool).removeLiquidity(
      msg.sender,
      tokenOut,
      address(this)
    );

    if (receivedAmount < minAmountOut)
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);

    WNATIVE.withdraw(receivedAmount);
    payable(receiver).transfer(receivedAmount);

    return receivedAmount;
  }

  function increasePosition(
    uint256 subAccountId,
    address tokenIn,
    address collateralToken,
    uint256 amountIn,
    uint256 minAmountOut,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 acceptablePrice,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant {
    _updatePrices(_priceUpdateData);
    _validatePrice(indexToken, isLong, true, acceptablePrice);

    if (tokenIn != collateralToken) {
      uint256 amountOutFromSwap = _swap(
        msg.sender,
        tokenIn,
        collateralToken,
        amountIn,
        minAmountOut,
        address(this)
      );
      IERC20Upgradeable(collateralToken).safeTransfer(pool, amountOutFromSwap);
    } else {
      IERC20Upgradeable(collateralToken).safeTransferFrom(
        msg.sender,
        pool,
        amountIn
      );
    }
    PerpTradeFacetInterface(pool).increasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      sizeDelta,
      isLong
    );

    // miner
    miner.increasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      sizeDelta,
      0, // no use as of now, then fixed 0 for reducing gas used
      isLong
    );
  }

  function increasePositionNative(
    uint256 subAccountId,
    address tokenIn,
    address collateralToken,
    uint256 minAmountOut,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 acceptablePrice,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant {
    uint256 fee = _updatePrices(_priceUpdateData);
    uint256 actualMsgValue = msg.value - fee;
    _validatePrice(indexToken, isLong, true, acceptablePrice);

    if (tokenIn != collateralToken && tokenIn == address(WNATIVE)) {
      WNATIVE.deposit{ value: actualMsgValue }();
      uint256 amountOut = _swap(
        address(this),
        tokenIn,
        collateralToken,
        actualMsgValue,
        minAmountOut,
        address(this)
      );
      IERC20Upgradeable(collateralToken).safeTransfer(pool, amountOut);
    } else {
      WNATIVE.deposit{ value: actualMsgValue }();
      IERC20Upgradeable(address(WNATIVE)).safeTransfer(pool, actualMsgValue);
    }
    PerpTradeFacetInterface(pool).increasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      sizeDelta,
      isLong
    );

    // miner
    miner.increasePosition(
      msg.sender,
      subAccountId,
      collateralToken,
      indexToken,
      sizeDelta,
      actualMsgValue,
      isLong
    );
  }

  function decreasePosition(
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    address receiver,
    uint256 acceptablePrice,
    address tokenOut,
    uint256 minAmountOut,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant {
    _updatePrices(_priceUpdateData);
    _validatePrice(indexToken, isLong, false, acceptablePrice);

    uint256 amountOutFromPosition = PerpTradeFacetInterface(pool)
      .decreasePosition(
        msg.sender,
        subAccountId,
        collateralToken,
        indexToken,
        collateralDelta,
        sizeDelta,
        isLong,
        address(this)
      );
    if (collateralToken == tokenOut) {
      if (amountOutFromPosition < minAmountOut)
        revert PoolRouter_InsufficientOutputAmount(
          minAmountOut,
          amountOutFromPosition
        );
      IERC20Upgradeable(tokenOut).safeTransfer(receiver, amountOutFromPosition);
    } else {
      _swap(
        address(this),
        collateralToken,
        tokenOut,
        amountOutFromPosition,
        minAmountOut,
        receiver
      );
    }
  }

  function decreasePositionNative(
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    address receiver,
    uint256 acceptablePrice,
    address tokenOut,
    uint256 minAmountOut,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant {
    _updatePrices(_priceUpdateData);
    _validatePrice(indexToken, isLong, false, acceptablePrice);

    uint256 amountOutFromPosition = PerpTradeFacetInterface(pool)
      .decreasePosition(
        msg.sender,
        subAccountId,
        collateralToken,
        indexToken,
        collateralDelta,
        sizeDelta,
        isLong,
        address(this)
      );
    if (collateralToken == tokenOut) {
      if (amountOutFromPosition < minAmountOut)
        revert PoolRouter_InsufficientOutputAmount(
          minAmountOut,
          amountOutFromPosition
        );
      WNATIVE.withdraw(amountOutFromPosition);
      payable(receiver).transfer(amountOutFromPosition);
    } else {
      uint256 amountOutFromSwap = _swap(
        address(this),
        collateralToken,
        tokenOut,
        amountOutFromPosition,
        minAmountOut,
        address(this)
      );
      WNATIVE.withdraw(amountOutFromSwap);
      payable(receiver).transfer(amountOutFromSwap);
    }
  }

  function swap(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    address receiver,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    _updatePrices(_priceUpdateData);
    return
      _swap(msg.sender, tokenIn, tokenOut, amountIn, minAmountOut, receiver);
  }

  function _swap(
    address sender,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    address receiver
  ) internal returns (uint256) {
    if (amountIn == 0) return 0;
    if (sender == address(this)) {
      IERC20Upgradeable(tokenIn).safeTransfer(address(pool), amountIn);
    } else {
      IERC20Upgradeable(tokenIn).safeTransferFrom(
        sender,
        address(pool),
        amountIn
      );
    }

    return
      LiquidityFacetInterface(pool).swap(
        msg.sender,
        tokenIn,
        tokenOut,
        minAmountOut,
        receiver
      );
  }

  function swapNative(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    address receiver,
    bytes[] memory _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    uint256 fee = _updatePrices(_priceUpdateData);
    uint256 actualMsgValue = msg.value - fee;
    if (tokenIn == address(WNATIVE)) {
      WNATIVE.deposit{ value: actualMsgValue }();
      IERC20Upgradeable(address(WNATIVE)).safeTransfer(pool, actualMsgValue);
      amountIn = actualMsgValue;
    } else {
      IERC20Upgradeable(tokenIn).safeTransferFrom(
        msg.sender,
        address(pool),
        amountIn
      );
    }

    if (tokenOut == address(WNATIVE)) {
      uint256 amountOut = LiquidityFacetInterface(pool).swap(
        msg.sender,
        tokenIn,
        tokenOut,
        minAmountOut,
        address(this)
      );

      WNATIVE.withdraw(amountOut);
      payable(receiver).transfer(amountOut);
      return amountOut;
    } else {
      return
        LiquidityFacetInterface(pool).swap(
          msg.sender,
          tokenIn,
          tokenOut,
          minAmountOut,
          receiver
        );
    }
  }

  receive() external payable {
    assert(msg.sender == address(WNATIVE)); // only accept NATIVE via fallback from the WNATIVE contract
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
