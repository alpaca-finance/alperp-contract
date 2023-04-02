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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AP_BaseTest} from "./AP_BaseTest.t.sol";

contract AP_Feed is AP_BaseTest {
  function setUp() public override {
    super.setUp();

    // skip for weekTimestamp
    vm.warp(1682821511);

    // mint 100 ether to ALICE
    weth.mint(ALICE, 100 ether);

    // grant ALICE as a minter
    ap.setMinter(ALICE, true);

    // grant WETH as a reward
    ap.setRewardToken(address(weth), true);

    // ALICE grant AP contract as a spender
    vm.startPrank(ALICE);
    weth.approve(address(ap), 1000 ether);
    vm.stopPrank();
  }

  function testCorrectness_Feed() external {
    vm.startPrank(ALICE);
    ap.feed(2770, address(weth), 12 ether);
    vm.stopPrank();

    // expect reward should be transfer
    // and weekly reward amount should be update
    assertEq(weth.balanceOf(address(ap)), 12 ether);
    assertEq(ap.weeklyRewardTokenBalanceOf(2770, address(weth)), 12 ether);

    // check indexing
    assertEq(ap.indexWeekTimestamp(0), 2770);
    assertEq(ap.latestIndex(), 1);

    // try to feed another week
    vm.startPrank(ALICE);
    ap.feed(2777, address(weth), 15 ether);
    vm.stopPrank();

    // old fed shouldn't change
    assertEq(ap.weeklyRewardTokenBalanceOf(2770, address(weth)), 12 ether);

    // at week 2777, reward amount should be update
    assertEq(weth.balanceOf(address(ap)), 27 ether);
    assertEq(ap.weeklyRewardTokenBalanceOf(2777, address(weth)), 15 ether);

    // check indexing
    assertEq(ap.indexWeekTimestamp(0), 2770);
    assertEq(ap.indexWeekTimestamp(1), 2777);
    assertEq(ap.latestIndex(), 2);
  }

  function testRevert_WhenCalledByNonMinter() external {
    vm.startPrank(BOB);
    weth.approve(address(ap), 12 ether);
    vm.expectRevert(abi.encodeWithSignature("AP_NotMinter()"));
    ap.feed(2770, address(weth), 12 ether);
    vm.stopPrank();
  }

  function testRevert_WhenFeedInAdvance() external {
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("AP_FeedInvalidWeekTimestamp()"));
    ap.feed(2800, address(weth), 1 ether);
    vm.stopPrank();
  }

  function testRevert_WhenFeedWithDenyToken() external {
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("AP_NotRewardToken()"));
    ap.feed(2770, address(wbtc), 1 ether);
    vm.stopPrank();
  }

  function testRevert_WhenDuplicatedFeed() external {
    vm.startPrank(ALICE);
    ap.feed(2770, address(weth), 1 ether);
    vm.stopPrank();

    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("AP_AlreadyFed()"));
    ap.feed(2770, address(weth), 1 ether);
    vm.stopPrank();
  }
}
