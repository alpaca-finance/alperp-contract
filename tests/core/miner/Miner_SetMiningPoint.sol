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

contract Miner_SetMiningPoint is Miner_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_SetMiningPoint() external {
    // grant PoolRouter
    miner.setMiningPoint(address(miningPoint));

    assertEq(miner.miningPoint(), address(miningPoint));

    // then deny PoolRouter
    miner.setMiningPoint(address(miningPoint));

    assertEq(miner.miningPoint(), address(miningPoint));
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    miner.setMiningPoint(address(miningPoint));
    vm.stopPrank();
  }
}
