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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Miner_IncreasePosition is Miner_BaseTest {
  function setUp() public override {
    super.setUp();

    miner.setPeriod(1_680_000_000, 1_700_000_000);
    miner.setWhitelist(address(poolRouter), true);
  }

  function testCorrectness_IncreasePosition() external {
    miner.setMiningPoint(address(miningPoint));

    // warp to 1_680_086_400 block.timestamp
    vm.warp(1_680_086_400);

    vm.startPrank(address(poolRouter));
    miner.increasePosition(ALICE, 0, address(0), address(0), 100 ether, 0, true);
    vm.stopPrank();

    assertEq(miningPoint.balanceOf(ALICE), 100 ether);
  }

  function testCorrectness_WhenCallBeforeStartTimestamp() external {
    miner.setMiningPoint(address(miningPoint));

    vm.startPrank(address(poolRouter));
    miner.increasePosition(ALICE, 0, address(0), address(0), 100 ether, 0, true);
    vm.stopPrank();

    assertEq(miningPoint.balanceOf(ALICE), 0);
  }

  function testCorrectness_WhenCallAfterEndTimestamp() external {
    miner.setMiningPoint(address(miningPoint));

    // warp to 1_700_086_400 block.timestamp
    vm.warp(1_700_086_400);

    vm.startPrank(address(poolRouter));
    miner.increasePosition(ALICE, 0, address(0), address(0), 100 ether, 0, true);
    vm.stopPrank();

    assertEq(miningPoint.balanceOf(ALICE), 0);
  }

  function testRevert_WhenCallBeforeSetMiningPoint() external {
    vm.startPrank(address(poolRouter));

    vm.expectRevert(abi.encodeWithSignature("Miner_InvlidMiningPoint()"));

    miner.increasePosition(ALICE, 0, address(0), address(0), 100 ether, 0, true);
    vm.stopPrank();
  }

  function testRevert_WhenCalledByNonWhitelisted() external {
    vm.startPrank(address(orderbook));
    vm.expectRevert(abi.encodeWithSignature("Miner_NotWhitelisted()"));
    miner.increasePosition(ALICE, 0, address(0), address(0), 100 ether, 0, true);
    vm.stopPrank();
  }
}
