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

/// Alperp Tests
import {Config} from "@alperp-tests/forks/base/Config.sol";
import {
  BaseTest,
  AP,
  Paradeen,
  PoolOracle,
  Orderbook02,
  PoolRouter04,
  PythPriceFeed,
  IERC20,
  ChainlinkPriceFeedInterface,
  AccessControlFacetInterface
} from "@alperp-tests/base/BaseTest.sol";

/// Pyth
import {MockPyth as FakePyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

abstract contract ForkBaseTest is BaseTest, Config {
  address internal constant EVE = address(0x888888);

  IERC20 internal forkBusd;
  IERC20 internal forkWbtc;
  IERC20 internal forkWbnb;
  IERC20 internal forkAlpaca;

  ChainlinkPriceFeedInterface internal forkBusdPriceFeed;
  ChainlinkPriceFeedInterface internal forkWbtcPriceFeed;
  ChainlinkPriceFeedInterface internal forkBnbPriceFeed;

  AccessControlFacetInterface internal forkPoolAccessControlFacet;

  PoolRouter04 forkPoolRouter04;
  Orderbook02 forkOrderBook02;
  Paradeen forkParadeen;
  AP forkAp;
  PoolOracle forkPoolOracle;

  constructor() {
    forkBusd = IERC20(BUSD_TOKEN);
    forkWbtc = IERC20(WBTC_TOKEN);
    forkWbnb = IERC20(WBNB_TOKEN);
    forkAlpaca = IERC20(ALPACA_TOKEN);

    forkBusdPriceFeed = ChainlinkPriceFeedInterface(BUSD_CHAINLINK_ORACLE);
    forkWbtcPriceFeed = ChainlinkPriceFeedInterface(WBTC_CHAINLINK_ORACLE);
    forkBnbPriceFeed = ChainlinkPriceFeedInterface(BNB_CHAINLINK_ORACLE);

    forkPoolAccessControlFacet =
      AccessControlFacetInterface(POOL_DIAMOND_ADDRESS);

    forkPoolRouter04 = PoolRouter04(payable(POOL_ROUTER_04));
    forkOrderBook02 = Orderbook02(payable(ORDER_BOOK));
    forkAp = AP(AP_ADDRESS);
    forkParadeen = Paradeen(PARADEEN);
    forkPoolOracle = PoolOracle(POOL_ORACLE);
  }
}
