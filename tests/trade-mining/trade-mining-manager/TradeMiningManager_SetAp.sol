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

/// Alperp tests
import {
  TradeMiningManager_BaseTest,
  AP
} from
  "@alperp-tests/trade-mining/trade-mining-manager/TradeMiningManager_BaseTest.t.sol";

contract TradeMiningManager_SetAp is TradeMiningManager_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_WhenSetApToNewAP() external {
    tradeMiningManager.setAp(AP(address(0x888888888)));
    assertEq(address(tradeMiningManager.alpacaPoint()), address(0x888888888));
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    tradeMiningManager.setAp(ap);
    vm.stopPrank();
  }
}
