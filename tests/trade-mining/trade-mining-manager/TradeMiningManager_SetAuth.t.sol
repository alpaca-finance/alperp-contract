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

/// Alperp tests
import {TradeMiningManager_BaseTest} from
  "@alperp-tests/trade-mining/trade-mining-manager/TradeMiningManager_BaseTest.t.sol";

contract TradeMiningManager_SetAuth is TradeMiningManager_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_WhenGrantAuth() external {
    // Grant PoolRouter
    tradeMiningManager.setAuth(address(poolRouter), true);

    assertTrue(tradeMiningManager.authed(address(poolRouter)));

    // Then deny PoolRouter
    tradeMiningManager.setAuth(address(poolRouter), false);

    assertFalse(tradeMiningManager.authed(address(poolRouter)));
  }

  function testCorrectness_WhenGrantAuthThenDenySome() external {
    // Grant PoolRouter and OrderBook
    tradeMiningManager.setAuth(address(poolRouter), true);
    tradeMiningManager.setAuth(address(orderbook), true);

    assertTrue(tradeMiningManager.authed(address(poolRouter)));
    assertTrue(tradeMiningManager.authed(address(orderbook)));

    // Then deny PoolRouter only
    // OrderBook should still be authed
    tradeMiningManager.setAuth(address(poolRouter), false);

    assertFalse(tradeMiningManager.authed(address(poolRouter)));
    assertTrue(tradeMiningManager.authed(address(orderbook)));
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    tradeMiningManager.setAuth(address(poolRouter), true);
    vm.stopPrank();
  }
}
