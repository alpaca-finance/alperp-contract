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

import {
  BaseTest,
  console,
  PoolOracle02,
  FakePyth,
  PythPriceFeed
} from "@alperp-tests/base/BaseTest.sol";

abstract contract PoolOracle02_BaseTest is BaseTest {
  PoolOracle02 internal poolOracle02;
  PythPriceFeed internal pythPriceFeed;
  FakePyth internal fakePyth;

  bytes32 internal BNB_PRICE_FEED_ID =
    0x626e620000000000000000000000000000000000000000000000000000000000;
  bytes32 internal ETH_PRICE_FEED_ID =
    0x6574680000000000000000000000000000000000000000000000000000000000;
  bytes32 internal BTCB_PRICE_FEED_ID =
    0x6274636200000000000000000000000000000000000000000000000000000000;
  bytes32 internal DAI_PRICE_FEED_ID =
    0x6461690000000000000000000000000000000000000000000000000000000000;
  bytes32 internal USDC_PRICE_FEED_ID =
    0x7573646300000000000000000000000000000000000000000000000000000000;

  function setUp() public virtual {
    // Deploy Fake Pyth
    fakePyth = new FakePyth(120, 1);
    // Initialize fake pyth
    pythUpdatePriceHelper(DAI_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    pythUpdatePriceHelper(BTCB_PRICE_FEED_ID, 30_000 * 10 ** 8, -8);
    pythUpdatePriceHelper(ETH_PRICE_FEED_ID, 2_000 * 10 ** 8, -8);
    pythUpdatePriceHelper(BNB_PRICE_FEED_ID, 330 * 10 ** 8, -8);

    // Deploy PythPriceFeed
    pythPriceFeed = deployPythPriceFeed(address(fakePyth));
    pythPriceFeed.setTokenPriceId(address(dai), DAI_PRICE_FEED_ID);
    pythPriceFeed.setTokenPriceId(address(usdc), USDC_PRICE_FEED_ID);
    pythPriceFeed.setTokenPriceId(address(wbtc), BTCB_PRICE_FEED_ID);
    pythPriceFeed.setTokenPriceId(address(weth), ETH_PRICE_FEED_ID);
    pythPriceFeed.setTokenPriceId(address(bnb), BNB_PRICE_FEED_ID);
    pythPriceFeed.setMaxPriceAge(120);

    // Deploy PoolOracle02
    poolOracle02 = deployPoolOracle02(address(pythPriceFeed));
  }

  function initValidPriceFeeds() internal {
    (address[] memory tokens, PoolOracle02.PriceFeedInfo[] memory priceFeedInfo)
    = buildPoolOracle02DefaultSetPriceFeedInput();

    poolOracle02.setPriceFeed(tokens, priceFeedInfo);
  }

  function setPriceFeedHelper(
    address token,
    PoolOracle02.PriceFeedInfo memory priceFeedInfo
  ) internal {
    address[] memory tokenArr = new address[](1);
    tokenArr[0] = token;

    PoolOracle02.PriceFeedInfo[] memory priceFeedInfoArr =
      new PoolOracle02.PriceFeedInfo[](1);
    priceFeedInfoArr[0] = priceFeedInfo;

    poolOracle02.setPriceFeed(tokenArr, priceFeedInfoArr);
  }

  function pythUpdatePriceHelper(bytes32 priceFeedId, int64 price, int32 expo)
    internal
  {
    bytes[] memory pythUpdateData = new bytes[](1);
    pythUpdateData[0] = fakePyth.createPriceFeedUpdateData(
      priceFeedId, price, 0, expo, price, 0, uint64(block.timestamp)
    );
    // move block.timestamp to 1 second later so that the price feed is updated
    vm.warp(block.timestamp + 1);
    fakePyth.updatePriceFeeds{value: 1}(pythUpdateData);
  }
}
