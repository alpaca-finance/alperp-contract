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

import {
  PythPriceFeed_BaseTest, FakePyth
} from "./PythPriceFeed_BaseTest.t.sol";

contract PythPriceFeed_SetCachedPrice is PythPriceFeed_BaseTest {
  function setUp() public override {
    super.setUp();

    // init price price
    bytes memory bnbPriceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
      id: WBNB_PRICE_ID,
      price: int64(30_000_000_000),
      conf: uint64(150_000_000),
      expo: int32(-8),
      emaPrice: int64(30_000_000_000),
      emaConf: uint64(150_000_000),
      publishTime: uint64(block.timestamp + 1)
    });
    bytes memory btcPriceFeedData = FakePyth(address(pyth))
      .createPriceFeedUpdateData({
      id: WBTC_PRICE_ID,
      price: int64(30_000_000_0000),
      conf: uint64(150_000_0000),
      expo: int32(-8),
      emaPrice: int64(30_000_000_0000),
      emaConf: uint64(150_000_0000),
      publishTime: uint64(block.timestamp + 1)
    });
    bytes[] memory poolPriceFeedDatas = new bytes[](2);
    poolPriceFeedDatas[0] = bnbPriceFeedData;
    poolPriceFeedDatas[1] = btcPriceFeedData;
    pyth.updatePriceFeeds{value: FEE * 2}(poolPriceFeedDatas);

    // warp to 16 seconds later,
    vm.warp(block.timestamp + 15);
  }

  function testCorrectness_WhenSetMultiPrice() external {
    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);
    pythPriceFeed.setTokenPriceId(address(wbtc), WBTC_PRICE_ID);

    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // ALICE call setCachedPrice
    vm.startPrank(ALICE);
    bytes[] memory cachedPriceUpdateDatas = new bytes[](2);
    address[] memory tokenAddrs = new address[](2);
    uint256[] memory cachedPrices = new uint256[](2);

    tokenAddrs[0] = address(bnb);
    tokenAddrs[1] = address(wbtc);
    cachedPrices[0] = 280 * 10 ** 30;
    cachedPrices[1] = 28_000 * 10 ** 30;

    pythPriceFeed.setCachedPrices(
      cachedPriceUpdateDatas, tokenAddrs, cachedPrices
    );
    vm.stopPrank();

    // assert BNB price state
    (uint256 bnbPrice, uint256 bnbUpdated) =
      pythPriceFeed.cachedPriceOf(address(bnb));
    assertEq(bnbPrice, 280 * 10 ** 30);
    assertEq(bnbUpdated, 1);

    // assert BTC price state
    (uint256 btcPrice, uint256 btcUpdated) =
      pythPriceFeed.cachedPriceOf(address(wbtc));
    assertEq(btcPrice, 28_000 * 10 ** 30);
    assertEq(btcUpdated, 1);
  }

  function testRevert_WhenBeCalledBySomeone() external {
    // ALICE call setCachedPrice
    vm.startPrank(ALICE);
    bytes[] memory cachedPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](1);
    uint256[] memory cachedPrices = new uint256[](1);

    vm.expectRevert(abi.encodeWithSignature("PythPriceFeed_OnlyUpdater()"));

    pythPriceFeed.setCachedPrices(
      cachedPriceUpdateDatas, tokenAddrs, cachedPrices
    );
    vm.stopPrank();
  }

  function testRevert_WhenCachedPriceDataIsNotConsistency() external {
    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // ALICE call setCachedPrice
    vm.startPrank(ALICE);
    bytes[] memory cachedPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](2);
    uint256[] memory cachedPrices = new uint256[](2);

    tokenAddrs[0] = address(bnb);
    tokenAddrs[1] = address(wbtc);
    cachedPrices[0] = 280 * 10 ** 30;
    cachedPrices[1] = 28_000 * 10 ** 30;

    vm.expectRevert(
      abi.encodeWithSignature("PythPriceFeed_InvalidCachedPriceDataLength()")
    );

    pythPriceFeed.setCachedPrices(
      cachedPriceUpdateDatas, tokenAddrs, cachedPrices
    );
    vm.stopPrank();
  }
}
