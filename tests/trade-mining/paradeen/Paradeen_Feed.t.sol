// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Paradeen_BaseTest} from
  "@alperp-tests/trade-mining/paradeen/Paradeen_BaseTest.t.sol";

contract Paradeen_Feed is Paradeen_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_WhenFeedRewards() public {
    // Set up
    usdc.mint(address(this), 1_000 ether);
    uint256[] memory timestamps = new uint256[](3);
    timestamps[0] = 0;
    timestamps[1] = WEEK + 1 days;
    timestamps[2] = (2 * WEEK) + 2 days;

    uint256[] memory rewards = new uint256[](3);
    rewards[0] = 100 ether;
    rewards[1] = 200 ether;
    rewards[2] = 300 ether;

    // Act
    usdc.approve(address(paradeen), type(uint256).max);
    paradeen.feed(timestamps, rewards);

    // Assert
    assertEq(paradeen.tokensPerWeek(0), 100 ether);
    assertEq(paradeen.tokensPerWeek(WEEK), 200 ether);
    assertEq(paradeen.tokensPerWeek(2 * WEEK), 300 ether);
    assertEq(paradeen.tokensPerWeek(3 * WEEK), 0);
    assertEq(usdc.balanceOf(address(this)), 400 ether);
    assertEq(usdc.balanceOf(address(paradeen)), 600 ether);
  }

  function testRevert_WhenBadLength() external {
    uint256[] memory timestamps = new uint256[](3);
    timestamps[0] = block.timestamp;
    timestamps[1] = block.timestamp + WEEK + 1 days;
    timestamps[2] = block.timestamp + (2 * WEEK) + 2 days;

    uint256[] memory rewards = new uint256[](2);
    rewards[0] = 100 ether;
    rewards[1] = 200 ether;

    vm.expectRevert("bad len");
    paradeen.feed(timestamps, rewards);
  }
}
