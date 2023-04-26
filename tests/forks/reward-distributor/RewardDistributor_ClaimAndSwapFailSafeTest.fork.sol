// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
  RewardDistributor_BaseForkTest,
  console2
} from
  "@alperp-tests/forks/reward-distributor/RewardDistributor_BaseTest.fork.sol";

contract RewardDistributor_ClaimAndSwapFailSafeForkTest is
  RewardDistributor_BaseForkTest
{
  uint256 internal constant DUST = 10;

  function setUp() public override {
    super.setUp();
    upgrade(address(forkRewardDistributor), "RewardDistributor");
    vm.startPrank(DEPLOYER);
    forkRewardDistributor.setPythPriceFeed(forkPythPriceFeed);
    forkRewardDistributor.setRouter(forkPancakeV3Router);
    address[] memory t0s = new address[](4);
    t0s[0] = address(forkBtcb);
    t0s[1] = address(forkWbnb);
    t0s[2] = address(forkEth);
    t0s[3] = address(forkUsdc);
    address[] memory t1s = new address[](4);
    t1s[0] = address(forkUsdt);
    t1s[1] = address(forkUsdt);
    t1s[2] = address(forkUsdt);
    t1s[3] = address(forkUsdt);
    bytes[] memory paths = new bytes[](4);
    paths[0] =
      abi.encodePacked(address(forkBtcb), uint24(500), address(forkUsdt));
    paths[1] =
      abi.encodePacked(address(forkWbnb), uint24(500), address(forkUsdt));
    paths[2] = abi.encodePacked(
      address(forkEth),
      uint24(2500),
      address(forkBtcb),
      uint24(500),
      address(forkUsdt)
    );
    paths[3] =
      abi.encodePacked(address(forkUsdc), uint24(100), address(forkUsdt));
    console2.logBytes(paths[0]);
    console2.logBytes(paths[1]);
    console2.logBytes(paths[2]);
    console2.logBytes(paths[3]);
    forkRewardDistributor.setPathOf(t0s, t1s, paths);
    forkPythPriceFeed.setUpdater(address(forkRewardDistributor), true);
    vm.stopPrank();
  }

  function testCorrectness_WhenFailSafe() external {
    // Claim and swap
    address[] memory tokens = new address[](4);
    tokens[0] = address(forkBtcb);
    tokens[1] = address(forkWbnb);
    tokens[2] = address(forkEth);
    tokens[3] = address(forkUsdc);
    uint256 balanceBefore = forkUsdt.balanceOf(address(forkRewardDistributor));
    bytes[] memory zeroBytesArr_ = new bytes[](0);
    vm.prank(REWARD_KEEPER, REWARD_KEEPER);
    forkRewardDistributor.claimAndSwap(tokens, zeroBytesArr_);
    uint256 balanceAfter = forkUsdt.balanceOf(address(forkRewardDistributor));
    assertTrue(balanceAfter > balanceBefore, "USDT should increase");

    // Feed protocol revenue
    vm.prank(REWARD_KEEPER, REWARD_KEEPER);
    forkRewardDistributor.feedProtocolRevenue(1683158400, 0, 0, bytes32(0));
    assertTrue(
      forkUsdt.balanceOf(address(forkRewardDistributor)) < DUST,
      "should has only dust left"
    );
  }
}
