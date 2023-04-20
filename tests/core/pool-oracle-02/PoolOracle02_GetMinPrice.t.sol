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
  PoolOracle02_BaseTest,
  PoolOracle02
} from "@alperp-tests/core/pool-oracle-02/PoolOracle02_BaseTest.t.sol";

contract PoolOracle02_GetMinPriceTest is PoolOracle02_BaseTest {
  function setUp() public override {
    super.setUp();
    initValidPriceFeeds();
  }

  function testCorrectness_WhenNormalPriceFeed() external {
    pythUpdatePriceHelper(DAI_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    assertEq(poolOracle02.getMinPrice(address(dai)), 1 * PRICE_PRECISION);

    pythUpdatePriceHelper(DAI_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    assertEq(poolOracle02.getMinPrice(address(dai)), 1 * PRICE_PRECISION);
  }

  function testCorrectness_WhenPriceFeedWithSpreadBps() external {
    pythUpdatePriceHelper(BTCB_PRICE_FEED_ID, 30000 * 10 ** 8, -8);
    assertEq(poolOracle02.getMinPrice(address(wbtc)), 30000 * PRICE_PRECISION);

    // Set spread to be 10 BPS
    PoolOracle02.PriceFeedInfo memory priceFeedInfo = PoolOracle02.PriceFeedInfo({
      decimals: 8,
      spreadBps: 10,
      isStrictStable: false
    });
    setPriceFeedHelper(address(wbtc), priceFeedInfo);

    // getMinPrice again, this should return price - spread
    assertEq(
      poolOracle02.getMinPrice(address(wbtc)),
      ((30000 * PRICE_PRECISION) * (BPS - 10)) / BPS
    );
  }

  function testCorrectness_WhenStrictStablePriceFeed() external {
    // Test getMinPrice without any max strict price deviation yet
    // This should return the latest oracle price
    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    assertEq(poolOracle02.getMinPrice(address(usdc)), 1 * PRICE_PRECISION);

    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    assertEq(poolOracle02.getMinPrice(address(usdc)), 1 * PRICE_PRECISION);

    // Set max strict price deviation to 0.1 USD,
    // so if oracle price diff from 1 USD <= 0.1 USD, then the answer should be 1 USD.
    // Now the min answer is 1 USD, so the answer should be 1 USD.
    poolOracle02.setMaxStrictPriceDeviation(1 * 10 ** 29);
    assertEq(poolOracle02.getMinPrice(address(usdc)), 1 * PRICE_PRECISION);

    // Set USDC price to 0.9 USD, this will make latest 3 rounds to be [0.9 USD, 1.11 USD, 1.1 USD],
    // Hence, the min answer from last 3 rounds is 0.9 USD, which the diff is within the max strict price deviation,
    // Then it should returns the actual answer 1 USD.
    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 9 * 10 ** 7, -8);
    assertEq(poolOracle02.getMinPrice(address(usdc)), 1 * PRICE_PRECISION);

    // --- Test spreadBps ---
    PoolOracle02.PriceFeedInfo memory priceFeedInfo = PoolOracle02.PriceFeedInfo({
      decimals: 8,
      spreadBps: 20,
      isStrictStable: true
    });
    setPriceFeedHelper(address(usdc), priceFeedInfo);

    // Get price again. Oracle round data are the same, so it should return the same answer.
    // Due to priceFeedInfo.isStrictStable is true, spreadBps is ignored, the answer should be 1.11 USD.
    assertEq(poolOracle02.getMinPrice(address(usdc)), 1 * PRICE_PRECISION);

    // Reset spreadBps to 0
    priceFeedInfo.spreadBps = 0;
    setPriceFeedHelper(address(usdc), priceFeedInfo);

    // Feed 2 more rounds
    usdcPriceFeed.setLatestAnswer(89 * 10 ** 6);
    usdcPriceFeed.setLatestAnswer(89 * 10 ** 6);

    // Set oracle to 0.89 and get min price again.
    // The min price from latest oracle data is 0.89 which more than the max deviation,
    // then it should return the actual answer from oracle: 0.89 USD.
    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 89 * 10 ** 6, -8);
    assertEq(poolOracle02.getMinPrice(address(usdc)), 89 * 10 ** 28);
  }
}
