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

pragma solidity 0.8.17;

/// OZ
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Alperp tests
import {TradeMiningManager_BaseTest} from
  "@alperp-tests/trade-mining/trade-mining-manager/TradeMiningManager_BaseTest.t.sol";

contract TradeMiningManager_DecreasePosition is TradeMiningManager_BaseTest {
  function setUp() public override {
    super.setUp();

    tradeMiningManager.setPeriod(1_680_000_000, 1_700_000_000);
    tradeMiningManager.setAuth(address(poolRouter), true);
  }

  function testCorrectness_DecreasePosition() external {
    tradeMiningManager.setAp(ap);

    // warp to 1_680_086_400 block.timestamp
    vm.warp(1_680_086_400);

    vm.startPrank(address(poolRouter));
    tradeMiningManager.onDecreasePosition(
      ALICE, 0, address(0), address(0), 100 * 10 ** 30, true
    );
    vm.stopPrank();

    assertEq(ap.balanceOf(ALICE), 100 ether);
  }

  function testCorrectness_WhenCallBeforeStartTimestamp() external {
    tradeMiningManager.setAp(ap);

    vm.startPrank(address(poolRouter));
    tradeMiningManager.onDecreasePosition(
      ALICE, 0, address(0), address(0), 100 * 10 ** 30, true
    );
    vm.stopPrank();

    assertEq(ap.balanceOf(ALICE), 0);
  }

  function testCorrectness_WhenCallAfterEndTimestamp() external {
    tradeMiningManager.setAp(ap);

    // warp to 1_700_086_400 block.timestamp
    vm.warp(1_700_086_400);

    vm.startPrank(address(poolRouter));
    tradeMiningManager.onDecreasePosition(
      ALICE, 0, address(0), address(0), 100 * 10 ** 30, true
    );
    vm.stopPrank();

    assertEq(ap.balanceOf(ALICE), 0);
  }

  function testRevert_WhenCalledByNonWhitelisted() external {
    vm.startPrank(address(orderbook));
    vm.expectRevert(
      abi.encodeWithSignature("TradeMiningManager_NotWhitelisted()")
    );
    tradeMiningManager.onDecreasePosition(
      ALICE, 0, address(0), address(0), 100 * 10 ** 30, true
    );
    vm.stopPrank();
  }
}
