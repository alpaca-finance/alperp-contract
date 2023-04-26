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
  TradeMiningManager,
  AP,
  PoolRouter04,
  Orderbook02
} from "@alperp-tests/base/BaseTest.sol";

abstract contract TradeMiningManager_BaseTest is BaseTest {
  TradeMiningManager tradeMiningManager;
  AP ap;
  PoolRouter04 poolRouter;
  Orderbook02 orderbook;

  function setUp() public virtual {
    // Deploy related contracts
    ap = deployAP();
    tradeMiningManager = deployTradeMiningManager(address(ap));
    poolRouter = deployPoolRouter(
      address(0), address(0), address(0), address(tradeMiningManager)
    );
    orderbook = deployOrderbook(
      address(0), address(0), address(0), 0.01 ether, 1 ether, address(0)
    );

    // Config
    ap.setMinter(address(tradeMiningManager), true);
    orderbook.setTradeMiningManager(tradeMiningManager);
  }
}
