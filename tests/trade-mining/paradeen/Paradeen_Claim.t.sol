// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Paradeen_BaseTest} from
  "@alperp-tests/trade-mining/paradeen/Paradeen_BaseTest.t.sol";

contract Paradeen_Claim is Paradeen_BaseTest {
  function setUp() public override {
    super.setUp();

    usdc.mint(address(this), 1_000_000 ether);

    uint256[] memory timestamps = new uint256[](3);
    timestamps[0] = 0;
    timestamps[1] = WEEK;
    timestamps[2] = (2 * WEEK);

    uint256[] memory rewards = new uint256[](3);
    rewards[0] = 100_000 ether;
    rewards[1] = 50_000 ether;
    rewards[2] = 30_000 ether;

    usdc.approve(address(paradeen), type(uint256).max);
    paradeen.feed(timestamps, rewards);
  }

  function testCorrectness_Claim() external {
    // Assuming 1 day has passed after the 1st week
    vm.warp(block.timestamp + 1 days);

    // Mint some AP to Alice
    ap.mint(ALICE, 1_000 ether);
    // Mint some AP to Bob
    ap.mint(BOB, 500 ether);

    // Claim for Alice
    uint256 aliceClaim = paradeen.claim(ALICE);
    assertEq(aliceClaim, 0);
    assertEq(paradeen.weekCursorOf(ALICE), 0);

    // Claim for Bob
    uint256 bobClaim = paradeen.claim(BOB);
    assertEq(bobClaim, 0);
    assertEq(paradeen.weekCursorOf(BOB), 0);

    // Warp to the start of the 2nd week
    vm.warp(WEEK);

    // Now Alice & Bob should be able to claim
    aliceClaim = paradeen.claim(ALICE);
    assertEq(aliceClaim, 66666666666666666666666);
    assertEq(paradeen.weekCursorOf(ALICE), WEEK);

    bobClaim = paradeen.claim(BOB);
    assertEq(bobClaim, 33333333333333333333333);
    assertEq(paradeen.weekCursorOf(BOB), WEEK);

    // Assuming 1 day has passed after the 2nd week
    vm.warp(block.timestamp + 1 days);

    // Mint some AP to Alice
    ap.mint(ALICE, 800 ether);

    // Mint some AP to Bob
    ap.mint(BOB, 200 ether);

    // Try to claim again, should not get anything as rewards are claimed.
    aliceClaim = paradeen.claim(ALICE);
    assertEq(aliceClaim, 0);

    bobClaim = paradeen.claim(BOB);
    assertEq(bobClaim, 0);

    // Warp to the start of the 3rd week
    vm.warp(WEEK * 2);

    // Mint some AP to Alice
    ap.mint(ALICE, 100 ether);

    // Mint some AP to Bob
    ap.mint(BOB, 900 ether);

    // Alice & Bob not claim any here.
    // Expect their weekCursor reminds the same
    assertEq(paradeen.weekCursorOf(ALICE), WEEK);
    assertEq(paradeen.weekCursorOf(BOB), WEEK);

    // Assuming time passed to the start of 4th week
    vm.warp(WEEK * 3);

    // Alice & Bob should be able to claim:
    // Alice = (50000 * 800 / 1000) + (30000 * 100 / 1000)
    //       = 43000 USDC
    aliceClaim = paradeen.claim(ALICE);
    assertEq(aliceClaim, 43_000 ether);
    assertEq(paradeen.weekCursorOf(ALICE), WEEK * 3);

    // Bob = (50000 * 200 / 1000) + (30000 * 900 / 1000)
    //     = 37000 USDC
    bobClaim = paradeen.claim(BOB);
    assertEq(bobClaim, 37_000 ether);
    assertEq(paradeen.weekCursorOf(BOB), WEEK * 3);

    // Cat has nothing to claim but try to claim.
    uint256 catClaim = paradeen.claim(CAT);
    assertEq(catClaim, 0);
    assertEq(paradeen.weekCursorOf(CAT), WEEK * 3);
  }
}
