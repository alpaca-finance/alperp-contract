// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Alperp Tests
import {
  TradeMining_BaseForkTest,
  PythPriceFeed,
  IPyth,
  FakePyth
} from "@alperp-tests/forks/trade-mining/TradeMining_BaseTest.fork.sol";

contract TradeMining_ClaimForkTest is TradeMining_BaseForkTest {
  function setUp() public override {
    super.setUp();

    // Deploy MockPyth to alter price easily
    IPyth pyth = new FakePyth(86400, 1);
    // Deploy a new PythPriceFeed
    PythPriceFeed pythPriceFeed = deployPythPriceFeed(address(pyth));
    // Set up new PythPriceFeed
    pythPriceFeed.setUpdater(POOL_ROUTER_04, true);
    pythPriceFeed.setUpdater(ORDER_BOOK, true);
    // Set new PythPriceFeed to Alperp
    vm.prank(
      0xC44f82b07Ab3E691F826951a6E335E1bC1bB0B51,
      0xC44f82b07Ab3E691F826951a6E335E1bC1bB0B51
    );
    forkPoolOracle.setSecondaryPriceFeed(address(pythPriceFeed));
  }

  function testCorrectness_Claim() public {
    // Motherload WBNB
    motherload(address(forkWbnb), address(this), 100_000_000 ether);

    // Warp to start of a week
    vm.warp(1680739200);

    // Trade
    // Market trade
    forkPoolAccessControlFacet.allowPlugin(address(forkPoolRouter04));
    forkWbnb.approve(address(forkPoolRouter04), type(uint256).max);
    forkPoolRouter04.increasePosition(
      0,
      WBNB_TOKEN,
      WBNB_TOKEN,
      10 ether,
      0,
      WBNB_TOKEN,
      30_000 * 10 ** 30,
      true,
      316 * 10 ** 30,
      new bytes[](0)
    );

    // Assert AP balance.
    // AP balance should be 30_000 ether
    assertEq(forkAp.balanceOf(address(this)), 30_000 ether);

    // Limit trade
    forkWbnb.approve(address(forkOrderBook02), type(uint256).max);
    address[] memory path = new address[](1);
    path[0] = address(forkWbnb);
    forkOrderBook02.createIncreaseOrder{
      value: forkOrderBook02.minExecutionFee()
    }(
      0,
      path,
      10 ether,
      address(forkWbnb),
      0,
      30_000 * 10 ** 30,
      address(forkWbnb),
      true,
      314 * 10 ** 30,
      true,
      forkOrderBook02.minExecutionFee(),
      false
    );

    // Assert AP balance.
    // AP balance remains the same
    assertEq(forkAp.balanceOf(address(this)), 30_000 ether);

    // Execute order
    forkPoolAccessControlFacet.allowPlugin(address(forkOrderBook02));
    vm.prank(
      0xe45216Ac4816A5Ec5378B1D13dE8aA9F262ce9De,
      0xe45216Ac4816A5Ec5378B1D13dE8aA9F262ce9De
    );
    //   function executeIncreaseOrder(
    //   address _address,
    //   uint256 _subAccountId,
    //   uint256 _orderIndex,
    //   address payable _feeReceiver,
    //   bytes[] calldata _priceUpdateData,
    //   address[] calldata _tokens,
    //   uint256[] calldata _prices
    // ) external nonReentrant whitelisted
    address[] memory tokens = new address[](1);
    tokens[0] = address(forkWbnb);
    uint256[] memory prices = new uint256[](1);
    prices[0] = 314 * 10 ** 30;
    forkOrderBook02.executeIncreaseOrder(
      address(this),
      0,
      0,
      payable(0xe45216Ac4816A5Ec5378B1D13dE8aA9F262ce9De),
      new bytes[](1),
      tokens,
      prices
    );

    // Check AP balance
    // AP balance should be 60_000 ether
    assertEq(forkAp.balanceOf(address(this)), 60_000 ether);

    // Feed Paradeen
    // feed(uint256[] memory _timestamps, uint256[] memory _amounts)
    uint256[] memory timestamps = new uint256[](1);
    timestamps[0] = 1680739200;
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 32_000 ether;
    motherload(address(forkAlpaca), address(this), 32_000 ether);
    forkAlpaca.approve(address(forkParadeen), type(uint256).max);
    forkParadeen.feed(timestamps, amounts);

    // Warp to next week
    vm.warp(block.timestamp + 7 days);

    // Claim
    uint256 rewards = forkParadeen.claim();
    assertEq(rewards, 32_000 ether);
    assertEq(forkAlpaca.balanceOf(address(this)), 32_000 ether);
    assertEq(forkAp.balanceOf(address(this)), 0);
  }
}
