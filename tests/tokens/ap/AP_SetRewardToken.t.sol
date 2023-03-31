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

import { AP_BaseTest } from "./AP_BaseTest.t.sol";

contract AP_SetRewardToken is AP_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_GrantRewardToken() external {
    // grant WETH as a reward token
    ap.setRewardToken(address(weth), true);

    assertTrue(ap.isRewardToken(address(weth)));

    // then deny WETH
    ap.setRewardToken(address(weth), false);

    assertFalse(ap.isRewardToken(address(weth)));
  }

  function testCorrectness_GrantRewardTokenButDenySome() external {
    // grant WETH and WBTC as a minter
    ap.setRewardToken(address(weth), true);
    ap.setRewardToken(address(wbtc), true);

    assertTrue(ap.isRewardToken(address(weth)));
    assertTrue(ap.isRewardToken(address(wbtc)));

    // then deny only WETH
    // expect that won't affect other
    ap.setRewardToken(address(weth), false);

    assertFalse(ap.isRewardToken(address(weth)));
    assertTrue(ap.isRewardToken(address(wbtc)));
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(BOB);
    vm.expectRevert("Ownable: caller is not the owner");
    ap.setMinter(ALICE, true);
    vm.stopPrank();
  }
}
