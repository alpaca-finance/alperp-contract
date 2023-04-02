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

import {AP_BaseTest} from "@alperp-tests/trade-mining/ap/AP_BaseTest.t.sol";
import {AP} from "@alperp/trade-mining/AP.sol";

contract AP_Mint is AP_BaseTest {
  function setUp() public override {
    super.setUp();

    // Grant ALICE as a minter
    ap.setMinter(ALICE, true);
  }

  function testCorrectness_WhenMint() external {
    // Assuming mint to Bob's account
    vm.prank(ALICE, ALICE);
    ap.mint(BOB, 1 ether);

    assertEq(ap.balanceOf(BOB), 1 ether);
    assertEq(ap.weeklyTotalSupply(0), 1 ether);
    assertEq(ap.balanceOf(BOB), 1 ether);
    assertEq(ap.totalSupply(), 1 ether);

    // Skip for other week number
    vm.warp(block.timestamp + ap.WEEK());

    // Then mint to Cat's account
    vm.startPrank(ALICE);
    ap.mint(CAT, 1.5 ether);
    vm.stopPrank();

    // Check previous epoch data
    // Expect Bob's weeklyBalance[0] to be 1 ether
    assertEq(ap.weeklyBalanceOf(0, BOB), 1 ether);
    // Expect weeklyTotalSupply[0] to be 1 ether.
    assertEq(ap.weeklyTotalSupply(0), 1 ether);

    // Check current epoch data
    // Expect Bob's balance to be 0.
    assertEq(ap.balanceOf(BOB), 0);
    // Expect Cat's balance to be 1.5 ether.
    assertEq(ap.balanceOf(CAT), 1.5 ether);
    // Expect Cat's weeklyBalance[1 * WEEK] to be 1.5 ether.
    assertEq(ap.weeklyBalanceOf(1 * ap.WEEK(), CAT), 1.5 ether);
    // Expect totalSupply to be 1.5 ether.
    assertEq(ap.totalSupply(), 1.5 ether);

    // skip for other week number
    vm.warp(block.timestamp + 1 weeks);

    // back to mint to BOB and CAT again
    // then also check CAT
    vm.startPrank(ALICE);
    ap.mint(BOB, 2 ether);
    ap.mint(CAT, 0.5 ether);
    vm.stopPrank();

    // Check epoch[0] data
    // Expect Bob's weeklyBalance[0] to be 1 ether
    assertEq(ap.weeklyBalanceOf(0, BOB), 1 ether);
    // Expect weeklyTotalSupply[0] to be 1 ether.
    assertEq(ap.weeklyTotalSupply(0), 1 ether);

    // Check epoch[1] data
    // Expect Bob's weeklyBalance[1 * WEEK] to be 0.
    assertEq(ap.weeklyBalanceOf(1 * ap.WEEK(), BOB), 0);
    // Expect Cat's weeklyBalance[1 * WEEK] to be 1.5 ether.
    assertEq(ap.weeklyBalanceOf(1 * ap.WEEK(), CAT), 1.5 ether);
    // Expect weeklyTotalSupply[1 * ap.WEEK()] to be 1.5 ether.
    assertEq(ap.weeklyTotalSupply(1 * ap.WEEK()), 1.5 ether);

    // Check current epoch data
    // Expect Bob's balance to be 0.
    assertEq(ap.balanceOf(BOB), 2 ether);
    // Expect Bob's weeklyBalance[2 * WEEK] to be 2 ether.
    assertEq(ap.weeklyBalanceOf(2 * ap.WEEK(), BOB), 2 ether);
    // Expect Cat's balance to be 0.5 ether.
    assertEq(ap.balanceOf(CAT), 0.5 ether);
    // Expect Cat's weeklyBalance[2 * WEEK] to be 0.5 ether.
    assertEq(ap.weeklyBalanceOf(2 * ap.WEEK(), CAT), 0.5 ether);
    // Expect totalSupply to be 2.5 ether.
    assertEq(ap.totalSupply(), 2.5 ether);
    // Expect weeklyTotalSupply[2 * WEEK] to be 2.5 ether.
    assertEq(ap.weeklyTotalSupply(2 * ap.WEEK()), 2.5 ether);

    // skip for other week number
    vm.warp(block.timestamp + 1 weeks);

    // Check current epoch data.
    // Expect Bob's balance to be 0.
    assertEq(ap.balanceOf(BOB), 0);
    // Expect Bob's weeklyBalance[3 * WEEK] to be 0 ether.
    assertEq(ap.weeklyBalanceOf(3 * ap.WEEK(), BOB), 0);
    // Expect Cat's balance to be 0.
    assertEq(ap.balanceOf(CAT), 0);
    // Expect Cat's weeklyBalance[3 * WEEK] to be 0 ether.
    assertEq(ap.weeklyBalanceOf(3 * ap.WEEK(), CAT), 0);
  }

  function testRevert_WhenCalledByNonMinter() external {
    vm.startPrank(BOB);
    vm.expectRevert(abi.encodeWithSignature("AP_NotMinter()"));
    ap.mint(BOB, 1 ether);
    vm.stopPrank();
  }
}
