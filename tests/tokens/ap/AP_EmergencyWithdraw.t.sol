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

contract AP_EmergencyWithdraw is AP_BaseTest {
  function setUp() public override {
    super.setUp();

    // mint 100 ether to ALICE
    weth.mint(address(ap), 100 ether);
  }

  function testCorrectness_EmergencyWithdraw() external {
    ap.emergencyWithdraw(address(weth), address(ALICE));

    assertEq(weth.balanceOf(address(ap)), 0);
    assertEq(weth.balanceOf(address(ALICE)), 100 ether);
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    ap.emergencyWithdraw(address(weth), address(ALICE));
    vm.stopPrank();
  }
}
