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
    poolOracle.setSecondaryPriceFeed(address(pythPriceFeed));
  }

  function testCorrectness_Claim() public {
    // Warp to start of a week
    vm.warp(1680739200);

    // Trade
    // Market trade
    //   function increasePosition(
    //   uint256 subAccountId,
    //   address tokenIn,
    //   address collateralToken,
    //   uint256 amountIn,
    //   uint256 minAmountOut,
    //   address indexToken,
    //   uint256 sizeDelta,
    //   bool isLong,
    //   uint256 acceptablePrice,
    //   bytes[] calldata _priceUpdateData
    // )
    poolRouter04.increasePosition(
      0,
      WBNB_TOKEN,
      WBNB_TOKEN,
      1 ether,
      0,
      WBNB_TOKEN,
      30_000 * 10 ** 30,
      true,
      316 * 10 ** 30,
      new bytes[](0)
    );

    // Limit trade

    // Check AP balance

    // Warp to end of a week

    // Claim
  }
}
