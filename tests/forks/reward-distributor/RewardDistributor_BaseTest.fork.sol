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
  console2
} from "@alperp-tests/forks/base/ForkBaseTest.sol";

contract RewardDistributor_BaseForkTest is ForkBaseTest {
  function setUp() public virtual {
    vm.createSelectFork(vm.envString("BSC_MAINNET_RPC"), 27676449);
  }
}
