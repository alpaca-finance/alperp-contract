// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseTest, AP, Paradeen, IERC20} from "@alperp-tests/base/BaseTest.sol";

abstract contract Paradeen_BaseTest is BaseTest {
  uint256 constant WEEK = 7 days;
  Paradeen paradeen;
  AP ap;

  function setUp() public virtual {
    // Deploy related contracts
    ap = deployAP();
    paradeen = deployParadeen(address(ap), block.timestamp, address(usdc), DAVE);

    ap.setMinter(address(this), true);
  }
}
