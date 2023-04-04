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

import {AP_BaseTest} from "@alperp-tests/trade-mining/ap/AP_BaseTest.t.sol";

contract AP_TransferFrom is AP_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenCallTransferFrom() external {
    vm.startPrank(ALICE);
    vm.expectRevert(abi.encodeWithSignature("AP_Unsupported()"));
    ap.transferFrom(address(this), BOB, 1 ether);
    vm.stopPrank();
  }
}
