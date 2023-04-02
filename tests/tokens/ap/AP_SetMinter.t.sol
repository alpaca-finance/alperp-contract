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

contract AP_SetMinter is AP_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_GrantMinter() external {
    // grant ALICE as a minter
    ap.setMinter(ALICE, true);

    assertTrue(ap.isMinter(ALICE));

    // then deny ALICE
    ap.setMinter(ALICE, false);

    assertFalse(ap.isMinter(ALICE));
  }

  function testCorrectness_GrantMinterButDenySome() external {
    // grant ALICE and BOB as a minter
    ap.setMinter(ALICE, true);
    ap.setMinter(BOB, true);

    assertTrue(ap.isMinter(ALICE));
    assertTrue(ap.isMinter(BOB));

    // then deny only ALICE
    // expect that won't affect other
    ap.setMinter(ALICE, false);

    assertFalse(ap.isMinter(ALICE));
    assertTrue(ap.isMinter(BOB));
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(BOB);
    vm.expectRevert("Ownable: caller is not the owner");
    ap.setMinter(ALICE, true);
    vm.stopPrank();
  }
}
