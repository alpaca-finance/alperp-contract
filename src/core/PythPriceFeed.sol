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

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ISecondaryPriceFeed } from "../interfaces/ISecondaryPriceFeed.sol";
import { IOnchainPriceUpdater } from "../interfaces/IOnChainPriceUpdater.sol";
import { IPyth } from "../interfaces/IPyth.sol";
import { PythStructs } from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract PythPriceFeed is
  ISecondaryPriceFeed,
  IOnchainPriceUpdater,
  OwnableUpgradeable
{
  using SafeCast for int256;
  using SafeCast for uint256;
  using SafeCast for int32;

  uint256 public constant PRICE_PRECISION = 10**30;
  uint256 public constant MAXIMUM_PRICE_AGE = 120; // 2 mins

  struct FastPrice {
    // Price
    uint256 price;
    // Unix timestamp describing when the price was updated
    uint256 updatedTime;
  }

  // pyth related fields
  IPyth public pyth;
  mapping(address => bytes32) public tokenPriceId;
  uint256 public maxPriceAge;

  bool public favorRefPrice;
  mapping(address => bool) public isUpdater;

  // fast price that represent save gas price
  mapping(bytes32 => FastPrice) public fastPrices;

  event SetTokenPriceId(address indexed token, bytes32 priceId);
  event SetMaxPriceAge(uint256 maxPriceAge);
  event SetFavorRefPrice(bool favorRefPrice);
  event SetUpdater(address indexed account, bool isActive);
  event SetFastPrices(
    bytes[] _priceUpdateData,
    address[] _tokens,
    uint256[] _prices
  );

  error PythPriceFeed_OnlyUpdater();
  error PythPriceFeed_InvalidMaxPriceAge();
  error PythPriceFeed_InvalidPriceId();
  error PythPriceFeed_InvalidFastPriceDataLength();

  function initialize(address _pyth) external initializer {
    OwnableUpgradeable.__Ownable_init();

    pyth = IPyth(_pyth);

    // Sanity check
    pyth.getValidTimePeriod();
  }

  modifier onlyUpdater() {
    if (!isUpdater[msg.sender]) {
      revert PythPriceFeed_OnlyUpdater();
    }
    _;
  }

  /// @notice A function for setting a token price id related to a token address
  /// @param _token - a token address
  /// @param _priceId - a price id (pyth price id)
  function setTokenPriceId(address _token, bytes32 _priceId) public onlyOwner {
    if (!pyth.priceFeedExists(_priceId)) {
      revert PythPriceFeed_InvalidPriceId();
    }

    tokenPriceId[_token] = _priceId;
    emit SetTokenPriceId(_token, _priceId);
  }

  /// @notice Same as setTokenPriceId, but can receive multiple tokens and price ids, indexed by array
  /// @param _tokens -  a list of token addresses
  /// @param _priceId - a list of price ids (pyth price id)
  function setTokenPriceIds(
    address[] calldata _tokens,
    bytes32[] calldata _priceId
  ) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      setTokenPriceId(_tokens[i], _priceId[i]);
    }
  }

  /// @notice A function for set max price age (to prevent price stale)
  /// @param _maxPriceAge - max price age in seconds
  function setMaxPriceAge(uint256 _maxPriceAge) external onlyOwner {
    if (_maxPriceAge > MAXIMUM_PRICE_AGE) {
      revert PythPriceFeed_InvalidMaxPriceAge();
    }
    maxPriceAge = _maxPriceAge;

    emit SetMaxPriceAge(_maxPriceAge);
  }

  /// @notice A function for setting favor ref price, if it's true, then we will neglect pyth prices, and use ref price which is passed from the caller instead
  /// @param _favorRefPrice - boolean indicating favor ref price

  function setFavorRefPrice(bool _favorRefPrice) external onlyOwner {
    favorRefPrice = _favorRefPrice;

    emit SetFavorRefPrice(_favorRefPrice);
  }

  /// @notice A function for setting updater who is able to updatePrices based on price update data
  function setUpdater(address _account, bool _isActive) external onlyOwner {
    isUpdater[_account] = _isActive;

    emit SetUpdater(_account, _isActive);
  }

  /// @notice A function for updating eco prices based on price update data, price id address and price
  /// @param _priceUpdateData - Array of price update data
  /// @param _tokens - Array of token address
  /// @param _prices - Array of price
  function setFastPrices(
    bytes[] memory _priceUpdateData,
    address[] memory _tokens,
    uint256[] memory _prices
  ) external onlyUpdater {
    if (favorRefPrice) {
      return;
    }

    // validate parameter length
    if (
      _priceUpdateData.length != _tokens.length ||
      _priceUpdateData.length != _prices.length
    ) {
      revert PythPriceFeed_InvalidFastPriceDataLength();
    }

    // loop for setting price
    for (uint256 i = 0; i < _priceUpdateData.length; i++) {
      bytes32 priceId = tokenPriceId[_tokens[i]];
      // check token has been set
      if (priceId == 0) {
        revert PythPriceFeed_InvalidPriceId();
      }

      FastPrice memory ecoData = fastPrices[priceId];

      ecoData.price = _prices[i];
      ecoData.updatedTime = block.timestamp;

      fastPrices[priceId] = ecoData;
    }

    emit SetFastPrices(_priceUpdateData, _tokens, _prices);
  }

  /// @notice A function for updating prices based on price update data
  /// @param _priceUpdateData - price update data
  function updatePrices(bytes[] memory _priceUpdateData)
    external
    payable
    onlyUpdater
  {
    if (favorRefPrice) {
      return;
    }
    uint256 fee = pyth.getUpdateFee(_priceUpdateData);
    pyth.updatePriceFeeds{ value: fee }(_priceUpdateData);
  }

  /// @notice A function for getting update fee based on price update data
  /// @param _priceUpdateData - price update data
  function getUpdateFee(bytes[] memory _priceUpdateData)
    external
    view
    returns (uint256)
  {
    if (favorRefPrice) {
      return uint256(0);
    }
    return pyth.getUpdateFee(_priceUpdateData);
  }

  /// @notice A function for getting price of a token
  /// @dev ref price is the price that is passed from the caller, it's used when we want to ignore pyth price (from favor ref price or when pyth price is stale)
  /// @dev ref price is injected via priceOracle (primary price feeder)
  /// @param _token - a token address
  /// @param _referencePrice - a reference price
  function getPrice(
    address _token,
    uint256 _referencePrice,
    bool /*_maximise*/
  ) external view returns (uint256) {
    if (favorRefPrice) {
      return _referencePrice;
    }

    bytes32 priceID = tokenPriceId[_token];
    // Read the current value of priceID, aborting the transaction if the price has not been updated recently.
    // Every chain has a default recency threshold which can be retrieved by calling the getValidTimePeriod() function on the contract.
    // Please see IPyth.sol for variants of this function that support configurable recency thresholds and other useful features.

    FastPrice memory fastPrice = fastPrices[priceID];

    try pyth.getPriceNoOlderThan(priceID, maxPriceAge) returns (
      PythStructs.Price memory _price
    ) {
      if (fastPrice.price != 0 && fastPrice.updatedTime > _price.publishTime) {
        return fastPrice.price;
      }

      uint256 tokenDecimals = _price.expo < 0
        ? (10**int256(-_price.expo).toUint256())
        : 10**int256(_price.expo).toUint256();
      return
        ((int256(_price.price)).toUint256() * PRICE_PRECISION) / tokenDecimals;
    } catch {
      // if some problem occurred (e.g. price is older than maxPriceAge)
      // also check fast if it's still available
      if (
        fastPrice.price != 0 &&
        (block.timestamp - fastPrice.updatedTime) < maxPriceAge
      ) {
        return fastPrice.price;
      }

      // return reference price from primary source
      return _referencePrice;
    }
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  receive() external payable {}
}
