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

pragma solidity >=0.8.4 <0.9.0;

import {Miner_BaseTest} from "./Miner_BaseTest.t.sol";

contract Miner_SetWhitelist is Miner_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_GrantWhitelist() external {
    // grant PoolRouter
    miner.setWhitelist(address(poolRouter), true);

    assertTrue(miner.isWhitelist(address(poolRouter)));

    // then deny PoolRouter
    miner.setWhitelist(address(poolRouter), false);

    assertFalse(miner.isWhitelist(address(poolRouter)));
  }

  function testCorrectness_GrantWhitelistButDenySome() external {
    // grant PoolRouter and OrderBook
    miner.setWhitelist(address(poolRouter), true);
    miner.setWhitelist(address(orderbook), true);

    assertTrue(miner.isWhitelist(address(poolRouter)));
    assertTrue(miner.isWhitelist(address(orderbook)));

    // then deny only PoolRouter
    // expect that won't affect other
    miner.setWhitelist(address(poolRouter), false);

    assertFalse(miner.isWhitelist(address(poolRouter)));
    assertTrue(miner.isWhitelist(address(orderbook)));
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    miner.setWhitelist(address(poolRouter), true);
    vm.stopPrank();
  }
}
