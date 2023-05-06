// SPDX-License-Identifier: MIT
/**
 *   ∩~~~~∩
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

/// OZ
import {IERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from
  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// Alperp
import {IWNative} from "@alperp/interfaces/IWNative.sol";
import {LiquidityFacetInterface} from "@alperp/core/pool-diamond/interfaces/LiquidityFacetInterface.sol";
import {GetterFacetInterface} from "@alperp/core/pool-diamond/interfaces/GetterFacetInterface.sol";
import {PerpTradeFacetInterface} from "@alperp/core/pool-diamond/interfaces/PerpTradeFacetInterface.sol";
import {IOnchainPriceUpdater} from "@alperp/interfaces/IOnChainPriceUpdater.sol";
import {PoolOracle} from "@alperp/core/PoolOracle.sol";
import {ITradeMiningManager} from "@alperp/interfaces/ITradeMiningManager.sol";
import {IWNativeRelayer} from "@alperp/interfaces/IWNativeRelayer.sol";

/// @title  PoolRouter05 is responsible for swapping tokens and managing liquidity
/// @notice This Router will apply pyth oracle mechanism
contract PoolRouter05 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
  /// Dependencies
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// Errors
  error PoolRouter_InsufficientOutputAmount(
    uint256 expectedAmount, uint256 actualAmount
  );
  error PoolRouter_MarkPriceTooHigh(
    uint256 acceptablePrice, uint256 actualPrice
  );
  error PoolRouter_MarkPriceTooLow(uint256 acceptablePrice, uint256 actualPrice);
  error PoolRouter_InsufficientUpdatedFee(uint256 expectedFee, uint256 msgValue);

  /// Configs
  IWNative public WNATIVE;
  address public pool;
  IOnchainPriceUpdater public oraclePriceUpdater;
  ITradeMiningManager public tradeMiningManager;
  IWNativeRelayer public wNativeRelayer;

  event SetOraclePriceUpdater(
    address _prevOraclePriceUpdater, address _newOraclePriceUpdater
  );
  event SetTradeMiningManager(
    address _prevTradeMiningManager, address _newTradeMiningManager
  );
  event SetWNativeRelayer(
    address _prevWNativeRelayer, address _newWNativeRelayer
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    IWNative _wNative,
    address _pool,
    IOnchainPriceUpdater _oraclePriceUpdater,
    ITradeMiningManager _tradeMiningManager
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    WNATIVE = _wNative;
    pool = _pool;
    oraclePriceUpdater = _oraclePriceUpdater;
    tradeMiningManager = _tradeMiningManager;
  }

  function _updatePrices(bytes[] calldata _priceUpdateData)
    internal
    returns (uint256)
  {
    uint256 fee = oraclePriceUpdater.getUpdateFee(_priceUpdateData);
    if (fee > msg.value) {
      revert PoolRouter_InsufficientUpdatedFee(fee, msg.value);
    }
    oraclePriceUpdater.updatePrices{value: fee}(_priceUpdateData);
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
        if (!(actualPrice <= acceptablePrice)) {
          revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
        }
      } else {
        uint256 actualPrice = oracle.getMinPrice(indexToken);
        if (!(actualPrice >= acceptablePrice)) {
          revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
        }
      }
      return;
    }

    if (isLong) {
      uint256 actualPrice = oracle.getMinPrice(indexToken);
      if (!(actualPrice >= acceptablePrice)) {
        revert PoolRouter_MarkPriceTooLow(acceptablePrice, actualPrice);
      }
    } else {
      uint256 actualPrice = oracle.getMaxPrice(indexToken);
      if (!(actualPrice <= acceptablePrice)) {
        revert PoolRouter_MarkPriceTooHigh(acceptablePrice, actualPrice);
      }
    }
  }

  function setOraclePriceUpdater(IOnchainPriceUpdater _newOraclePriceUpdater)
    external
    onlyOwner
  {
    emit SetOraclePriceUpdater(
      address(oraclePriceUpdater), address(_newOraclePriceUpdater)
    );
    oraclePriceUpdater = _newOraclePriceUpdater;
  }

  function setTradeMiningManager(ITradeMiningManager _newTradeMiningManager)
    external
    onlyOwner
  {
    emit SetTradeMiningManager(
      address(tradeMiningManager), address(_newTradeMiningManager)
    );
    tradeMiningManager = _newTradeMiningManager;
  }

  function setWNativeRelayer(IWNativeRelayer _wNativeRelayer)
    external
    onlyOwner
  {
    emit SetWNativeRelayer(address(wNativeRelayer), address(_wNativeRelayer));
    wNativeRelayer = _wNativeRelayer;
  }

  function addLiquidity(
    address token,
    uint256 amount,
    address receiver,
    uint256 minLiquidity,
    bytes[] calldata _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    _updatePrices(_priceUpdateData);
    IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(pool), amount);

    uint256 receivedAmount =
      LiquidityFacetInterface(pool).addLiquidity(msg.sender, token, receiver);

    if (receivedAmount < minLiquidity) {
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);
    }

    return receivedAmount;
  }

  function addLiquidityNative(
    address token,
    address receiver,
    uint256 minLiquidity,
    bytes[] calldata _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    uint256 fee = _updatePrices(_priceUpdateData);
    uint256 actualMsgValue = msg.value - fee;
    WNATIVE.deposit{value: actualMsgValue}();
    IERC20Upgradeable(address(WNATIVE)).safeTransfer(
      address(pool), actualMsgValue
    );

    uint256 receivedAmount =
      LiquidityFacetInterface(pool).addLiquidity(msg.sender, token, receiver);

    if (receivedAmount < minLiquidity) {
      revert PoolRouter_InsufficientOutputAmount(minLiquidity, receivedAmount);
    }

    return receivedAmount;
  }

  function removeLiquidity(
    address tokenOut,
    uint256 liquidity,
    address receiver,
    uint256 minAmountOut,
    bytes[] calldata _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    _updatePrices(_priceUpdateData);
    IERC20Upgradeable(address(GetterFacetInterface(pool).alp()))
      .safeTransferFrom(msg.sender, address(pool), liquidity);

    uint256 receivedAmount = LiquidityFacetInterface(pool).removeLiquidity(
      msg.sender, tokenOut, receiver
    );

    if (receivedAmount < minAmountOut) {
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);
    }

    return receivedAmount;
  }

  function removeLiquidityNative(
    address tokenOut,
    uint256 liquidity,
    address receiver,
    uint256 minAmountOut,
    bytes[] calldata _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    _updatePrices(_priceUpdateData);
    IERC20Upgradeable(address(GetterFacetInterface(pool).alp()))
      .safeTransferFrom(msg.sender, address(pool), liquidity);

    uint256 receivedAmount = LiquidityFacetInterface(pool).removeLiquidity(
      msg.sender, tokenOut, address(this)
    );

    if (receivedAmount < minAmountOut) {
      revert PoolRouter_InsufficientOutputAmount(minAmountOut, receivedAmount);
    }

    _transferOutETH(receivedAmount, receiver);

    return receivedAmount;
  }

  function swap(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    address receiver,
    bytes[] calldata _priceUpdateData
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
        sender, address(pool), amountIn
      );
    }

    return LiquidityFacetInterface(pool).swap(
      msg.sender, tokenIn, tokenOut, minAmountOut, receiver
    );
  }

  function swapNative(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    address receiver,
    bytes[] calldata _priceUpdateData
  ) external payable nonReentrant returns (uint256) {
    uint256 fee = _updatePrices(_priceUpdateData);
    uint256 actualMsgValue = msg.value - fee;
    if (tokenIn == address(WNATIVE)) {
      WNATIVE.deposit{value: actualMsgValue}();
      IERC20Upgradeable(address(WNATIVE)).safeTransfer(pool, actualMsgValue);
      amountIn = actualMsgValue;
    } else {
      IERC20Upgradeable(tokenIn).safeTransferFrom(
        msg.sender, address(pool), amountIn
      );
    }

    if (tokenOut == address(WNATIVE)) {
      uint256 amountOut = LiquidityFacetInterface(pool).swap(
        msg.sender, tokenIn, tokenOut, minAmountOut, address(this)
      );

      _transferOutETH(amountOut, receiver);
      return amountOut;
    } else {
      return LiquidityFacetInterface(pool).swap(
        msg.sender, tokenIn, tokenOut, minAmountOut, receiver
      );
    }
  }

  function _transferOutETH(uint256 _amountOut, address _receiver) private {
    // Prevent istanbul msg.sender.transfer problem
    IERC20Upgradeable(address(WNATIVE)).safeTransfer(
      address(wNativeRelayer), _amountOut
    );
    wNativeRelayer.withdraw(_amountOut);

    payable(_receiver).transfer(_amountOut);
  }

  receive() external payable {
    // Only accept NATIVE via fallback from the wNativeRelayer contract
    require(msg.sender == address(wNativeRelayer), "!wNativeRelayer");
  }
}
