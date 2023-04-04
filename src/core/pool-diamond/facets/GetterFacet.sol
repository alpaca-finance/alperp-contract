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
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// Alperp
import {PoolOracle} from "../../PoolOracle.sol";
import {LibPoolV1} from "../libraries/LibPoolV1.sol";
import {LibPoolConfigV1} from "../libraries/LibPoolConfigV1.sol";
import {GetterFacetInterface} from "../interfaces/GetterFacetInterface.sol";
import {StrategyInterface} from "../../../interfaces/StrategyInterface.sol";
import {ALP} from "../../../tokens/ALP.sol";

contract GetterFacet is GetterFacetInterface {
  using SafeCast for int256;
  using SafeCast for uint256;

  error GetterFacet_BadSubAccountId();
  error GetterFacet_InvalidAveragePrice();

  enum LiquidityDirection {
    ADD,
    REMOVE
  }

  address internal constant LINKEDLIST_START = address(1);
  address internal constant LINKEDLIST_END = address(1);
  address internal constant LINKEDLIST_EMPTY = address(0);

  uint256 internal constant PRICE_PRECISION = 10 ** 30;
  uint256 internal constant FUNDING_RATE_PRECISION = 1000000;
  uint256 internal constant BPS = 10000;
  uint256 internal constant USD_DECIMALS = 18;

  // ---------------------------
  // Simple info functions
  // ---------------------------
  function additionalAum() external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().additionalAum;
  }

  function approvedPlugins(address user, address plugin)
    external
    view
    returns (bool)
  {
    return LibPoolV1.poolV1DiamondStorage().approvedPlugins[user][plugin];
  }

  function discountedAum() external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().discountedAum;
  }

  function feeReserveOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().feeReserveOf[token];
  }

  function fundingInterval() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().fundingInterval;
  }

  function borrowingRateFactor() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().borrowingRateFactor;
  }

  function fundingRateFactor() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().fundingRateFactor;
  }

  function getStrategyDeltaOf(address token)
    external
    view
    returns (bool, uint256)
  {
    return LibPoolConfigV1.getStrategyDelta(token);
  }

  function guaranteedUsdOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().guaranteedUsdOf[token];
  }

  function isAllowAllLiquidators() external view returns (bool) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().isAllowAllLiquidators;
  }

  function isAllowedLiquidators(address liquidator)
    external
    view
    returns (bool)
  {
    return LibPoolConfigV1.isAllowedLiquidators(liquidator);
  }

  function isDynamicFeeEnable() external view returns (bool) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().isDynamicFeeEnable;
  }

  function isLeverageEnable() external view returns (bool) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().isLeverageEnable;
  }

  function isSwapEnable() external view returns (bool) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().isSwapEnable;
  }

  function lastFundingTimeOf(address user) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().lastFundingTimeOf[user];
  }

  function liquidationFeeUsd() external view returns (uint256) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().liquidationFeeUsd;
  }

  function liquidityOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().liquidityOf[token];
  }

  function maxLeverage() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().maxLeverage;
  }

  function minProfitDuration() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().minProfitDuration;
  }

  function mintBurnFeeBps() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().mintBurnFeeBps;
  }

  function oracle() external view returns (PoolOracle) {
    return LibPoolV1.poolV1DiamondStorage().oracle;
  }

  function pendingStrategyOf(address token)
    external
    view
    returns (StrategyInterface)
  {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().pendingStrategyOf[token];
  }

  function alp() external view returns (ALP) {
    return LibPoolV1.poolV1DiamondStorage().alp;
  }

  function positionFeeBps() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().positionFeeBps;
  }

  function reservedOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().reservedOf[token];
  }

  function router() external view returns (address) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().router;
  }

  function shortSizeOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().shortSizeOf[token];
  }

  function shortAveragePriceOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().shortAveragePriceOf[token];
  }

  function stableBorrowingRateFactor() external view returns (uint64) {
    return
      LibPoolConfigV1.poolConfigV1DiamondStorage().stableBorrowingRateFactor;
  }

  function stableTaxBps() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().stableTaxBps;
  }

  function stableSwapFeeBps() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().stableSwapFeeBps;
  }

  function strategyOf(address token) external view returns (StrategyInterface) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().strategyOf[token];
  }

  function strategyDataOf(address token)
    external
    view
    returns (LibPoolConfigV1.StrategyData memory)
  {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().strategyDataOf[token];
  }

  function sumBorrowingRateOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().sumBorrowingRateOf[token];
  }

  function swapFeeBps() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().swapFeeBps;
  }

  function taxBps() external view returns (uint64) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().taxBps;
  }

  function totalOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().totalOf[token];
  }

  function tokenMetas(address token)
    external
    view
    returns (LibPoolConfigV1.TokenConfig memory)
  {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().tokenMetas[token];
  }

  function totalTokenWeight() external view returns (uint256) {
    return LibPoolConfigV1.poolConfigV1DiamondStorage().totalTokenWeight;
  }

  function totalUsdDebt() external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().totalUsdDebt;
  }

  function usdDebtOf(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().usdDebtOf[token];
  }

  function openInterestLong(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().openInterestLong[token];
  }

  function openInterestShort(address token) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().openInterestShort[token];
  }

  struct GetDeltaLocalVars {
    bool isProfit;
    int256 delta;
    uint256 unsignedDelta;
    int256 fundingFee;
    uint256 price;
    uint256 priceDelta;
    uint256 minBps;
  }

  function getDelta(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 lastIncreasedTime,
    int256 entryFundingRate,
    int256 fundingFeeDebt
  ) public view returns (bool, uint256, int256) {
    GetDeltaLocalVars memory vars;

    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    // Load PoolConfigV1 diamond storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigDs =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    if (averagePrice == 0) revert GetterFacet_InvalidAveragePrice();
    vars.price = isLong
      ? ds.oracle.getMinPrice(indexToken)
      : ds.oracle.getMaxPrice(indexToken);

    unchecked {
      vars.priceDelta = averagePrice > vars.price
        ? averagePrice - vars.price
        : vars.price - averagePrice;
    }
    vars.delta = int256((size * vars.priceDelta) / averagePrice);

    if (isLong) {
      vars.delta = vars.price > averagePrice ? vars.delta : -vars.delta;
    } else {
      vars.delta = vars.price < averagePrice ? vars.delta : -vars.delta;
    }

    // Negative funding fee means profit to the position
    vars.fundingFee =
      getFundingFee(indexToken, isLong, size, entryFundingRate) + fundingFeeDebt;
    vars.delta -= vars.fundingFee;
    vars.isProfit = vars.delta > 0;
    vars.unsignedDelta =
      vars.delta > 0 ? uint256(vars.delta) : uint256(-vars.delta);

    vars.minBps = block.timestamp
      > lastIncreasedTime + poolConfigDs.minProfitDuration
      ? 0
      : poolConfigDs.tokenMetas[indexToken].minProfitBps;
    if (vars.isProfit && vars.unsignedDelta * BPS <= size * vars.minBps) {
      vars.unsignedDelta = 0;
    }
    return (vars.isProfit, vars.unsignedDelta, vars.fundingFee);
  }

  function getDeltaWithoutFundingFee(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 lastIncreasedTime
  ) public view returns (bool, uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    // Load PoolConfigV1 diamond storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigDs =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    if (averagePrice == 0) revert GetterFacet_InvalidAveragePrice();
    uint256 price = isLong
      ? ds.oracle.getMinPrice(indexToken)
      : ds.oracle.getMaxPrice(indexToken);
    uint256 priceDelta;
    unchecked {
      priceDelta =
        averagePrice > price ? averagePrice - price : price - averagePrice;
    }
    uint256 delta = (size * priceDelta) / averagePrice;

    bool isProfit;
    if (isLong) {
      isProfit = price > averagePrice;
    } else {
      isProfit = price < averagePrice;
    }

    uint256 minBps = block.timestamp
      > lastIncreasedTime + poolConfigDs.minProfitDuration
      ? 0
      : poolConfigDs.tokenMetas[indexToken].minProfitBps;

    if (isProfit && delta * BPS <= size * minBps) delta = 0;

    return (isProfit, delta);
  }

  function getEntryBorrowingRate(
    address collateralToken,
    address, /* indexToken */
    bool /* isLong */
  ) external view returns (uint256) {
    return LibPoolV1.poolV1DiamondStorage().sumBorrowingRateOf[collateralToken];
  }

  function getEntryFundingRate(
    address, /*collateralToken*/
    address indexToken,
    bool isLong
  ) external view returns (int256) {
    return isLong
      ? LibPoolV1.poolV1DiamondStorage().accumFundingRateLong[indexToken]
      : LibPoolV1.poolV1DiamondStorage().accumFundingRateShort[indexToken];
  }

  function getBorrowingFee(
    address, /* account */
    address collateralToken,
    address, /* indexToken */
    bool, /* isLong */
    uint256 size,
    uint256 entryBorrowingRate
  ) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    if (size == 0) return 0;

    uint256 borrowingRate =
      ds.sumBorrowingRateOf[collateralToken] - entryBorrowingRate;
    if (borrowingRate == 0) return 0;

    return (size * borrowingRate) / FUNDING_RATE_PRECISION;
  }

  function getFundingFee(
    address indexToken,
    bool isLong,
    uint256 size,
    int256 entryFundingRate
  ) public view returns (int256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    if (size == 0) return 0;

    int256 fundingRate = isLong
      ? ds.accumFundingRateLong[indexToken] - entryFundingRate
      : ds.accumFundingRateShort[indexToken] - entryFundingRate;
    if (fundingRate == 0) return 0;

    return (int256(size) * fundingRate) / int256(FUNDING_RATE_PRECISION);
  }

  function getNextShortAveragePrice(
    address indexToken,
    uint256 nextPrice,
    uint256 sizeDelta
  ) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    uint256 shortSize = ds.shortSizeOf[indexToken];
    uint256 shortAveragePrice = ds.shortAveragePriceOf[indexToken];
    if (shortAveragePrice == 0) return nextPrice;
    uint256 priceDelta = shortAveragePrice > nextPrice
      ? shortAveragePrice - nextPrice
      : nextPrice - shortAveragePrice;
    uint256 delta = (shortSize * priceDelta) / shortAveragePrice;
    bool isProfit = nextPrice < shortAveragePrice;

    uint256 nextSize = shortSize + sizeDelta;
    uint256 divisor = isProfit ? nextSize - delta : nextSize + delta;

    return (nextPrice * nextSize) / divisor;
  }

  function getNextShortAveragePriceWithRealizedPnl(
    address indexToken,
    uint256 nextPrice,
    int256 sizeDelta,
    int256 realizedPnl
  ) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    uint256 shortSize = ds.shortSizeOf[indexToken];
    uint256 shortAveragePrice = ds.shortAveragePriceOf[indexToken];
    if (shortAveragePrice == 0) return nextPrice;
    uint256 priceDelta = shortAveragePrice > nextPrice
      ? shortAveragePrice - nextPrice
      : nextPrice - shortAveragePrice;
    uint256 delta = (shortSize * priceDelta) / shortAveragePrice;
    (bool isProfit, uint256 nextDelta) =
      _getNextDelta(delta, shortAveragePrice, nextPrice, realizedPnl);

    uint256 nextSize = sizeDelta > 0
      ? shortSize + uint256(sizeDelta)
      : shortSize - uint256(-sizeDelta);

    if (nextSize == 0) return 0;

    uint256 divisor = isProfit
      ? nextSize >= nextDelta ? (nextSize - nextDelta) : 0
      : nextSize + nextDelta;
    return divisor > 0 ? (nextPrice * nextSize) / divisor : nextPrice;
  }

  function getPoolShortDelta(address token)
    external
    view
    returns (bool, uint256)
  {
    // Load Diamond Storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    uint256 shortSize = ds.shortSizeOf[token];
    if (shortSize == 0) return (false, 0);

    uint256 nextPrice = ds.oracle.getMaxPrice(token);
    uint256 averagePrice = ds.shortAveragePriceOf[token];
    uint256 priceDelta;
    unchecked {
      priceDelta = averagePrice > nextPrice
        ? averagePrice - nextPrice
        : nextPrice - averagePrice;
    }
    uint256 delta = (shortSize * priceDelta) / averagePrice;

    return (averagePrice > nextPrice, delta);
  }

  function getPositionWithSubAccountId(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (GetPositionReturnVars memory) {
    return getPosition(
      getSubAccount(primaryAccount, subAccountId),
      collateralToken,
      indexToken,
      isLong
    );
  }

  function getPosition(
    address account,
    address collateralToken,
    address indexToken,
    bool isLong
  ) public view returns (GetPositionReturnVars memory) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    LibPoolV1.Position memory position = ds.positions[LibPoolV1.getPositionId(
      account, collateralToken, indexToken, isLong
    )];
    uint256 realizedPnl = position.realizedPnl > 0
      ? uint256(position.realizedPnl)
      : uint256(-position.realizedPnl);
    GetPositionReturnVars memory vars = GetPositionReturnVars({
      primaryAccount: position.primaryAccount,
      size: position.size,
      collateral: position.collateral,
      averagePrice: position.averagePrice,
      entryBorrowingRate: position.entryBorrowingRate,
      entryFundingRate: position.entryFundingRate,
      reserveAmount: position.reserveAmount,
      realizedPnl: realizedPnl,
      hasProfit: position.realizedPnl >= 0,
      lastIncreasedTime: position.lastIncreasedTime,
      fundingFeeDebt: position.fundingFeeDebt
    });
    return vars;
  }

  function getPositionDelta(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (bool, uint256, int256) {
    LibPoolV1.Position memory position = LibPoolV1.poolV1DiamondStorage()
      .positions[LibPoolV1.getPositionId(
      LibPoolV1.getSubAccount(primaryAccount, subAccountId),
      collateralToken,
      indexToken,
      isLong
    )];
    return getDelta(
      indexToken,
      position.size,
      position.averagePrice,
      isLong,
      position.lastIncreasedTime,
      position.entryFundingRate,
      position.fundingFeeDebt
    );
  }

  function getPositionFee(
    address, /* account */
    address, /* collateralToken */
    address, /* indexToken */
    bool, /* isLong */
    uint256 sizeDelta
  ) public view returns (uint256) {
    // Load PoolConfigV1 diamond storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigDs =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    if (sizeDelta == 0) return 0;
    uint256 afterFeeUsd =
      (sizeDelta * (BPS - poolConfigDs.positionFeeBps)) / BPS;
    return sizeDelta - afterFeeUsd;
  }

  function getPositionLeverage(
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong
  ) external view returns (uint256) {
    bytes32 posId = LibPoolV1.getPositionId(
      LibPoolV1.getSubAccount(primaryAccount, subAccountId),
      collateralToken,
      indexToken,
      isLong
    );
    LibPoolV1.Position memory position =
      LibPoolV1.poolV1DiamondStorage().positions[posId];
    return (position.size * BPS) / position.collateral;
  }

  function getPositionNextAveragePrice(
    address indexToken,
    uint256 size,
    uint256 averagePrice,
    bool isLong,
    uint256 nextPrice,
    uint256 sizeDelta,
    uint256 lastIncreasedTime
  ) external view returns (uint256) {
    (bool isProfit, uint256 delta) = getDeltaWithoutFundingFee(
      indexToken, size, averagePrice, isLong, lastIncreasedTime
    );
    uint256 nextSize = size + sizeDelta;
    uint256 divisor;
    if (isLong) {
      divisor = isProfit ? nextSize + delta : nextSize - delta;
    } else {
      divisor = isProfit ? nextSize - delta : nextSize + delta;
    }

    return (nextPrice * nextSize) / divisor;
  }

  function getRedemptionCollateral(address token) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage ds = LibPoolV1.poolV1DiamondStorage();

    if (LibPoolConfigV1.isStableToken(token)) return ds.liquidityOf[token];

    uint256 collateral =
      LibPoolV1.convertUsde30ToTokens(token, ds.guaranteedUsdOf[token], true);
    return collateral + ds.liquidityOf[token] - ds.reservedOf[token];
  }

  function getRedemptionCollateralUsd(address token)
    external
    view
    returns (uint256)
  {
    return LibPoolV1.convertTokensToUsde30(
      token, getRedemptionCollateral(token), false
    );
  }

  function getSubAccount(address primary, uint256 subAccountId)
    public
    pure
    returns (address)
  {
    return LibPoolV1.getSubAccount(primary, subAccountId);
  }

  /// @notice Return target value of a token in USD
  /// @dev Return in 1e18 format
  /// @param token The token address
  function getTargetValue(address token) public view returns (uint256) {
    return _getTargetValue(token, getAumE18(true));
  }

  /// @notice Calculate target value of a token in USD
  /// @dev Return in 1e18 format
  /// @param token The token address
  /// @param totalAumE18 The total asset under management in 1e18
  function _getTargetValue(address token, uint256 totalAumE18)
    internal
    view
    returns (uint256)
  {
    // Load PoolConfigV1 diamond storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigDs =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    if (totalAumE18 == 0) return 0;

    return totalAumE18 * poolConfigDs.tokenMetas[token].weight
      / poolConfigDs.totalTokenWeight;
  }

  // ---------------------------
  // Asset under management math
  // ---------------------------

  /// @notice Return short pnl of a given token
  /// @param poolV1ds Pool's diamond storage
  /// @param token token to calculate short pnl
  function _getShortPnlOf(
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds,
    address token
  ) internal view returns (int256) {
    uint256 shortSize = poolV1ds.shortSizeOf[token];
    uint256 shortAveragePrice = poolV1ds.shortAveragePriceOf[token];
    if (shortSize > 0 && shortAveragePrice > 0) {
      uint256 priceDelta;
      uint256 maxPrice = poolV1ds.oracle.getMaxPrice(token);
      unchecked {
        priceDelta = shortAveragePrice > maxPrice
          ? shortAveragePrice - maxPrice
          : maxPrice - shortAveragePrice;
      }
      // Findout delta (can be either profit or loss) of short positions.
      uint256 delta = (shortSize * priceDelta) / shortAveragePrice;
      if (maxPrice < shortAveragePrice) {
        // Short is in profit. Hence pool is loss.
        return -(delta.toInt256());
      } else {
        // Short is in loss. Hence pool is profit.
        return delta.toInt256();
      }
    }
    return 0;
  }

  /// @notice Calculate current value of an asset in the pool. Factored in trader PnL.
  /// @dev Return in 1e18
  /// @param token Token to calculate current value
  /// @param isUseMaxPrice use max or min price
  function getCurrentValueOf(address token, bool isUseMaxPrice)
    public
    view
    returns (uint256)
  {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();

    uint256 price = !isUseMaxPrice
      ? poolV1ds.oracle.getMinPrice(token)
      : poolV1ds.oracle.getMaxPrice(token);
    uint256 liquidity = poolV1ds.liquidityOf[token];
    uint256 decimals = LibPoolConfigV1.getTokenDecimalsOf(token);

    // Handle strategy delta
    (bool isStrategyProfit, uint256 strategyDelta) =
      LibPoolConfigV1.getStrategyDelta(token);
    if (isStrategyProfit) liquidity += strategyDelta;
    else liquidity -= strategyDelta;

    if (LibPoolConfigV1.isStableToken(token)) {
      // Handing value if it is stable coin
      // If token is a stable coin, try to find
      // best-effort value due to we compressed PnL to one variable.
      // best-effort short PnL alloc = Pool's short profits * stable coin utilization
      // current value = liquidity * price - best-effort short PnL alloc
      address tokenCursor =
        LibPoolConfigV1.getNextAllowTokenOf(LINKEDLIST_START);
      int256 shortPnl = 0;
      uint256 totalStableReserved = 0;
      while (tokenCursor != LINKEDLIST_END) {
        if (LibPoolConfigV1.isStableToken(tokenCursor)) {
          // If it is a stablecoin then sum to totalStableReserved normalized in token's decimals
          totalStableReserved += LibPoolV1.convertTokenDecimals(
            LibPoolConfigV1.getTokenDecimalsOf(tokenCursor),
            decimals,
            poolV1ds.reservedOf[tokenCursor]
          );
        } else {
          // If not then calculate short profit
          shortPnl += _getShortPnlOf(poolV1ds, tokenCursor);
        }
        tokenCursor = LibPoolConfigV1.getNextAllowTokenOf(tokenCursor);
      }
      liquidity = liquidity * price / 10 ** decimals;
      shortPnl = totalStableReserved > 0
        ? shortPnl * poolV1ds.reservedOf[token].toInt256()
          / totalStableReserved.toInt256()
        : int256(0);
      return liquidity.toInt256() + shortPnl < 0
        ? uint256(0)
        : (liquidity.toInt256() + shortPnl).toUint256() / 1e12;
    } else {
      // Handing value calculation if it is volitle asset
      // If token is a volatile asset,
      // current value = ((liquidity - reserved) * price) + guaranteedUsd
      return (
        (((liquidity - poolV1ds.reservedOf[token]) * price) / 10 ** decimals)
          + poolV1ds.guaranteedUsdOf[token]
      ) / 1e12;
    }
  }

  function getAum(bool isUseMaxPrice) public view returns (uint256) {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();

    address token = LibPoolConfigV1.getNextAllowTokenOf(LINKEDLIST_START);
    uint256 aum = poolV1ds.additionalAum;
    uint256 shortProfits = 0;

    while (token != LINKEDLIST_END) {
      uint256 price = !isUseMaxPrice
        ? poolV1ds.oracle.getMinPrice(token)
        : poolV1ds.oracle.getMaxPrice(token);
      uint256 liquidity = poolV1ds.liquidityOf[token];
      uint256 decimals = LibPoolConfigV1.getTokenDecimalsOf(token);

      // Handle strategy delta
      (bool isStrategyProfit, uint256 strategyDelta) =
        LibPoolConfigV1.getStrategyDelta(token);
      if (isStrategyProfit) liquidity += strategyDelta;
      else liquidity -= strategyDelta;

      if (LibPoolConfigV1.isStableToken(token)) {
        aum += (liquidity * price) / 10 ** decimals;
      } else {
        uint256 shortSize = poolV1ds.shortSizeOf[token];
        uint256 shortAveragePrice = poolV1ds.shortAveragePriceOf[token];
        if (shortSize > 0 && shortAveragePrice > 0) {
          uint256 priceDelta;
          uint256 maxPrice = poolV1ds.oracle.getMaxPrice(token);
          unchecked {
            priceDelta = shortAveragePrice > maxPrice
              ? shortAveragePrice - maxPrice
              : maxPrice - shortAveragePrice;
          }
          // Findout delta (can be either profit or loss) of short positions.
          uint256 delta = (shortSize * priceDelta) / shortAveragePrice;

          if (maxPrice > shortAveragePrice) {
            // Short position is at loss, then count it as aum
            aum += delta;
          } else {
            // Short position is at profit, then count it as shortProfits
            shortProfits += delta;
          }
        }

        // Add guaranteed USD to the aum.
        aum += poolV1ds.guaranteedUsdOf[token];

        // Add actual liquidity of the token to the aum.
        aum +=
          ((liquidity - poolV1ds.reservedOf[token]) * price) / 10 ** decimals;
      }

      token = LibPoolConfigV1.getNextAllowTokenOf(token);
    }
    aum = shortProfits > aum ? 0 : aum - shortProfits;
    return poolV1ds.discountedAum > aum
      ? 0
      : aum - poolV1ds.discountedAum - poolV1ds.fundingFeePayable
        + poolV1ds.fundingFeeReceivable;
  }

  function getAumE18(bool isUseMaxPrice) public view returns (uint256) {
    return (getAum(isUseMaxPrice) * 10 ** 18) / PRICE_PRECISION;
  }

  // ------------------------
  // Delta Liquidity Fee Math
  // ------------------------

  /// @notice Calculate fee based on pool's weight.
  /// @dev lower fee when help pool moves closer to the target weight.
  /// @param token The address of a token that is changing.
  /// @param aumE18 The aum of the pool in E18 format.
  /// @param value The value to change in USD (E18 format).
  /// @param feeBps The base fee bps
  /// @param _taxBps The tax fee based on change in underlying.
  /// @param direction The liquidity direction. Add or Remove.
  function getFeeBps(
    address token,
    uint256 aumE18,
    uint256 value,
    uint256 feeBps,
    uint256 _taxBps,
    LiquidityDirection direction
  ) internal view returns (uint256) {
    if (!LibPoolConfigV1.isDynamicFeeEnable()) return feeBps;

    uint256 startValue = getCurrentValueOf(token, true);
    uint256 nextValue = startValue + value;
    if (direction == LiquidityDirection.REMOVE) {
      nextValue = value > startValue ? 0 : startValue - value;
    }

    uint256 targetValue = _getTargetValue(token, aumE18);
    if (targetValue == 0) return feeBps;

    uint256 startTargetDiff = startValue > targetValue
      ? startValue - targetValue
      : targetValue - startValue;
    uint256 nextTargetDiff = nextValue > targetValue
      ? nextValue - targetValue
      : targetValue - nextValue;

    // nextValue moves closer to the targetValue -> positive case;
    // Should apply rebate.
    if (nextTargetDiff < startTargetDiff) {
      uint256 rebateBps = (_taxBps * startTargetDiff) / targetValue;
      return rebateBps > feeBps ? 0 : feeBps - rebateBps;
    }

    // If not then -> negative impact to the pool.
    // Should apply tax.
    uint256 midDiff = (startTargetDiff + nextTargetDiff) / 2;
    if (midDiff > targetValue) {
      midDiff = targetValue;
    }
    _taxBps = (_taxBps * midDiff) / targetValue;

    return feeBps + _taxBps;
  }

  function getAddLiquidityFeeBps(address token, uint256 aum, uint256 value)
    external
    view
    returns (uint256)
  {
    // Load PoolConfigV1 Diamond Storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigV1ds =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    return getFeeBps(
      token,
      aum,
      value,
      poolConfigV1ds.mintBurnFeeBps,
      poolConfigV1ds.taxBps,
      LiquidityDirection.ADD
    );
  }

  function getRemoveLiquidityFeeBps(address token, uint256 aum, uint256 value)
    external
    view
    returns (uint256)
  {
    // Load PoolConfigV1 Diamond Storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigV1ds =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    return getFeeBps(
      token,
      aum,
      value,
      poolConfigV1ds.mintBurnFeeBps,
      poolConfigV1ds.taxBps,
      LiquidityDirection.REMOVE
    );
  }

  function getSwapFeeBps(address tokenIn, address tokenOut, uint256 usdDebt)
    external
    view
    returns (uint256)
  {
    // Load PoolConfigV1 Diamond Storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigV1ds =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    uint256 aum = getAumE18(false);
    bool isStableSwap = poolConfigV1ds.tokenMetas[tokenIn].isStable
      && poolConfigV1ds.tokenMetas[tokenOut].isStable;
    uint64 baseFeeBps =
      isStableSwap ? poolConfigV1ds.stableSwapFeeBps : poolConfigV1ds.swapFeeBps;
    uint64 _taxBps =
      isStableSwap ? poolConfigV1ds.stableTaxBps : poolConfigV1ds.taxBps;
    uint256 feeBpsIn = getFeeBps(
      tokenIn, aum, usdDebt, baseFeeBps, _taxBps, LiquidityDirection.ADD
    );
  }

  // ------------
  // Borrowing rate
  // ------------

  function getNextBorrowingRate(address token) public view returns (uint256) {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();
    // Load PoolConfigV1 Diamond Storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigV1ds =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    uint256 _fundingInterval = poolConfigV1ds.fundingInterval;

    // If block.timestamp not pass the next funding time, return 0.
    if (poolV1ds.lastFundingTimeOf[token] + _fundingInterval > block.timestamp)
    {
      return 0;
    }

    uint256 intervals =
      (block.timestamp - poolV1ds.lastFundingTimeOf[token]) / _fundingInterval;
    // SLOAD
    uint256 liquidity = poolV1ds.liquidityOf[token];
    if (liquidity == 0) return 0;

    uint256 _borrowingRateFactor = poolConfigV1ds.tokenMetas[token].isStable
      ? poolConfigV1ds.stableBorrowingRateFactor
      : poolConfigV1ds.borrowingRateFactor;

    return (_borrowingRateFactor * poolV1ds.reservedOf[token] * intervals)
      / liquidity;
  }

  // ------------
  // Funding rate
  // ------------

  function getNextFundingRate(address token)
    public
    view
    returns (int256 fundingRateLong, int256 fundingRateShort)
  {
    // Load diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();
    // Load PoolConfigV1 Diamond Storage
    LibPoolConfigV1.PoolConfigV1DiamondStorage storage poolConfigV1ds =
      LibPoolConfigV1.poolConfigV1DiamondStorage();

    uint256 _fundingInterval = poolConfigV1ds.fundingInterval;

    // If block.timestamp not pass the next funding time, return 0.
    if (poolV1ds.lastFundingTimeOf[token] + _fundingInterval > block.timestamp)
    {
      return (0, 0);
    }

    uint256 intervals =
      (block.timestamp - poolV1ds.lastFundingTimeOf[token]) / _fundingInterval;

    int256 openInterestLongValue = int256(poolV1ds.openInterestLong[token]);
    int256 openInterestShortValue = int256(poolV1ds.openInterestShort[token]);
    int256 fundingFeesPaidByLongs = (
      openInterestLongValue - openInterestShortValue
    ) * int256(intervals) * int64(poolConfigV1ds.fundingRateFactor);
    int256 absFundingFeesPaidByLongs = fundingFeesPaidByLongs < 0
      ? -fundingFeesPaidByLongs
      : fundingFeesPaidByLongs;

    if (openInterestLongValue > 0) {
      fundingRateLong = fundingFeesPaidByLongs / openInterestLongValue;

      // Handle the precision loss of 1 wei
      fundingRateLong = fundingRateLong > 0
        && fundingRateLong * openInterestLongValue < absFundingFeesPaidByLongs
        ? fundingRateLong + 1
        : fundingRateLong;
    }

    if (openInterestShortValue > 0) {
      fundingRateShort = -fundingFeesPaidByLongs / openInterestShortValue;
      // Handle the precision loss of 1 wei
      fundingRateShort = fundingRateShort > 0
        && fundingRateShort * openInterestShortValue < absFundingFeesPaidByLongs
        ? fundingRateShort + 1
        : fundingRateShort;
    }
  }

  function convertUsde30ToTokens(
    address token,
    uint256 amountUsd,
    bool isUseMaxPrice
  ) external view returns (uint256) {
    return LibPoolV1.convertUsde30ToTokens(token, amountUsd, isUseMaxPrice);
  }

  function getFundingFeeAccounting() external view returns (uint256, uint256) {
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();
    return (poolV1ds.fundingFeePayable, poolV1ds.fundingFeeReceivable);
  }

  function convertTokensToUsde30(
    address token,
    uint256 amountTokens,
    bool isUseMaxPrice
  ) external view returns (uint256) {
    if (amountTokens == 0) return 0;

    // Load PoolV1 diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();

    return (amountTokens * poolV1ds.oracle.getPrice(token, isUseMaxPrice))
      / (10 ** LibPoolConfigV1.getTokenDecimalsOf(token));
  }

  function accumFundingRateLong(address indexToken)
    external
    view
    returns (int256)
  {
    // Load PoolV1 diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();
    return poolV1ds.accumFundingRateLong[indexToken];
  }

  function accumFundingRateShort(address indexToken)
    external
    view
    returns (int256)
  {
    // Load PoolV1 diamond storage
    LibPoolV1.PoolV1DiamondStorage storage poolV1ds =
      LibPoolV1.poolV1DiamondStorage();
    return poolV1ds.accumFundingRateShort[indexToken];
  }

  function _getNextDelta(
    uint256 _globalShortPnL,
    uint256 _averagePrice,
    uint256 _nextPrice,
    int256 _realizedPnl
  ) internal pure returns (bool, uint256) {
    // _globalShortPnL = Global Short PnL in USD
    // _realizedPnL = Realized PnL in USD of this transaction
    // Calculate the PnL to be realized from this transaction in regards to the Global Short PnL of all traders' short positions.
    // Realized PnL will be deducted from Global Short PnL. So, we will have the remaining unrealized PnL of all traders' short positions.
    // Example scenarios:
    // _globalShortPnL = 10000  | _realizedPnl = 1000   => return 10000 - 1000      = 9000
    // _globalShortPnL = 10000  | _realizedPnl = -1000  => return 10000 - (-1000)   = 11000
    // _globalShortPnL = -10000 | _realizedPnl = 1000   => return -10000 - 1000     = -11000
    // _globalShortPnL = -10000 | _realizedPnl = -1000  => return -10000 - (-1000)  = -9000
    // _globalShortPnL = 10000  | _realizedPnl = 11000  => return 10000 - 11000     = -1000
    // _globalShortPnL = -10000 | _realizedPnl = -11000 => return -10000 - (-11000) = 1000

    bool hasProfit = _averagePrice > _nextPrice;
    if (hasProfit) {
      // global shorts pnl is positive
      if (_realizedPnl > 0) {
        if (uint256(_realizedPnl) > _globalShortPnL) {
          _globalShortPnL = uint256(_realizedPnl) - _globalShortPnL;
          hasProfit = false;
        } else {
          _globalShortPnL = _globalShortPnL - uint256(_realizedPnl);
        }
      } else {
        _globalShortPnL = _globalShortPnL + uint256(-_realizedPnl);
      }

      return (hasProfit, _globalShortPnL);
    }

    if (_realizedPnl > 0) {
      _globalShortPnL = _globalShortPnL + uint256(_realizedPnl);
    } else {
      if (uint256(-_realizedPnl) > _globalShortPnL) {
        _globalShortPnL = uint256(-_realizedPnl) - _globalShortPnL;
        hasProfit = true;
      } else {
        _globalShortPnL = _globalShortPnL - uint256(-_realizedPnl);
      }
    }
    return (hasProfit, _globalShortPnL);
  }
}
