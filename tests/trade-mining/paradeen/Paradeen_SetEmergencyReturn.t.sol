// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Paradeen_BaseTest} from
  "@alperp-tests/trade-mining/paradeen/Paradeen_BaseTest.t.sol";

contract Paradeen_SetEmergencyReturn is Paradeen_BaseTest {
  function setUp() public override {
    super.setUp();
  }

  function testCorrectness_WhenCalledByOwner() public {
    paradeen.setEmergencyReturn(DAVE);
    assertEq(paradeen.emergencyReturn(), DAVE);
  }

  function testRevert_WhenCalledByRandomAccount() external {
    vm.startPrank(ALICE, ALICE);
    vm.expectRevert("Ownable: caller is not the owner");
    paradeen.setEmergencyReturn(DAVE);
    vm.stopPrank();
  }
}
