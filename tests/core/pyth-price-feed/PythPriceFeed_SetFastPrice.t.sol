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

import { PythPriceFeed_BaseTest, FakePyth } from "./PythPriceFeed_BaseTest.t.sol";

contract PythPriceFeed_SetFastPrice is PythPriceFeed_BaseTest {
  bytes32 internal constant WBNB_PRICE_ID =
    0x2f95862b045670cd22bee3114c39763a4a08beeb663b145d283c31d7d1101c4f;
  bytes32 internal constant BTC_PRICE_ID =
    0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43;

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
        id: BTC_PRICE_ID,
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
    pyth.updatePriceFeeds{ value: FEE * 2 }(poolPriceFeedDatas);

    // warp to 16 seconds later,
    vm.warp(block.timestamp + 15);
  }

  function testCorrectness_WhenSetMultiPrice() external {
    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);
    pythPriceFeed.setTokenPriceId(address(wbtc), BTC_PRICE_ID);

    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // ALICE call setFastPrice
    vm.prank(ALICE);
    bytes[] memory fastPriceUpdateDatas = new bytes[](2);
    address[] memory tokenAddrs = new address[](2);
    uint256[] memory fastPrices = new uint256[](2);

    tokenAddrs[0] = address(bnb);
    tokenAddrs[1] = address(wbtc);
    fastPrices[0] = 280 * 10**30;
    fastPrices[1] = 28_000 * 10**30;

    pythPriceFeed.setFastPrices(fastPriceUpdateDatas, tokenAddrs, fastPrices);
    vm.stopPrank();

    // assert BNB price state
    (uint256 bnbPrice, uint256 bnbUpdated) = pythPriceFeed.fastPrices(
      WBNB_PRICE_ID
    );
    assertEq(bnbPrice, 280 * 10**30);
    assertEq(bnbUpdated, block.timestamp);

    // assert BTC price state
    (uint256 btcPrice, uint256 btcUpdated) = pythPriceFeed.fastPrices(
      BTC_PRICE_ID
    );
    assertEq(btcPrice, 28_000 * 10**30);
    assertEq(btcUpdated, block.timestamp);
  }

  function testRevert_WhenBeCalledBySomeone() external {
    // ALICE call setFastPrice
    vm.prank(ALICE);
    bytes[] memory fastPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](1);
    uint256[] memory fastPrices = new uint256[](1);

    vm.expectRevert(abi.encodeWithSignature("PythPriceFeed_OnlyUpdater()"));

    pythPriceFeed.setFastPrices(fastPriceUpdateDatas, tokenAddrs, fastPrices);
    vm.stopPrank();
  }

  function testRevert_WhenFastPriceDataIsNotConsistency() external {
    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // ALICE call setFastPrice
    vm.prank(ALICE);
    bytes[] memory fastPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](2);
    uint256[] memory fastPrices = new uint256[](2);

    tokenAddrs[0] = address(bnb);
    tokenAddrs[1] = address(wbtc);
    fastPrices[0] = 280 * 10**30;
    fastPrices[1] = 28_000 * 10**30;

    vm.expectRevert(
      abi.encodeWithSignature("PythPriceFeed_InvalidFastPriceDataLength()")
    );

    pythPriceFeed.setFastPrices(fastPriceUpdateDatas, tokenAddrs, fastPrices);
    vm.stopPrank();
  }

  function testRevert_WhenTryToSetNonWhitelistToken() external {
    // set token to the correct price id
    pythPriceFeed.setTokenPriceId(address(bnb), WBNB_PRICE_ID);
    pythPriceFeed.setTokenPriceId(address(wbtc), BTC_PRICE_ID);

    // set ALICE as a updater
    pythPriceFeed.setUpdater(ALICE, true);

    // ALICE call setFastPrice
    vm.prank(ALICE);
    bytes[] memory fastPriceUpdateDatas = new bytes[](1);
    address[] memory tokenAddrs = new address[](1);
    uint256[] memory fastPrices = new uint256[](1);

    tokenAddrs[0] = address(weth);
    fastPrices[0] = 1800 * 10**30;

    vm.expectRevert(abi.encodeWithSignature("PythPriceFeed_InvalidPriceId()"));

    pythPriceFeed.setFastPrices(fastPriceUpdateDatas, tokenAddrs, fastPrices);
    vm.stopPrank();
  }
}
