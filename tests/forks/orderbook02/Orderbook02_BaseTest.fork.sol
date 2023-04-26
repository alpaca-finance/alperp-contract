// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Alperp Test
import {
  ForkBaseTest,
  PythPriceFeed,
  PoolRouter04,
  Orderbook02,
  Paradeen,
  AP,
  FakePyth,
  IPyth,
  PoolOracle,
  console,
  Orderbook02,
  FakePyth
} from "@alperp-tests/forks/base/ForkBaseTest.sol";

contract Orderbook02_BaseForkTest is ForkBaseTest {
  function setUp() public virtual {
    vm.createSelectFork(vm.envString("BSC_MAINNET_RPC"), 27684705);
  }
}
