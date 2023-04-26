// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Alperp Tests
import {
  TradeMining_BaseForkTest,
  PythPriceFeed,
  IPyth,
  FakePyth,
  Orderbook02
} from "@alperp-tests/forks/trade-mining/TradeMining_BaseTest.fork.sol";

/// Forge
import {StdStorage, stdStorage} from "@forge-std/StdStorage.sol";

contract TradeMining_ClaimForkTest is TradeMining_BaseForkTest {
  using stdStorage for StdStorage;

  FakePyth internal fakePyth;

  function setUp() public override {
    super.setUp();

    // Deploy MockPyth to alter price easily
    fakePyth = new FakePyth(86400, 1);
    bytes[] memory pythUpdateData = new bytes[](5);
    pythUpdateData[0] = fakePyth.createPriceFeedUpdateData(
      BTCB_PYTH_PRICE_ID,
      30_000 * 10 ** 8,
      0,
      -8,
      30_000 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[1] = fakePyth.createPriceFeedUpdateData(
      BNB_PYTH_PRICE_ID,
      330 * 10 ** 8,
      0,
      -8,
      330 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[2] = fakePyth.createPriceFeedUpdateData(
      ETH_PYTH_PRICE_ID,
      2_000 * 10 ** 8,
      0,
      -8,
      2_000 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[3] = fakePyth.createPriceFeedUpdateData(
      USDT_PYTH_PRICE_ID,
      1 * 10 ** 8,
      0,
      -8,
      1 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[4] = fakePyth.createPriceFeedUpdateData(
      USDC_PYTH_PRICE_ID,
      1 * 10 ** 8,
      0,
      -8,
      1 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    fakePyth.updatePriceFeeds{value: 5}(pythUpdateData);
    // Deploy a new PythPriceFeed
    PythPriceFeed pythPriceFeed = deployPythPriceFeed(address(fakePyth));
    pythPriceFeed.setMaxPriceAge(120);
    // Set up new PythPriceFeed
    pythPriceFeed.setUpdater(POOL_ROUTER_04, true);
    pythPriceFeed.setUpdater(ORDER_BOOK, true);
    // Set token price id
    pythPriceFeed.setTokenPriceId(address(forkBtcb), BTCB_PYTH_PRICE_ID);
    pythPriceFeed.setTokenPriceId(address(forkWbnb), BNB_PYTH_PRICE_ID);
    pythPriceFeed.setTokenPriceId(address(forkEth), ETH_PYTH_PRICE_ID);
    pythPriceFeed.setTokenPriceId(address(forkUsdt), USDT_PYTH_PRICE_ID);
    pythPriceFeed.setTokenPriceId(address(forkUsdc), USDC_PYTH_PRICE_ID);
    // Set new PythPriceFeed to Alperp
    vm.prank(DEPLOYER, DEPLOYER);
    forkPoolOracle.setSecondaryPriceFeed(address(pythPriceFeed));
    // Upgrade PoolRouter04
    upgrade(address(forkPoolRouter04), "PoolRouter04");
    upgrade(address(forkOrderBook02), "Orderbook02");
    vm.prank(DEPLOYER, DEPLOYER);
    forkPoolRouter04.setOraclePriceUpdater(pythPriceFeed);
  }

  function testCorrectness_Claim() public {
    // Motherload WBNB
    motherload(address(forkWbnb), address(this), 100_000_000 ether);

    // Warp to start of a week
    vm.warp(1680739200);

    // Trade
    // Build pyth update data
    bytes[] memory pythUpdateData = new bytes[](5);
    pythUpdateData[0] = fakePyth.createPriceFeedUpdateData(
      BTCB_PYTH_PRICE_ID,
      30_000 * 10 ** 8,
      0,
      -8,
      30_000 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[1] = fakePyth.createPriceFeedUpdateData(
      BNB_PYTH_PRICE_ID,
      330 * 10 ** 8,
      0,
      -8,
      330 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[2] = fakePyth.createPriceFeedUpdateData(
      ETH_PYTH_PRICE_ID,
      2_000 * 10 ** 8,
      0,
      -8,
      2_000 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[3] = fakePyth.createPriceFeedUpdateData(
      USDT_PYTH_PRICE_ID,
      1 * 10 ** 8,
      0,
      -8,
      1 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData[4] = fakePyth.createPriceFeedUpdateData(
      USDC_PYTH_PRICE_ID,
      1 * 10 ** 8,
      0,
      -8,
      1 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    // Market trade
    forkPoolAccessControlFacet.allowPlugin(address(forkPoolRouter04));
    forkWbnb.approve(address(forkPoolRouter04), type(uint256).max);
    forkPoolRouter04.increasePosition{value: 5}(
      0,
      WBNB_TOKEN,
      WBNB_TOKEN,
      10 ether,
      0,
      WBNB_TOKEN,
      30_000 * 10 ** 30,
      true,
      330 * 10 ** 30,
      pythUpdateData
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
      Orderbook02.CreateIncreaseOrderParams({
        subAccountId: 0,
        path: path,
        amountIn: 10 ether,
        indexToken: address(forkWbnb),
        minOut: 0,
        sizeDelta: 30_000 * 10 ** 30,
        collateralToken: address(forkWbnb),
        isLong: true,
        triggerPrice: 314 * 10 ** 30,
        triggerAboveThreshold: true,
        executionFee: forkOrderBook02.minExecutionFee(),
        shouldWrap: false,
        pythUpdateData: zeroBytesArr()
      })
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
