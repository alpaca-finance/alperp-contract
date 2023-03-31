// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity >=0.8.4 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AP_BaseTest } from "./AP_BaseTest.t.sol";

contract AP_Claim is AP_BaseTest {
  function setUp() public override {
    super.setUp();

    // skip for weekTimestamp
    vm.warp(1675496000);

    // mint 100 ether to ALICE
    weth.mint(ALICE, 100 ether);

    // grant ALICE as a minter
    ap.setMinter(ALICE, true);

    // grant WETH as a reward
    ap.setRewardToken(address(weth), true);

    // ALICE grant AP contract as a spender
    vm.startPrank(ALICE);
    weth.approve(address(ap), 1000 ether);
    ap.mint(address(BOB), 7 ether);
    ap.mint(address(CAT), 5 ether);
    ap.mint(address(DAVE), 8 ether);

    vm.warp(block.timestamp + (1 weeks));
    ap.feed(2770, address(weth), 3 ether);
    vm.stopPrank();
  }

  function testCorrectness_Claim() external {
    // BOB claim
    vm.startPrank(BOB);
    ap.claim(2770, address(weth), address(BOB));
    vm.stopPrank();

    // assert it burnt
    assertEq(ap.totalSupply(), 13 ether);
    // assert it transfered
    assertEq(weth.balanceOf(address(ap)), 1.95 ether);
    assertEq(weth.balanceOf(address(BOB)), 1.05 ether);
    // also check isClaimed
    (, bool bobClaimed) = ap.weeklyAccountBalanceOf(2770, address(BOB));
    assertTrue(bobClaimed);

    // then CAT claim
    vm.startPrank(CAT);
    ap.claim(2770, address(weth), address(CAT));
    vm.stopPrank();

    // assert it burnt
    assertEq(ap.totalSupply(), 8 ether);
    // assert it transfered
    assertEq(weth.balanceOf(address(ap)), 1.2 ether);
    assertEq(weth.balanceOf(address(BOB)), 1.05 ether);
    assertEq(weth.balanceOf(address(CAT)), 0.75 ether);
    // also check isClaimed
    (, bool catClaimed) = ap.weeklyAccountBalanceOf(2770, address(CAT));
    assertTrue(catClaimed);

    // then the leftover will be DAVE
    vm.startPrank(DAVE);
    ap.claim(2770, address(weth), address(DAVE));
    vm.stopPrank();

    // assert it burnt
    assertEq(ap.totalSupply(), 0 ether);
    // assert it transfered
    assertEq(weth.balanceOf(address(ap)), 0 ether);
    assertEq(weth.balanceOf(address(DAVE)), 1.2 ether);

    // also check isClaimed
    (, bool daveClaimed) = ap.weeklyAccountBalanceOf(2770, address(DAVE));
    assertTrue(daveClaimed);
  }

  function testCorrectness_WhenClaimForSomeone() external {
    // BOB claim
    vm.startPrank(BOB);
    ap.claim(2770, address(weth), address(CAT));
    vm.stopPrank();

    assertEq(ap.totalSupply(), 15 ether);
    assertEq(weth.balanceOf(address(ap)), 2.25 ether);
    assertEq(weth.balanceOf(address(BOB)), 0 ether);
    assertEq(weth.balanceOf(address(CAT)), 0.75 ether);
  }

  function testRevert_WhenCalledByNonparticipant() external {
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("AP_InvalidClaim()"));
    ap.claim(2770, address(weth), address(ALICE));
    vm.stopPrank();
  }

  function testRevert_WhenSomeoneClaimTwice() external {
    vm.startPrank(BOB);
    ap.claim(2770, address(weth), address(BOB));
    vm.stopPrank();

    vm.startPrank(BOB);
    vm.expectRevert(abi.encodeWithSignature("AP_InvalidClaim()"));
    ap.claim(2770, address(weth), address(BOB));
    vm.stopPrank();
  }
}
