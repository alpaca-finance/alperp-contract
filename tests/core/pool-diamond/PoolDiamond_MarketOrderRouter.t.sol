// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
  PoolDiamond_BaseTest,
  console,
  LibPoolConfigV1,
  LiquidityFacetInterface,
  GetterFacetInterface,
  PerpTradeFacetInterface,
  FastPriceFeed
} from "./PoolDiamond_BaseTest.t.sol";

contract PoolDiamond_MarketOrderRouter is PoolDiamond_BaseTest {
  function setUp() public override {
    super.setUp();

    (
      address[] memory tokens2,
      LibPoolConfigV1.TokenConfig[] memory tokenConfigs2
    ) = buildDefaultSetTokenConfigInput2();

    // Config tokens
    poolAdminFacet.setTokenConfigs(tokens2, tokenConfigs2);

    // Set PythPriceFeed as a secondary price feed
    poolOracle.setSecondaryPriceFeed(address(pythPriceFeed));
    poolOracle.setIsSecondaryPriceEnabled(true);

    // Turn off favorRefPrice on PythPriceFeed
    pythPriceFeed.setFavorRefPrice(false);
  }

  function testRevert_CreateIncreasePosition_WithInsufficientExecutionFee()
    external
  {
    address[] memory path = new address[](1);
    path[0] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InsufficientExecutionFee()"));
    marketOrderRouter.createIncreasePosition{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _amountIn: 22500,
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0 ether
    });
  }

  function testRevert_CreateIncreasePosition_WithIncorrectValueTransferred()
    external
  {
    address[] memory path = new address[](1);
    path[0] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("IncorrectValueTransferred()"));
    marketOrderRouter.createIncreasePosition{value: 0.001 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _amountIn: 22500,
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0.01 ether
    });
  }

  function testRevert_IncreasePosition_WithInvalidPathLength() external {
    address[] memory path = new address[](3);
    path[0] = address(wbtc);
    path[1] = address(wbtc);
    path[2] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InvalidPathLength()"));
    marketOrderRouter.createIncreasePosition{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _amountIn: 22500,
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0.01 ether
    });
  }

  function testRevert_CreateIncreasePositionNative_WithInsufficientExecutionFee(
  ) external {
    address[] memory path = new address[](1);
    path[0] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InsufficientExecutionFee()"));
    marketOrderRouter.createIncreasePositionNative{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0 ether
    });
  }

  function testRevert_CreateIncreasePositionNative_WithIncorrectValueTransferred(
  ) external {
    address[] memory path = new address[](1);
    path[0] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("IncorrectValueTransferred()"));
    marketOrderRouter.createIncreasePositionNative{value: 0.001 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0.01 ether
    });
  }

  function testRevert_IncreasePositionNative_WithInvalidPathLength() external {
    address[] memory path = new address[](3);
    path[0] = address(weth);
    path[1] = address(wbtc);
    path[2] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InvalidPathLength()"));
    marketOrderRouter.createIncreasePositionNative{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0.01 ether
    });
  }

  function testRevert_IncreasePositionNative_WhenStartPathIsNotWrapNative()
    external
  {
    address[] memory path = new address[](2);
    path[0] = address(wbtc);
    path[1] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InvalidPath()"));
    marketOrderRouter.createIncreasePositionNative{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0.01 ether
    });
  }

  function testRevert_CreateDecreasePosition_WithInsufficientExecutionFee()
    external
  {
    address[] memory path = new address[](1);
    path[0] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InsufficientExecutionFee()"));
    marketOrderRouter.createDecreasePosition{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _collateralDelta: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _receiver: address(this),
      _acceptablePrice: 41_001 * 10 ** 30,
      _minOut: 0,
      _executionFee: 0 ether,
      _withdrawETH: false
    });
  }

  function testRevert_CreateDecreasePosition_WithIncorrectValueTransferred()
    external
  {
    address[] memory path = new address[](1);
    path[0] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("IncorrectValueTransferred()"));
    marketOrderRouter.createDecreasePosition{value: 0.001 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _collateralDelta: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _receiver: address(this),
      _acceptablePrice: 41_001 * 10 ** 30,
      _minOut: 0,
      _executionFee: 0.01 ether,
      _withdrawETH: false
    });
  }

  function testRevert_CreateDecreasePosition_WithInvalidPathLength() external {
    address[] memory path = new address[](3);
    path[0] = address(wbtc);
    path[1] = address(wbtc);
    path[2] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InvalidPathLength()"));
    marketOrderRouter.createDecreasePosition{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _collateralDelta: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _receiver: address(this),
      _acceptablePrice: 41_001 * 10 ** 30,
      _minOut: 0,
      _executionFee: 0.01 ether,
      _withdrawETH: false
    });
  }

  function testRevert_CreateDecreasePosition_WhenWithdrawETHIsTrue_WhenLastPathIsNotWNative(
  ) external {
    address[] memory path = new address[](2);
    path[0] = address(wbtc);
    path[1] = address(wbtc);
    vm.expectRevert(abi.encodeWithSignature("InvalidPath()"));
    marketOrderRouter.createDecreasePosition{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _collateralDelta: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _receiver: address(this),
      _acceptablePrice: 41_001 * 10 ** 30,
      _minOut: 0,
      _executionFee: 0.01 ether,
      _withdrawETH: true
    });
  }

  function testCorrectness_WhenLong_WithNoSwap_WithoutDepositFee() external {
    bnbPriceFeed.setLatestAnswer(400 * 10 ** 8);
    daiPriceFeed.setLatestAnswer(1 * 10 ** 8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10 ** 8);

    wbtc.mint(ALICE, 1 * 10 ** 8);

    // ----- Start Alice session -----
    vm.deal(ALICE, 100 ether);
    vm.startPrank(ALICE);

    // Alice add liquidity with 117499 satoshi
    wbtc.approve(address(poolRouter), 117499);
    alp.approve(address(poolRouter), type(uint256).max);
    // Warp +1sec to make sure pyth prices updated
    vm.warp(block.timestamp + 1);
    poolRouter.addLiquidity{value: 0.04 ether}(
      address(wbtc),
      117499,
      ALICE,
      0,
      buildPythUpdateData(41_000 * 1e8, 400 * 1e8, 1_900 * 1e8, 1 * 1e8)
    );

    // After Alice added 117499 satoshi as a liquidity,
    // the following conditions should be met:
    // 1. Alice should get 48.02986 ALP
    // 2. Pool should make 353 sathoshi
    // 3. Pool's AUM by min price should be:
    // 0.00117499 * (1-0.003) * 41000 = 48.02986 USD
    // 4. Pool's AUM by max price should be:
    // 0.00117499 * (1-0.003) * 41000 = 48.02986 USD
    // 5. WBTC's USD debt should be 48.8584 USD
    // 6. WBTC's liquidity should be 117499 - 353 = 117146 satoshi
    // 7. Redeemable WBTC in USD should be 48.8584 USD
    assertEq(
      poolGetterFacet.alp().balanceOf(address(ALICE)), 48.02986 * 10 ** 18
    );
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 353);
    assertEq(poolGetterFacet.getAumE18(false), 48.02986 * 10 ** 18);
    assertEq(poolGetterFacet.getAumE18(true), 48.02986 * 10 ** 18);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 48.02986 * 10 ** 18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 117146);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      48.02986 * 10 ** 30
    );

    // Alice add liquidity again with 117499 satoshi
    wbtc.approve(address(poolRouter), 117499);
    // Warp +1sec to make sure pyth prices updated
    vm.warp(block.timestamp + 1);
    poolRouter.addLiquidity{value: 0.04 ether}(
      address(wbtc),
      117499,
      ALICE,
      0,
      buildPythUpdateData(41_000 * 1e8, 400 * 1e8, 1_900 * 1e8, 1 * 1e8)
    );

    // After Alice added 117499 satoshi as a liquidity,
    // the following conditions should be met:
    // 1. Alice Contract should get 96.05972 ALP
    // 2. Pool should make 706 sathoshi
    // 3. Pool's AUM by min price should be:
    // 46.8584 + (0.00117499 * (1-0.003) * 41000) = 96.05972 USD
    // 4. Pool's AUM by max price should be:
    // 48.02986 + (0.00117499 * (1-0.003) * 41000) = 96.05972 USD
    // 5. WBTC's USD debt should be 96.05972 USD
    // 6. WBTC's liquidity should be 117146 + 117499 - 353 = 234292 satoshi
    // 7. Redeemable WBTC in USD should be 96.05972 USD
    assertEq(
      poolGetterFacet.alp().balanceOf(address(ALICE)), 96.05972 * 10 ** 18
    );
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 706);
    assertEq(poolGetterFacet.getAumE18(false), 96.05972 * 10 ** 18);
    assertEq(poolGetterFacet.getAumE18(true), 96.05972 * 10 ** 18);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 96.05972 * 10 ** 18);
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 234292);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      96.05972 * 10 ** 30
    );

    vm.stopPrank();

    uint256 startTime = 1669832202;
    vm.warp(startTime);
    // Alice increase long position with sub account id = 0
    vm.startPrank(ALICE);
    wbtc.approve(address(marketOrderRouter), 22500);
    poolAccessControlFacet.allowPlugin(address(marketOrderRouter));
    address[] memory path = new address[](1);
    path[0] = address(wbtc);
    bytes32 requestKey = marketOrderRouter.createIncreasePosition{
      value: 0.01 ether
    }({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _amountIn: 22500,
      _minOut: 0,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _acceptablePrice: 41_001 * 10 ** 30,
      _executionFee: 0.01 ether
    });
    vm.stopPrank();

    {
      // Avoid Stack-Too-Deep
      (
        address actualAccount,
        uint256 actualSubAccountId,
        address actualIndexToken,
        uint256 actualAmountIn,
        uint256 actualMinOut,
        uint256 actualSizeDelta,
        bool actualIsLong,
        uint256 actualAcceptablePrice,
        uint256 actualExecutionFee,
        uint256 actualBlockNumber,
        uint256 actualBlockTime,
        bool actualHasCollateralInETH
      ) = marketOrderRouter.increasePositionRequests(requestKey);

      assertEq(actualAccount, address(ALICE));
      assertEq(actualSubAccountId, 0);
      assertEq(actualIndexToken, address(wbtc));
      assertEq(actualAmountIn, 22500);
      assertEq(actualMinOut, 0);
      assertEq(actualSizeDelta, 47 * 10 ** 30);
      assertTrue(actualIsLong);
      assertEq(actualAcceptablePrice, 41_001 * 10 ** 30);
      assertEq(actualExecutionFee, 0.01 ether);
      assertEq(actualBlockNumber, block.number);
      assertEq(actualBlockTime, block.timestamp);
      assertFalse(actualHasCollateralInETH);
    }

    {
      // Avoid Stack-Too-Deep
      address[] memory actualPath =
        marketOrderRouter.getIncreasePositionRequestPath(requestKey);
      assertEq(actualPath[0], path[0]);
    }

    // Set delay values for execution validation
    marketOrderRouter.setDelayValues({
      _minBlockDelayKeeper: 0,
      _minTimeDelayPublic: 3 minutes,
      _maxTimeDelay: 30 minutes
    });

    // Execute Alice's order
    (, uint256 increaseQueueEndIndex,, uint256 decreaseQueueEndIndex) =
      marketOrderRouter.getRequestQueueLengths();

    // Execute Alice's order by MarketOrderExecutor
    address[] memory feedTokens = new address[](1);
    feedTokens[0] = address(wbtc);
    uint256[] memory feedPrices = new uint256[](1);
    feedPrices[0] = 41_000 * 10 ** 30;
    marketOrderExecutor.execute(
      increaseQueueEndIndex,
      decreaseQueueEndIndex,
      new bytes[](1),
      feedTokens,
      feedPrices,
      payable(BOB)
    );

    // Feed price here again so price not stale
    pyth.updatePriceFeeds{value: 0.04 ether}(
      buildPythUpdateData(41_000 * 1e8, 400 * 1e8, 1_800 * 1e8, 1 * 18)
    );

    // Bob should receive 0.01 ether as execution fee
    assertEq(BOB.balance, 0.01 ether);

    // The following condition expected to be happened:
    // 1. Pool's WBTC liquidity should be:
    // = 234292 + 22500 - (((47 * 0.001) + (47 * 0)) / 41000)
    // = 234292 + 22500 - 114 = 256678 sathoshi
    // 2. Pool's WBTC reserved should be:
    // = 47 / 41000 = 114634 sathoshi
    // 3. Pool's WBTC guarantee USD should be:
    // = 47 + 0.047 - ((22500 / 1e8) * 41000) = 37.822 USD
    // 4. Redeemable WBTC in USD should be:
    // = ((256678 + 92248 - 114634) / 1e8) * 41000 = 96.05972 USD
    // 5. Pool's AUM by min price should be:
    // 37.822 + ((256678 - 114634) / 1e8) * 41000 = 96.06004 USD
    // 6. Pool's AUM by max price should be:
    // 37.822 + ((256678 - 114634) / 1e8) * 41000 = 96.06004 USD
    // 7. Pool should makes 706 + 114 = 820 sathoshi
    // 8. Pool's WBTC USD debt should still the same as before
    // 9. Pool's WBTC balance should be:
    // = 256678 + 820 = 257498 sathoshi
    assertEq(poolGetterFacet.liquidityOf(address(wbtc)), 256678);
    assertEq(poolGetterFacet.reservedOf(address(wbtc)), 114634);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(wbtc)), 37.822 * 10 ** 30);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(wbtc)),
      96.05972 * 10 ** 30
    );
    assertEq(poolGetterFacet.getAumE18(false), 96.06004 * 10 ** 18);
    assertEq(poolGetterFacet.getAumE18(true), 96.06004 * 10 ** 18);
    assertEq(poolGetterFacet.feeReserveOf(address(wbtc)), 820);
    assertEq(poolGetterFacet.usdDebtOf(address(wbtc)), 96.05972 * 10 ** 18);
    assertEq(wbtc.balanceOf(address(poolDiamond)), 257498);

    // Assert a postion
    // 1. Position's size should be 47 USD
    // 2. Position's collateral should be:
    // = ((22500 / 1e8) * 41000) - 0.047 = 9.178 USD
    // 3. Position's average price should be 41000 USD
    GetterFacetInterface.GetPositionReturnVars memory position = poolGetterFacet
      .getPositionWithSubAccountId(ALICE, 0, address(wbtc), address(wbtc), true);
    assertEq(position.size, 47 * 10 ** 30);
    assertEq(position.collateral, 9.178 * 10 ** 30);
    assertEq(position.averagePrice, 41000 * 10 ** 30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 114634);
    assertEq(position.realizedPnl, 0);
    assertTrue(position.hasProfit == true);
    assertEq(position.lastIncreasedTime, block.timestamp);

    vm.startPrank(ALICE);
    marketOrderRouter.createDecreasePosition{value: 0.01 ether}({
      _subAccountId: 0,
      _path: path,
      _indexToken: address(wbtc),
      _collateralDelta: position.collateral,
      _sizeDelta: 47 * 10 ** 30,
      _isLong: true,
      _receiver: address(ALICE),
      _acceptablePrice: 44_000 * 10 ** 30,
      _minOut: 0,
      _executionFee: 0.01 ether,
      _withdrawETH: false
    });
    vm.stopPrank();
    // ----- Stop Alice session ------

    uint256 aliceWBTCBalanceBefore = wbtc.balanceOf(ALICE);

    // Execute Alice's order
    (, increaseQueueEndIndex,, decreaseQueueEndIndex) =
      marketOrderRouter.getRequestQueueLengths();

    vm.warp(block.timestamp + 1000);
    feedTokens = new address[](1);
    feedTokens[0] = address(wbtc);
    feedPrices = new uint256[](1);
    feedPrices[0] = 45_000 * 10 ** 30;
    marketOrderExecutor.execute(
      increaseQueueEndIndex,
      decreaseQueueEndIndex,
      new bytes[](1),
      feedTokens,
      feedPrices,
      payable(BOB)
    );

    // Bob should receive another 0.01 ether as execution fee
    assertEq(BOB.balance, 0.02 ether);

    position = poolGetterFacet.getPositionWithSubAccountId(
      ALICE, 0, address(wbtc), address(wbtc), true
    );
    // Position should be closed
    assertEq(position.collateral, 0, "Alice position should be closed");
    assertGt(
      wbtc.balanceOf(ALICE) - aliceWBTCBalanceBefore,
      22500,
      "Alice should receive collateral and profit."
    );
  }

  function testCorrectness_WhenShort_WithNoSwap_WithoutDepositFee() external {
    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10 ** 8);
    wbtcPriceFeed.setLatestAnswer(60_000 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(1000 * 10 ** 8);

    // Set mintBurnFeeBps to 4 BPS
    poolAdminFacet.setMintBurnFeeBps(4);

    // Mint 1,000 DAI to Alice
    dai.mint(ALICE, 1000 * 10 ** 18);

    // --- Start Alice session --- //
    vm.deal(ALICE, 100 ether);
    vm.startPrank(ALICE);

    // Alice performs add liquidity by a 500 DAI
    dai.approve(address(poolRouter), 500 * 10 ** 18);
    alp.approve(address(poolRouter), type(uint256).max);
    poolRouter.addLiquidity{value: 0.04 ether}(
      address(dai),
      500 * 10 ** 18,
      ALICE,
      0,
      buildPythUpdateData(41_000 * 1e8, 400 * 1e8, 1_800 * 1e8, 1 * 1e8)
    );

    // The following conditions need to be met:
    // 1. Pool's DAI liquidity should be 500 * (1-0.0004) = 499.8 DAI
    // 2. Pool should make 0.2 DAI in fee
    // 3. Pool's DAI usd debt should be 499.8 USD
    // 4. Redemptable DAI collateral should be 499.8 USD
    // 5. Pool's AUM by min price should be 499.8 USD
    // 6. Pool's AUM by max price should be 499.8 USD
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 499.8 * 10 ** 18);
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 0.2 * 10 ** 18);
    assertEq(poolGetterFacet.usdDebtOf(address(dai)), 499.8 * 10 ** 18);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(dai)), 499.8 * 10 ** 30
    );
    assertEq(poolGetterFacet.getAumE18(false), 499.8 * 10 ** 18);
    assertEq(poolGetterFacet.getAumE18(true), 499.8 * 10 ** 18);

    vm.stopPrank();
    // ---- Stop Alice session ---- //

    // ---- Start Alice session ---- //
    vm.startPrank(ALICE);
    // Alice opens a 90 USD WBTC short position with 20 DAI as a collateral
    dai.approve(address(marketOrderRouter), 20 * 10 ** 18);
    poolAccessControlFacet.allowPlugin(address(marketOrderRouter));
    address[] memory path = new address[](1);
    path[0] = address(dai);
    bytes32 requestKey = marketOrderRouter.createIncreasePosition{
      value: 0.01 ether
    }({
      _subAccountId: 1,
      _path: path,
      _indexToken: address(wbtc),
      _amountIn: 20 * 10 ** 18,
      _minOut: 0,
      _sizeDelta: 90 * 10 ** 30,
      _isLong: false,
      _acceptablePrice: 39_999 * 10 ** 30,
      _executionFee: 0.01 ether
    });
    vm.stopPrank();

    {
      // Avoid Stack-Too-Deep
      (
        address actualAccount,
        uint256 actualSubAccountId,
        address actualIndexToken,
        uint256 actualAmountIn,
        uint256 actualMinOut,
        uint256 actualSizeDelta,
        bool actualIsLong,
        uint256 actualAcceptablePrice,
        uint256 actualExecutionFee,
        uint256 actualBlockNumber,
        uint256 actualBlockTime,
        bool actualHasCollateralInETH
      ) = marketOrderRouter.increasePositionRequests(requestKey);

      assertEq(actualAccount, address(ALICE));
      assertEq(actualSubAccountId, 1);
      assertEq(actualIndexToken, address(wbtc));
      assertEq(actualAmountIn, 20 * 10 ** 18);
      assertEq(actualMinOut, 0);
      assertEq(actualSizeDelta, 90 * 10 ** 30);
      assertFalse(actualIsLong);
      assertEq(actualAcceptablePrice, 39_999 * 10 ** 30);
      assertEq(actualExecutionFee, 0.01 ether);
      assertEq(actualBlockNumber, block.number);
      assertEq(actualBlockTime, block.timestamp);
      assertFalse(actualHasCollateralInETH);
    }

    {
      // Avoid Stack-Too-Deep
      address[] memory actualPath =
        marketOrderRouter.getIncreasePositionRequestPath(requestKey);
      assertEq(actualPath[0], path[0]);
    }

    // Set delay values for execution validation
    marketOrderRouter.setDelayValues({
      _minBlockDelayKeeper: 0,
      _minTimeDelayPublic: 3 minutes,
      _maxTimeDelay: 30 minutes
    });

    // Execute Alice's order
    (, uint256 increaseQueueEndIndex,,) =
      marketOrderRouter.getRequestQueueLengths();
    address[] memory tokens_ = new address[](1);
    tokens_[0] = address(wbtc);
    uint256[] memory prices_ = new uint256[](1);
    prices_[0] = 40_000 * 10 ** 30;
    marketOrderExecutor.execute(
      increaseQueueEndIndex, 0, new bytes[](1), tokens_, prices_, payable(BOB)
    );
    // Bob should receive 0.01 ether as execution fee
    assertEq(BOB.balance, 0.01 ether);

    // The following conditions need to be met:
    // 1. Pool's DAI liquidity should be the same.
    // 2. Pool's DAI USD debt should be the same.
    // 2. Pool's DAI reserved should be 90 DAI
    // 3. Pool's guaranteed USD should be 0
    // 4. Redemptable DAI collateral should be 499.8 USD (same as liquidity)
    // 5. Pool should makes 0.2 + ((90 * 0.001)) = 0.29 DAI
    assertEq(poolGetterFacet.liquidityOf(address(dai)), 499.8 * 10 ** 18);
    assertEq(poolGetterFacet.usdDebtOf(address(dai)), 499.8 * 10 ** 18);
    assertEq(poolGetterFacet.reservedOf(address(dai)), 90 * 10 ** 18);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(dai)), 0 * 10 ** 18);
    assertEq(
      poolGetterFacet.getRedemptionCollateralUsd(address(dai)), 499.8 * 10 ** 30
    );
    assertEq(poolGetterFacet.feeReserveOf(address(dai)), 0.29 * 10 ** 18);
    assertEq(poolGetterFacet.shortSizeOf(address(wbtc)), 90 * 10 ** 30);
    assertEq(
      poolGetterFacet.shortAveragePriceOf(address(wbtc)), 40_000 * 10 ** 30
    );

    // Assert a position:
    // 1. Position's size should be 90
    // 2. Position's collateral should be 20 - (90 * 0.001) = 19.91 DAI
    // 3. Position's averagePrice should be 40,000 USD
    // 4. Position's entry funding rate should be 0
    // 5. Position's reserve amount should be 90 DAI
    // 6. Position should be in profit
    // 7. Position's lastIncreasedTime should be block.timestamp
    GetterFacetInterface.GetPositionReturnVars memory position = poolGetterFacet
      .getPositionWithSubAccountId(ALICE, 1, address(dai), address(wbtc), false);
    assertEq(position.size, 90 * 10 ** 30);
    assertEq(position.collateral, 19.91 * 10 ** 30);
    assertEq(position.averagePrice, 40_000 * 10 ** 30);
    assertEq(position.entryFundingRate, 0);
    assertEq(position.reserveAmount, 90 * 10 ** 18);
    assertTrue(position.hasProfit);
    assertEq(position.lastIncreasedTime, block.timestamp);

    // Make WBTC price pump to 41_000 USD
    vm.roll(block.number + 1);
    vm.warp(block.timestamp + 1);
    pyth.updatePriceFeeds{value: 0.04 ether}(
      buildPythUpdateData(41_000 * 1e8, 400 * 1e8, 1_800 * 1e8, 1 * 1e8)
    );

    console.log(poolOracle.getMaxPrice(address(wbtc)));

    // Assert pool's short delta
    // 1. Pool's delta should be (90 * (40000 - 41000)) / 40000 = -2.25 USD
    // 2. Pool's short should be not profitable
    (bool isProfit, uint256 delta) =
      poolGetterFacet.getPoolShortDelta(address(wbtc));
    assertFalse(isProfit);
    assertEq(delta, 2.25 * 10 ** 30);

    // Assert position's delta
    // 1. Position's delta should be (90 * (40000 - 41000)) / 40000 = -2.25 USD
    // 2. Position's short should be not profitable
    (isProfit, delta,) = poolGetterFacet.getPositionDelta(
      ALICE, 1, address(dai), address(wbtc), false
    );
    assertFalse(isProfit);
    assertEq(delta, 2.25 * 10 ** 30);

    // Make WBTC price pump to 42,000 USD
    vm.roll(block.number + 1);
    vm.warp(block.timestamp + 1);
    pyth.updatePriceFeeds{value: 0.04 ether}(
      buildPythUpdateData(42_000 * 1e8, 400 * 1e8, 1_800 * 1e8, 1 * 1e8)
    );

    vm.startPrank(ALICE);

    // Assert pool's short delta
    // 1. Pool's delta should be (90 * (40000 - 42000)) / 40000 = -4.5 USD
    // 2. Pool's short should be not profitable
    (isProfit, delta) = poolGetterFacet.getPoolShortDelta(address(wbtc));
    assertFalse(isProfit);
    assertEq(delta, 4.5 * 10 ** 30);

    // Assert position's delta
    // 1. Position's delta should be (90 * (40000 - 42000)) / 40000 = -4.5 USD
    // 2. Position's short should be not profitable
    (isProfit, delta,) = poolGetterFacet.getPositionDelta(
      ALICE, 1, address(dai), address(wbtc), false
    );
    assertFalse(isProfit);
    assertEq(delta, 4.5 * 10 ** 30);

    marketOrderRouter.createDecreasePosition{value: 0.01 ether}({
      _subAccountId: 1,
      _path: path,
      _indexToken: address(wbtc),
      _collateralDelta: position.collateral,
      _sizeDelta: 90 * 10 ** 30,
      _isLong: false,
      _receiver: address(ALICE),
      _acceptablePrice: 40_000 * 10 ** 30,
      _minOut: 0,
      _executionFee: 0.01 ether,
      _withdrawETH: false
    });
    vm.stopPrank();

    // Make WBTC price dump to 39_000 USD
    vm.roll(block.number + 1);
    vm.warp(block.timestamp + 1);
    pyth.updatePriceFeeds{value: 0.04 ether}(
      buildPythUpdateData(39_000 * 1e8, 400 * 1e8, 1_800 * 1e8, 1 * 1e8)
    );

    uint256 aliceDAIBalanceBefore = dai.balanceOf(ALICE);

    // Execute Alice's order
    (,,, uint256 decreaseQueueEndIndex) =
      marketOrderRouter.getRequestQueueLengths();
    address[] memory feedTokens = new address[](1);
    feedTokens[0] = address(wbtc);
    uint256[] memory feedPrices = new uint256[](1);
    feedPrices[0] = 39_000 * 1e30;
    marketOrderExecutor.execute(
      0,
      decreaseQueueEndIndex,
      new bytes[](1),
      feedTokens,
      feedPrices,
      payable(BOB)
    );

    // Bob should receive another 0.01 ether as execution fee
    assertEq(BOB.balance, 0.02 ether);

    position = poolGetterFacet.getPositionWithSubAccountId(
      ALICE, 1, address(wbtc), address(wbtc), true
    );
    // Position should be closed
    assertEq(position.collateral, 0, "Alice position should be closed");
    assertGt(
      dai.balanceOf(ALICE) - aliceDAIBalanceBefore,
      20 * 10 ** 18,
      "Alice should receive collateral and profit."
    );
  }
}
