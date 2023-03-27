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

import { PythPriceFeed_BaseTest, PythPriceFeed, IPyth, FakePyth } from "./PythPriceFeed_BaseTest.t.sol";
import { PythStructs } from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract PythPriceFeed_GetPrice is PythPriceFeed_BaseTest {
  using SafeCast for int256;
  using SafeCast for uint256;
  using SafeCast for int32;

  bytes32 internal constant WBNB_PRICE_ID =
    0x2f95862b045670cd22bee3114c39763a4a08beeb663b145d283c31d7d1101c4f;

  struct PriceFeedData {
    bytes32 id;
    int64 price;
    uint64 conf;
    int32 expo;
    int64 emaPrice;
    uint64 emaConf;
    uint64 publishTime;
  }

  function setUp() public override {
    super.setUp();

    // init price price
    bytes memory bnbPriceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
        id: WBNB_PRICE_ID,
        price: int64(30000000000),
        conf: uint64(150000000),
        expo: int32(-8),
        emaPrice: int64(30000000000),
        emaConf: uint64(150000000),
        publishTime: uint64(block.timestamp + 1)
      });
    bytes[] memory poolPriceFeedDatas = new bytes[](1);
    poolPriceFeedDatas[0] = bnbPriceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(poolPriceFeedDatas);

    // warp to 16 seconds later,
    vm.warp(block.timestamp + 15);
  }

  function _convertPythPriceDataToTetherFormat(
    PythStructs.Price memory _price,
    bool _maximise
  ) internal pure returns (uint256) {
    uint256 tokenDecimals = _price.expo < 0
      ? (10**int256(-_price.expo).toUint256())
      : 10**int256(_price.expo).toUint256();
    return
      ((int256(_price.price)).toUint256() * PRICE_PRECISION) / tokenDecimals;
  }

  function testCorrectness_WhenPriceIsOlderThanMaxPrice() external {
    // set max price agge to 15
    pythPriceFeed.setMaxPriceAge(15);

    // set price
    PriceFeedData memory data = PriceFeedData({
      id: WBNB_PRICE_ID,
      price: int64(28895911666),
      conf: uint64(16436851),
      expo: int32(-8),
      emaPrice: int64(28895911666),
      emaConf: uint64(16436851),
      publishTime: uint64(block.timestamp)
    });
    bytes memory priceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
        id: data.id,
        price: data.price,
        conf: data.conf,
        expo: data.expo,
        emaPrice: data.emaPrice,
        emaConf: data.emaConf,
        publishTime: data.publishTime
      });

    // update price in a Pyth contract
    bytes[] memory priceFeedDatas = new bytes[](1);
    priceFeedDatas[0] = priceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(priceFeedDatas);

    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);

    // warp to 16 seconds later, so that price is older than MaxAge (15 seconds)
    vm.warp(block.timestamp + 16);

    // get price, should return ref price instead
    uint256 refPrice = 20000 * 10**30;
    uint256 price = pythPriceFeed.getPrice(address(bnb), refPrice, true);

    assertEq(price, refPrice);
  }

  function testCorrectness_WhenPriceIsNotOlderThanMaxPrice() external {
    // set max price agge to 15
    pythPriceFeed.setMaxPriceAge(15);

    // set price
    PriceFeedData memory data = PriceFeedData({
      id: WBNB_PRICE_ID,
      price: int64(28895911666),
      conf: uint64(16436851),
      expo: int32(-8),
      emaPrice: int64(28895911666),
      emaConf: uint64(16436851),
      publishTime: uint64(block.timestamp)
    });
    bytes memory priceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
        id: data.id,
        price: data.price,
        conf: data.conf,
        expo: data.expo,
        emaPrice: data.emaPrice,
        emaConf: data.emaConf,
        publishTime: data.publishTime
      });

    // update price in a Pyth contract
    bytes[] memory priceFeedDatas = new bytes[](1);
    priceFeedDatas[0] = priceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(priceFeedDatas);

    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);

    // warp to 15 seconds later, so that it's still within MaxAge (15 seconds)
    vm.warp(block.timestamp + 15);

    // get price, should return ref price instead
    uint256 refPrice = 20000 * 10**30;
    uint256 price = pythPriceFeed.getPrice(address(bnb), refPrice, true);

    PythStructs.Price memory priceStruct = PythStructs.Price({
      price: data.price,
      conf: data.conf,
      expo: data.expo,
      publishTime: data.publishTime
    });

    // It should return a price from Pyth service
    assertEq(price, _convertPythPriceDataToTetherFormat(priceStruct, true));
    // Calculation correctness check
    // Price should be 28895911666 * 10**30 / 10**8 = 288959116660000000000000000000000
    // Omit maximize since conf can be very large, hence use only the price from pyth
    assertEq(price, 288959116660000000000000000000000);

    // Incase of maximise = false, it should subtract confidence from the price
    price = pythPriceFeed.getPrice(address(bnb), refPrice, false);

    // It should return a price from Pyth service
    assertEq(price, _convertPythPriceDataToTetherFormat(priceStruct, false));
    // Calculation correctness check
    // Price should be 28895911666 * 10**30 / 10**8 = 288959116660000000000000000000000
    // Omit maximize since conf can be very large, hence use only the price from pyth
    assertEq(price, 288959116660000000000000000000000);
  }

  function testCorrectness_WhenFavorRefPrice() external {
    // set max price agge to 15
    pythPriceFeed.setMaxPriceAge(15);

    // set price
    PriceFeedData memory data = PriceFeedData({
      id: WBNB_PRICE_ID,
      price: int64(27775911666),
      conf: uint64(16436851),
      expo: int32(-8),
      emaPrice: int64(28895911666),
      emaConf: uint64(16436851),
      publishTime: uint64(block.timestamp)
    });
    bytes memory priceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
        id: data.id,
        price: data.price,
        conf: data.conf,
        expo: data.expo,
        emaPrice: data.emaPrice,
        emaConf: data.emaConf,
        publishTime: data.publishTime
      });

    // update price in a Pyth contract
    bytes[] memory priceFeedDatas = new bytes[](1);
    priceFeedDatas[0] = priceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(priceFeedDatas);

    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);

    // favor ref price
    pythPriceFeed.setFavorRefPrice(true);

    // warp to 15 seconds later, set price again
    vm.warp(block.timestamp + 15);

    // set price
    data = PriceFeedData({
      id: WBNB_PRICE_ID,
      price: int64(28895911666),
      conf: uint64(16436851),
      expo: int32(-8),
      emaPrice: int64(28895911666),
      emaConf: uint64(16436851),
      publishTime: uint64(block.timestamp)
    });
    priceFeedData = FakePyth(address(pyth)).createPriceFeedUpdateData({
      id: data.id,
      price: data.price,
      conf: data.conf,
      expo: data.expo,
      emaPrice: data.emaPrice,
      emaConf: data.emaConf,
      publishTime: data.publishTime
    });

    // update price in a Pyth contract
    priceFeedDatas[0] = priceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(priceFeedDatas);

    // warp to 15 seconds later, so that it's still within MaxAge (15 seconds)
    vm.warp(block.timestamp + 15);

    // get price, should return ref price instead since the price we feed is stale now
    uint256 refPrice = 20000 * 10**30;
    uint256 price = pythPriceFeed.getPrice(address(bnb), refPrice, true);

    assertEq(price, refPrice);
  }

  function testCorrectness_WhenGetFastPriceAtSameBlockWithSetFastPrice()
    external
  {
    // set max price agge to 15
    pythPriceFeed.setMaxPriceAge(15);

    // set price
    bytes memory priceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
        id: WBNB_PRICE_ID,
        price: int64(28895911666),
        conf: uint64(16436851),
        expo: int32(-8),
        emaPrice: int64(28895911666),
        emaConf: uint64(16436851),
        publishTime: uint64(block.timestamp)
      });

    // update price in a Pyth contract
    bytes[] memory priceFeedDatas = new bytes[](1);
    priceFeedDatas[0] = priceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(priceFeedDatas);

    // warp to 5 seconds later
    vm.warp(block.timestamp + 5);

    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);

    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // alice set eco price
    uint256 fastWBNBPrice = 280 * 10**30;
    vm.prank(ALICE);
    bytes[] memory fastPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](1);
    uint256[] memory fastPrices = new uint256[](1);
    tokenAddrs[0] = address(bnb);
    fastPrices[0] = fastWBNBPrice;
    pythPriceFeed.setFastPrices(fastPriceUpdateDatas, tokenAddrs, fastPrices);
    vm.stopPrank();

    // get price, should return eco price instead
    uint256 price = pythPriceFeed.getPrice(address(bnb), 290 * 10**30, true);

    assertEq(price, fastWBNBPrice);
  }

  function testCorrectness_WhenGetFastPriceAfterSetFastPriceBlock() external {
    // set max price agge to 15
    pythPriceFeed.setMaxPriceAge(15);

    // set price
    bytes memory priceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
        id: WBNB_PRICE_ID,
        price: int64(28895911666),
        conf: uint64(16436851),
        expo: int32(-8),
        emaPrice: int64(28895911666),
        emaConf: uint64(16436851),
        publishTime: uint64(block.timestamp)
      });

    // update price in a Pyth contract
    bytes[] memory priceFeedDatas = new bytes[](1);
    priceFeedDatas[0] = priceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(priceFeedDatas);

    // warp to 5 seconds later
    vm.warp(block.timestamp + 5);

    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);

    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // alice set eco price
    uint256 fastWBNBPrice = 280 * 10**30;
    vm.prank(ALICE);
    bytes[] memory fastPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](1);
    uint256[] memory fastPrices = new uint256[](1);
    tokenAddrs[0] = address(bnb);
    fastPrices[0] = fastWBNBPrice;
    pythPriceFeed.setFastPrices(fastPriceUpdateDatas, tokenAddrs, fastPrices);
    vm.stopPrank();

    // warp to 5 seconds later
    vm.warp(block.timestamp + 3);

    // get price, should return eco price instead
    uint256 price = pythPriceFeed.getPrice(address(bnb), 290 * 10**30, true);

    assertEq(price, 288959116660000000000000000000000);
  }

  function testCorrectness_WhenSomeoneUpdatePythPriceButStillSameBlock()
    external
  {
    // set max price agge to 15
    pythPriceFeed.setMaxPriceAge(15);

    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);

    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // alice set eco price
    uint256 fastWBNBPrice = 280 * 10**30;
    vm.prank(ALICE);
    bytes[] memory fastPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](1);
    uint256[] memory fastPrices = new uint256[](1);
    tokenAddrs[0] = address(bnb);
    fastPrices[0] = fastWBNBPrice;
    pythPriceFeed.setFastPrices(fastPriceUpdateDatas, tokenAddrs, fastPrices);
    vm.stopPrank();

    // set price
    bytes memory priceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
        id: WBNB_PRICE_ID,
        price: int64(28895911666),
        conf: uint64(16436851),
        expo: int32(-8),
        emaPrice: int64(28895911666),
        emaConf: uint64(16436851),
        publishTime: uint64(block.timestamp)
      });

    // update price in a Pyth contract
    bytes[] memory priceFeedDatas = new bytes[](1);
    priceFeedDatas[0] = priceFeedData;
    pyth.updatePriceFeeds{ value: FEE }(priceFeedDatas);

    // get price, should return eco price instead
    uint256 price = pythPriceFeed.getPrice(address(bnb), 290 * 10**30, true);

    assertEq(price, fastWBNBPrice);
  }
}
