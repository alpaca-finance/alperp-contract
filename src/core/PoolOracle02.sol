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

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPriceFeed} from "@alperp/interfaces/IPriceFeed.sol";

contract PoolOracle02 is OwnableUpgradeable {
  using SafeCast for int256;

  error PoolOracle02_BadArguments();
  error PoolOracle02_PriceFeedNotAvailable();
  error PoolOracle02_UnableFetchPrice();

  uint256 internal constant PRICE_PRECISION = 10 ** 30;
  uint256 internal constant ONE_USD = PRICE_PRECISION;
  uint256 internal constant BPS = 10000;

  struct PriceFeedInfo {
    uint8 decimals;
    uint64 spreadBps;
    bool isStrictStable;
  }
  IPriceFeed public corePriceFeed;
  mapping(address => PriceFeedInfo) public priceFeedInfo;
  uint256 public maxStrictPriceDeviation;

  event SetMaxStrictPriceDeviation(
    uint256 prevMaxStrictPriceDeviation, uint256 newMaxStrictPriceDeviation
  );
  event SetPriceFeed(
    address token,
    PriceFeedInfo prevPriceFeedInfo,
    PriceFeedInfo newPriceFeedInfo
  );
  event SetRoundDepth(uint80 prevRoundDepth, uint80 newRoundDepth);
  event SetSecondaryPriceFeed(
    address oldSecondaryPriceFeed, address newSecondaryPriceFeed
  );
  event SetIsSecondaryPriceEnabled(bool oldFlag, bool newFlag);

  function initialize(IPriceFeed corePriceFeed_) external initializer {
    OwnableUpgradeable.__Ownable_init();

    corePriceFeed = corePriceFeed_;
  }

  function _getPrice(address token, bool isUseMaxPrice)
    internal
    view
    returns (uint256)
  {
    uint256 price = _safeFetchPrice(token, isUseMaxPrice);

    // Handle strict stable price deviation.
    // SLOAD
    PriceFeedInfo memory priceFeed = priceFeedInfo[token];
    if (priceFeed.isStrictStable) {
      uint256 delta;
      unchecked {
        delta = price > ONE_USD ? price - ONE_USD : ONE_USD - price;
      }

      if (delta <= maxStrictPriceDeviation) return ONE_USD;

      if (isUseMaxPrice && price > ONE_USD) return price;

      if (!isUseMaxPrice && price < ONE_USD) return price;

      return ONE_USD;
    }

    // Handle spreadBasisPoint
    if (isUseMaxPrice) return (price * (BPS + priceFeed.spreadBps)) / BPS;

    return (price * (BPS - priceFeed.spreadBps)) / BPS;
  }

  function _safeFetchPrice(
    address _token,
    bool _maximise
  ) internal view returns (uint256) {
    return corePriceFeed.getPrice(
      _token, 0, _maximise
    );
  }

  function getPrice(address token, bool isUseMaxPrice)
    external
    view
    returns (uint256)
  {
    return _getPrice(token, isUseMaxPrice);
  }

  function getMaxPrice(address token) external view returns (uint256) {
    return _getPrice(token, true);
  }

  function getMinPrice(address token) external view returns (uint256) {
    return _getPrice(token, false);
  }

  function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
    external
    onlyOwner
  {
    emit SetMaxStrictPriceDeviation(
      maxStrictPriceDeviation, _maxStrictPriceDeviation
      );
    maxStrictPriceDeviation = _maxStrictPriceDeviation;
  }

  function setPriceFeed(
    address[] calldata token,
    PriceFeedInfo[] calldata feedInfo
  ) external onlyOwner {
    if (token.length != feedInfo.length) revert PoolOracle02_BadArguments();

    for (uint256 i = 0; i < token.length;) {
      emit SetPriceFeed(token[i], priceFeedInfo[token[i]], feedInfo[i]);
      priceFeedInfo[token[i]] = feedInfo[i];
      unchecked {
        ++i;
      }
    }
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
