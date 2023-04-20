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

contract PoolOracle02_GetMaxPriceTest is PoolOracle02_BaseTest {
  function setUp() public override {
    super.setUp();
    initValidPriceFeeds();
  }

  function testCorrectness_WhenNormalPriceFeed() external {
    pythUpdatePriceHelper(DAI_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    assertEq(poolOracle02.getMaxPrice(address(dai)), 1 * PRICE_PRECISION);

    pythUpdatePriceHelper(DAI_PRICE_FEED_ID, 11 * 10 ** 7, -8);
    assertEq(poolOracle02.getMaxPrice(address(dai)), 11 * 10 ** 29);
  }

  function testCorrectness_WhenPriceFeedWithSpreadBps() external {
    pythUpdatePriceHelper(BTCB_PRICE_FEED_ID, 30000 * 10 ** 8, -8);
    assertEq(poolOracle02.getMaxPrice(address(wbtc)), 30000 * PRICE_PRECISION);

    // Set spread to be 10 BPS
    PoolOracle02.PriceFeedInfo memory priceFeedInfo = PoolOracle02.PriceFeedInfo({
      decimals: 8,
      spreadBps: 10,
      isStrictStable: false
    });
    setPriceFeedHelper(address(wbtc), priceFeedInfo);

    // getMaxPrice again, this should return price with spread
    assertEq(
      poolOracle02.getMaxPrice(address(wbtc)),
      ((30000 * PRICE_PRECISION) * (BPS + 10)) / BPS
    );
  }

  function testCorrectness_WhenStrictStablePriceFeed() external {
    // Test getMaxPrice without any max strict price deviation yet
    // This should return exact price
    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 1 * 10 ** 8, -8);
    assertEq(poolOracle02.getMaxPrice(address(usdc)), 1 * PRICE_PRECISION);

    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 11 * 10 ** 7, -8);
    assertEq(poolOracle02.getMaxPrice(address(usdc)), 11 * 10 ** 29);

    // Set max strict price deviation to 0.1 USD,
    // so if oracle price diff from 1 USD <= 0.1 USD, then the answer should be 1 USD.
    // Now the lastest answer is 1.1 USD, so the answer should be 1 USD.
    poolOracle02.setMaxStrictPriceDeviation(1 * 10 ** 29);
    assertEq(poolOracle02.getMaxPrice(address(usdc)), 1 * PRICE_PRECISION);

    // Set USDC price to be 1.11 USD which is over the max strict price deviation,
    // So it should returns 1.11 USD.
    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 111 * 10 ** 6, -8);
    assertEq(poolOracle02.getMaxPrice(address(usdc)), 111 * 10 ** 28);

    // --- Test spreadBps ---
    PoolOracle02.PriceFeedInfo memory priceFeedInfo = PoolOracle02.PriceFeedInfo({
      decimals: 8,
      spreadBps: 20,
      isStrictStable: true
    });
    setPriceFeedHelper(address(usdc), priceFeedInfo);

    // Get price again. Oracle data is the same, so it should return the same answer.
    // Due to priceFeedInfo.isStrictStable is true, spreadBps is ignored, the answer should be 1.11 USD.
    assertEq(poolOracle02.getMaxPrice(address(usdc)), 111 * 10 ** 28);

    // Reset spreadBps to 0
    priceFeedInfo.spreadBps = 0;
    setPriceFeedHelper(address(usdc), priceFeedInfo);

    // Set oracle price to 0.9 and get max price again.
    // The max price from latest round is 0.9 which has 0.1 USD deviation,
    // which is less than the max strict price deviation, then it should return 1 USD
    pythUpdatePriceHelper(USDC_PRICE_FEED_ID, 9 * 10 ** 7, -8);
    assertEq(poolOracle02.getMaxPrice(address(usdc)), 1 * PRICE_PRECISION);
  }
}
