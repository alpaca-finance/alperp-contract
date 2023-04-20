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

import {
  PoolOracle02_BaseTest,
  PoolOracle02
} from "@alperp-tests/core/pool-oracle-02/PoolOracle02_BaseTest.t.sol";

contract PoolOracle02_SetPriceFeedTest is PoolOracle02_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testRevert_WhenLenNotEqual() external {
    address[] memory tokens = new address[](2);
    tokens[0] = address(88);
    tokens[1] = address(99);

    PoolOracle02.PriceFeedInfo[] memory priceFeedInfo =
      new PoolOracle02.PriceFeedInfo[](1);
    priceFeedInfo[0] = PoolOracle02.PriceFeedInfo({
      decimals: 0,
      spreadBps: 0,
      isStrictStable: false
    });

    vm.expectRevert(abi.encodeWithSignature("PoolOracle02_BadArguments()"));
    poolOracle02.setPriceFeed(tokens, priceFeedInfo);
  }

  function testRevert_WhenRandomUserTryToSetPriceFeed() external {
    address[] memory tokens = new address[](1);
    tokens[0] = address(88);

    PoolOracle02.PriceFeedInfo[] memory priceFeedInfo =
      new PoolOracle02.PriceFeedInfo[](1);
    priceFeedInfo[0] = PoolOracle02.PriceFeedInfo({
      decimals: 0,
      spreadBps: 0,
      isStrictStable: false
    });

    vm.prank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    poolOracle02.setPriceFeed(tokens, priceFeedInfo);
  }

  function testCorrectness_WhenParamsValid() external {
    address[] memory tokens = new address[](1);
    tokens[0] = address(dai);

    PoolOracle02.PriceFeedInfo[] memory priceFeedInfo =
      new PoolOracle02.PriceFeedInfo[](1);
    priceFeedInfo[0] = PoolOracle02.PriceFeedInfo({
      decimals: 8,
      spreadBps: 10,
      isStrictStable: false
    });

    poolOracle02.setPriceFeed(tokens, priceFeedInfo);

    (uint8 decimals, uint64 spreadBps, bool isStrictStable) =
      poolOracle02.priceFeedInfo(tokens[0]);

    assertEq(decimals, 8);
    assertEq(spreadBps, 10);
    assertTrue(isStrictStable == false);
  }
}
