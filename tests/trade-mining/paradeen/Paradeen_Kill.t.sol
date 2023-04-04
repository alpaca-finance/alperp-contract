// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Paradeen_BaseTest} from
  "@alperp-tests/trade-mining/paradeen/Paradeen_BaseTest.t.sol";

contract Paradeen_Kill is Paradeen_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_WhenKill() public {
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

    // Feed
    usdc.approve(address(paradeen), type(uint256).max);
    paradeen.feed(timestamps, rewards);

    // Kill
    paradeen.kill();

    assertTrue(paradeen.isKilled());
    assertEq(usdc.balanceOf(DAVE), 600 ether);

    vm.expectRevert("killed");
    paradeen.feed(timestamps, rewards);

    vm.prank(ALICE, ALICE);
    vm.expectRevert("killed");
    paradeen.claim();
  }

  function testRevert_WhenRandomAccountTryToKill() external {
    vm.startPrank(ALICE, ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    paradeen.kill();
    vm.stopPrank();
  }
}
