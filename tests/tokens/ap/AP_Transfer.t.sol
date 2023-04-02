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

contract AP_Transfer is AP_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenCallTransfer() external {
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("AP_Unsupported()"));
    ap.transfer(BOB, 1 ether);
    vm.stopPrank();
  }
}
