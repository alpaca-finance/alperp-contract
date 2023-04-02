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

import {AP_BaseTest} from "./AP_BaseTest.t.sol";
import {AP} from "src/tokens/AP.sol";

contract AP_Mint is AP_BaseTest {
  function setUp() public override {
    super.setUp();

    // grant ALICE as a minter
    ap.setMinter(ALICE, true);
  }

  function _getAccountInfo(uint256 _weekTimestamp, address _owner)
    internal
    returns (uint256)
  {
    (uint256 amount,) = ap.weeklyAccountBalanceOf(_weekTimestamp, _owner);

    return amount;
  }

  function testCorrectness_Mint() external {
    vm.startPrank(ALICE);
    ap.mint(BOB, 1 ether);
    vm.stopPrank();

    assertEq(ap.balanceOf(BOB), 1 ether);
    assertEq(ap.weeklyTotalSupply(0), 1 ether);
    assertEq(_getAccountInfo(0, BOB), 1 ether);
    assertEq(ap.totalSupply(), 1 ether);

    // skip for other week number
    vm.warp(1677554711);

    // just want to check that
    // when mint to other
    // it won't affct to other
    vm.startPrank(ALICE);
    ap.mint(CAT, 1.5 ether);
    vm.stopPrank();

    assertEq(ap.balanceOf(BOB), 1 ether);
    assertEq(ap.balanceOf(CAT), 1.5 ether);
    assertEq(ap.weeklyTotalSupply(0), 1 ether);
    assertEq(ap.weeklyTotalSupply(2773), 1.5 ether);
    assertEq(_getAccountInfo(2773, BOB), 0);
    assertEq(_getAccountInfo(0, CAT), 0);
    assertEq(_getAccountInfo(2773, CAT), 1.5 ether);
    assertEq(ap.totalSupply(), 2.5 ether);

    // skip for other week number
    vm.warp(block.timestamp + 1 weeks);

    // back to mint to BOB and CAT again
    // then also check CAT
    vm.startPrank(ALICE);
    ap.mint(BOB, 2 ether);
    ap.mint(CAT, 0.5 ether);
    vm.stopPrank();

    assertEq(ap.totalSupply(), 5 ether);
    assertEq(ap.balanceOf(BOB), 3 ether);
    assertEq(ap.balanceOf(CAT), 2 ether);
    assertEq(ap.weeklyTotalSupply(0), 1 ether);
    assertEq(ap.weeklyTotalSupply(2773), 1.5 ether);
    assertEq(ap.weeklyTotalSupply(2774), 2.5 ether);
    assertEq(_getAccountInfo(0, BOB), 1 ether);
    assertEq(_getAccountInfo(2773, BOB), 0);
    assertEq(_getAccountInfo(2774, BOB), 2 ether);
    assertEq(_getAccountInfo(0, CAT), 0);
    assertEq(_getAccountInfo(2773, CAT), 1.5 ether);
    assertEq(_getAccountInfo(2774, CAT), 0.5 ether);
  }

  function testRevert_WhenCalledByNonMinter() external {
    vm.startPrank(BOB);
    vm.expectRevert(abi.encodeWithSignature("AP_NotMinter()"));
    ap.mint(BOB, 1 ether);
    vm.stopPrank();
  }
}
