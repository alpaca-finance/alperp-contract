// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Alperp Test
import {
  ForkBaseTest,
  PythPriceFeed,
  PoolRouter04,
  Orderbook02,
  Paradeen,
  AP,
  FakePyth,
  IPyth,
  PoolOracle
} from "@alperp-tests/forks/base/BaseTest.sol";

contract TradeMining_BaseForkTest is ForkBaseTest {
  PoolRouter04 poolRouter04;
  Orderbook02 orderBook02;
  Paradeen paradeen;
  AP ap;
  PoolOracle poolOracle;

  function setUp() public virtual {
    poolRouter04 = PoolRouter04(payable(POOL_ROUTER_04));
    orderBook02 = Orderbook02(payable(ORDER_BOOK));
    ap = AP(AP_ADDRESS);
    paradeen = Paradeen(PARADEEN);
    poolOracle = PoolOracle(POOL_ORACLE);
  }
}
