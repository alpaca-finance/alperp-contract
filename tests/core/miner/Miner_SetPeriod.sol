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

import { Miner_BaseTest } from "./Miner_BaseTest.t.sol";

contract Miner_SetPeriod is Miner_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_SetPeriod() external {
    miner.setPeriod(1_680_000_000, 1_700_000_000);

    assertEq(miner.startTimestamp(), 1_680_000_000);
    assertEq(miner.endTimestamp(), 1_700_000_000);
  }

  function testRevert_WhenStartAfterEndTimestamp() external {
    vm.expectRevert(abi.encodeWithSignature("Miner_InvlidPeriod()"));
    miner.setPeriod(1_700_000_000, 1_680_000_000);
  }

  function testRevert_WhenCalledByNonOwner() external {
    vm.startPrank(ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    miner.setPeriod(1_680_000_000, 1_700_000_000);
    vm.stopPrank();
  }
}
