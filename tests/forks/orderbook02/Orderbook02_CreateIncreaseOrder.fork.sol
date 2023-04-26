// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
  Orderbook02_BaseForkTest,
  FakePyth,
  PythPriceFeed,
  Orderbook02,
  IPyth
} from "@alperp-tests/forks/orderbook02/Orderbook02_BaseTest.fork.sol";

contract Orderbook02_CreateIncreaseOrderForkTest is Orderbook02_BaseForkTest {
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
    // Upgarde PythPriceFeed
    upgrade(address(forkPythPriceFeed), "PythPriceFeed");
    // Point pyth price feed to FakePyth
    vm.prank(DEPLOYER, DEPLOYER);
    forkPythPriceFeed.setPyth(address(fakePyth));
    // Upgrade order book
    upgrade(address(forkOrderBook02), "Orderbook02");
  }

  function testCorrectness_CreateIncreaseOrder() external {
    // Trade
    // Build pyth update data
    bytes[] memory pythUpdateData_ = new bytes[](5);
    pythUpdateData_[0] = fakePyth.createPriceFeedUpdateData(
      BTCB_PYTH_PRICE_ID,
      30_000 * 10 ** 8,
      0,
      -8,
      30_000 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData_[1] = fakePyth.createPriceFeedUpdateData(
      BNB_PYTH_PRICE_ID,
      330 * 10 ** 8,
      0,
      -8,
      330 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData_[2] = fakePyth.createPriceFeedUpdateData(
      ETH_PYTH_PRICE_ID,
      2_000 * 10 ** 8,
      0,
      -8,
      2_000 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData_[3] = fakePyth.createPriceFeedUpdateData(
      USDT_PYTH_PRICE_ID,
      1 * 10 ** 8,
      0,
      -8,
      1 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );
    pythUpdateData_[4] = fakePyth.createPriceFeedUpdateData(
      USDC_PYTH_PRICE_ID,
      1 * 10 ** 8,
      0,
      -8,
      1 * 10 ** 8,
      1,
      uint64(block.timestamp)
    );

    // Limit trade
    address[] memory path = new address[](1);
    path[0] = address(forkWbnb);
    forkOrderBook02.createIncreaseOrder{
      value: forkOrderBook02.minExecutionFee() + 5 + 10 ether
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
        shouldWrap: true,
        pythUpdateData: pythUpdateData_
      })
    );
  }
}
