// SPDX-License-Identifier: MIT
/**
 *   ∩~~~~∩
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
import {TradeMiningManager_BaseTest} from
  "@alperp-tests/trade-mining/trade-mining-manager/TradeMiningManager_BaseTest.t.sol";

contract TradeMiningManager_SetPeriod is TradeMiningManager_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_SetPeriod() external {
    tradeMiningManager.setPeriod(1_680_000_000, 1_700_000_000);

    assertEq(tradeMiningManager.startTimestamp(), 1_680_000_000);
    assertEq(tradeMiningManager.endTimestamp(), 1_700_000_000);
  }

  function testRevert_WhenStartAfterEndTimestamp() external {
    vm.expectRevert(
      abi.encodeWithSignature("TradeMiningManager_InvalidPeriod()")
    );
    tradeMiningManager.setPeriod(1_700_000_000, 1_680_000_000);
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    tradeMiningManager.setPeriod(1_680_000_000, 1_700_000_000);
    vm.stopPrank();
  }
}
