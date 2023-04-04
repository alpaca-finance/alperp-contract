// SPDX-License-Identifier: MIT
/**
 *   ∩~~~~∩
 *   ξ ･×･ ξ
 *   ξ　~　ξ
 *   ξ　　 ξ
 *   ξ　　 “~～~～〇
 *   ξ　　　　　　 ξ
 *   ξ ξ ξ~～~ξ ξ ξ
 * 　 ξ_ξξ_ξ　ξ_ξξ_ξ
 * Alpaca Fin Corporation
 */

pragma solidity 0.8.17;

import {
  PoolDiamond_BaseTest,
  console,
  LibPoolConfigV1,
  LiquidityFacetInterface,
  GetterFacetInterface,
  PerpTradeFacetInterface
} from "./PoolDiamond_BaseTest.t.sol";

contract PoolDiamond_GetFeeBpsTest is PoolDiamond_BaseTest {
  function setUp() public override {
    super.setUp();

    address[] memory tokens = new address[](1);
    tokens[0] = address(bnb);

    LibPoolConfigV1.TokenConfig[] memory tokenConfigs =
      new LibPoolConfigV1.TokenConfig[](1);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: bnb.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0,
      openInterestLongCeiling: 0
    });

    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);
  }

  function testCorrectness_GetFeeBps() external {
    // Initialized price feeds
    daiPriceFeed.setLatestAnswer(1 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(300 * 10 ** 8);
    wbtcPriceFeed.setLatestAnswer(40_000 * 10 ** 8);

    // Set Mint Burn Fee Bps to 20 BPS
    poolAdminFacet.setMintBurnFeeBps(20);

    // Turn on dynamic fee
    poolAdminFacet.setIsDynamicFeeEnable(true);

    // Add 100 wei of BNB as a liquidity
    bnb.mint(address(poolDiamond), 100);
    poolLiquidityFacet.addLiquidity(address(this), address(bnb), address(this));

    // The following conditions are expected to be true:
    // 1. Pool's BNB USD debt should be:
    // = math.trunc(100 * (1-0.002)) * 300
    // = 29700
    // 2. Pool's BNB target value should be:
    // = 29700 * 10000 / 10000
    // = 29700
    // 3. Pool's AUM should be: 29700
    uint256 aumE18 = poolGetterFacet.getAumE18(true);
    assertEq(poolGetterFacet.usdDebtOf(address(bnb)), 29700);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 29700);
    assertEq(aumE18, 29700);

    // BNB's USD value is 29700, and the target value is 29700
    // Assuming:
    // 1. mintBurnFeeBps is 100 BPS
    // 2. taxBps is 50 BPS
    poolAdminFacet.setMintBurnFeeBps(100);
    poolAdminFacet.setTaxBps(50, 50);

    // Assert with the given conditions.
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 1000), 100
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 5000), 104
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 1000), 100
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 5000), 104
    );

    // Assuming:
    // 1. mintBurnFeeBps is 50 BPS
    // 2. taxBps is 100 BPS
    poolAdminFacet.setMintBurnFeeBps(50);
    poolAdminFacet.setTaxBps(100, 100);

    // Assert with the given conditions.
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 1000), 51
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 5000), 58
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 1000), 51
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 5000), 58
    );

    // Add DAI to the allow token list
    address[] memory tokens = new address[](1);
    tokens[0] = address(dai);
    LibPoolConfigV1.TokenConfig[] memory tokenConfigs =
      new LibPoolConfigV1.TokenConfig[](1);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: dai.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0,
      openInterestLongCeiling: 0
    });
    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);

    // Assert target value.
    // 1. Pool's BNB target value should be:
    // = 29700 * 10000 / 20000
    // = 14850
    // 2. Pool's DAI target value should be:
    // = 29700 * 10000 / 20000
    // = 14850
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 14850);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 14850);

    // BNB's USD value is 29700, and the target value is 14850
    // Assuming:
    // 1. mintBurnFeeBps is 100 BPS
    // 2. taxBps is 50 BPS
    poolAdminFacet.setMintBurnFeeBps(100);
    poolAdminFacet.setTaxBps(50, 50);

    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 1000), 150
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 5000), 150
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 10000), 150
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 20000), 150
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 1000), 50
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 5000), 50
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 10000), 50
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 20000), 50
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 25000), 50
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 100000),
      150
    );

    // Assuming:
    // 1. mintBurnFeeBps is 20 BPS
    // 2. taxBps is 50 BPS
    // 3. stableTaxBps is 10 BPS
    poolAdminFacet.setMintBurnFeeBps(20);
    poolAdminFacet.setTaxBps(50, 10);

    // Add 20000 wei of DAI as a liquidity
    dai.mint(address(poolDiamond), 20000);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // Assert target value.
    aumE18 = poolGetterFacet.getAumE18(true);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 24850);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 24850);
    assertEq(poolGetterFacet.totalUsdDebt(), 49700);
    assertEq(aumE18, 49700);

    // Adjust BNB's token weight
    tokens[0] = address(bnb);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: bnb.decimals(),
      weight: 30000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0,
      openInterestLongCeiling: 0
    });
    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);

    // Assert target value
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 37275);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 12425);

    // Assert BNB's USD debt should be the same
    assertEq(poolGetterFacet.usdDebtOf(address(bnb)), 29700);

    // BNB's USD value is 29700, and the target value is 37275
    // Add more BNB to the pool, low fee
    // Remove BNB from the pool, high fee
    // Assuming:
    // 1. mintBurnFeeBps is 100 BPS
    // 2. taxBps is 50 BPS
    // 3. stableTaxBps is 10 BPS
    poolAdminFacet.setMintBurnFeeBps(100);
    poolAdminFacet.setTaxBps(50, 10);

    // Assert add liquidity fee, should be low fee
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 1000), 90
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 5000), 90
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 10000), 90
    );

    // Assert remove liquidity fee, should be high fee
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 1000), 110
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 5000), 113
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 10000), 116
    );

    // Set fee back to what it should be.
    // 1. mintBurnFeeBps is 20 BPS
    // 2. taxBps is 50 BPS
    // 3. stableTaxBps is 10 BPS
    poolAdminFacet.setMintBurnFeeBps(20);
    poolAdminFacet.setTaxBps(50, 10);

    // Reduce BNB's token weight to 5000
    tokenConfigs[0].weight = 5000;
    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);

    // Add 200 wei of BNB as a liquidity
    bnb.mint(address(poolDiamond), 200);
    poolLiquidityFacet.addLiquidity(address(this), address(bnb), address(this));

    // Assert USD debt, target value, and aum.
    aumE18 = poolGetterFacet.getAumE18(true);
    assertEq(poolGetterFacet.usdDebtOf(address(bnb)), 89100);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 36366);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 72733);
    assertEq(poolGetterFacet.totalUsdDebt(), 109100);

    // BNB's USD value is 89100, and the target value is 36366
    // Add more BNB to the pool, high fee
    // Remove BNB from the pool, low fee
    // Assuming:
    // 1. mintBurnFeeBps is 100 BPS
    // 2. taxBps is 50 BPS
    // 3. stableTaxBps is 10 BPS
    poolAdminFacet.setMintBurnFeeBps(100);
    poolAdminFacet.setTaxBps(50, 10);

    // Assert add liquidity, result in high fee
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 1000), 150
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 5000), 150
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 10000), 150
    );

    // Assert remove liquidity, result in lower fee
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 1000), 28
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 5000), 28
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 20000), 28
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 50000), 28
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 80000), 28
    );

    // Assuming:
    // 1. mintBurnFeeBps is 50 BPS
    // 2. taxBps is 100 BPS
    // 3. stableTaxBps is 10 BPS
    poolAdminFacet.setMintBurnFeeBps(50);
    poolAdminFacet.setTaxBps(100, 10);

    // Assert add liquidity, result in high fee
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 1000), 150
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 5000), 150
    );
    assertEq(
      poolGetterFacet.getAddLiquidityFeeBps(address(bnb), aumE18, 10000), 150
    );

    // Assert remove liquidity, result in lower fee
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 1000), 0
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 5000), 0
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 20000), 0
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 50000), 0
    );
    assertEq(
      poolGetterFacet.getRemoveLiquidityFeeBps(address(bnb), aumE18, 80000), 0
    );
  }

  function testCorrectness_WhenTraderPnLAffectFee() external {
    // Initialize price feeds
    daiPriceFeed.setLatestAnswer(1 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(300 * 10 ** 8);
    wbtcPriceFeed.setLatestAnswer(100_000 * 10 ** 8);

    // Add DAI to the allow token list
    address[] memory tokens = new address[](1);
    tokens[0] = address(dai);
    LibPoolConfigV1.TokenConfig[] memory tokenConfigs =
      new LibPoolConfigV1.TokenConfig[](1);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: dai.decimals(),
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0,
      openInterestLongCeiling: 0
    });
    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);

    // Set Mint Burn Fee Bps to 20 BPS
    poolAdminFacet.setMintBurnFeeBps(20);

    // Enable dynamic fee
    poolAdminFacet.setIsDynamicFeeEnable(true);

    // Add 30_000 BNB as a liquidity
    bnb.mint(address(poolDiamond), 30_000 ether);
    poolLiquidityFacet.addLiquidity(address(this), address(bnb), address(this));

    // The following conditions are expected to be true:
    // 1. Pool's BNB USD debt should be:
    // = 30000 * (1-0.002) * 300 = 8982000 USD
    // 2. Pool's BNB target value should be:
    // = 8982000 * 10000 / 20000 = 4491000 USD
    // 3. Pool's DAI target value should be:
    // = 8982000 * 10000 / 20000 = 4491000 USD
    // 4. Pool's AUM should be: 8982000 USD
    // 5. Pool's BNB liquidity should be:
    // = 30000 * (1-0.002) = 29940 BNB
    uint256 aumE18 = poolGetterFacet.getAumE18(true);
    assertEq(poolGetterFacet.usdDebtOf(address(bnb)), 8_982_000 ether);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 4_491_000 ether);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 4_491_000 ether);
    assertEq(aumE18, 8_982_000 ether);
    assertEq(poolGetterFacet.liquidityOf(address(bnb)), 29_940 ether);

    // Add 4_000_000 DAI
    dai.mint(address(poolDiamond), 4_000_000 ether);
    poolLiquidityFacet.addLiquidity(address(this), address(dai), address(this));

    // The following conditions are expected to be true:
    // 1. Pool's BNB USD debt should be:
    // = 8982000 USD
    // 2. Pool's DAI USD debt should be:
    // = 4000000 * (1-0 [Due to help pool to balance]) * 1 = 4000000 USD
    // 3. Pool's BNB target value should be:
    // = (8982000 + 4000000) * 10000 / 20000 = 6491000.0 USD
    // 4. Pool's DAI target value should be:
    // = (8982000 + 4000000) * 10000 / 20000 = 6491000.0 USD
    assertEq(poolGetterFacet.usdDebtOf(address(bnb)), 8_982_000 ether);
    assertEq(poolGetterFacet.usdDebtOf(address(dai)), 4_000_000 ether);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 6_491_000 ether);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 6_491_000 ether);
    assertEq(poolGetterFacet.getAumE18(true), 12_982_000 ether);

    // Long BNB 30_000 USD with 10 BNB as collateral.
    bnb.mint(address(poolDiamond), 10 ether);
    poolPerpTradeFacet.increasePosition(
      address(this), 0, address(bnb), address(bnb), 30_000 * 1e30, true
    );

    // The following conditions are expected to be true:
    // 1. Pool's reserved BNB should be 100 BNB
    // 2. Pool's BNB guarantee USD should be 90 * 300 + (30_000 * 0.001) = 27030.0 USD
    // 3. Pool's BNB target value should be:
    // = (((29_949.9 - 100) * 300 + 27_030) + 4000000) * 10000 / 20000
    // = 6491000.0 USD
    // 4. Pool's DAI target value should be:
    // = (((29_949.9 - 100) * 300 + 27_030) + 4000000) * 10000 / 20000
    // = 6491000.0 USD
    assertEq(poolGetterFacet.reservedOf(address(bnb)), 100 ether);
    assertEq(poolGetterFacet.guaranteedUsdOf(address(bnb)), 27030 * 1e30);
    assertEq(poolGetterFacet.liquidityOf(address(bnb)), 29_949.9 ether);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 6_491_000 ether);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 6_491_000 ether);

    // Assumming BNB price went up to 350 USD
    bnbPriceFeed.setLatestAnswer(350 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(350 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(350 * 10 ** 8);

    // The following conditions are expected to be true:
    // 1. Pool's BNB target value should be:
    // = (((29_949.9 - 100) * 350 + 27_030) + 4000000) * 10000 / 20000
    // = 7237247.5 USD
    // 2. Pool's DAI target value should be:
    // = (((29_949.9 - 100) * 350 + 27_030) + 4000000) * 10000 / 20000
    // = 7237247.5 USD
    // 3. Pool's BNB current value should be:
    // = ((29_949.9 - 100) * 350 + 27_030)
    // = 10_474_495.0 USD
    // 4. Pool's DAI current value should be:
    // = 4000000 USD
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 7_237_247.5 ether);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 7_237_247.5 ether);
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(bnb), true), 10_474_495 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(dai), true), 4_000_000 ether
    );

    // Assuming add another 1_000 BNB to the pool.
    // This action makes pool even imbalanced.
    bnb.mint(address(poolDiamond), 1_000 ether);
    poolLiquidityFacet.addLiquidity(address(this), address(bnb), address(this));

    // The following conditions are expected to be true:
    // 1. Pool's BNB liquidity should be:
    // Fee should be:
    // midDiff = ((10_474_495 - 7_237_247.5) + ((10_474_495 + (350 * 1_000)) - 7_237_247.5)) / 2
    // midDiff = 3412247.5
    // tax = 50 * 3412247.5/ 7_237_247.5 = 23
    // fee = 20 + 23 = 43
    // 29_949.9 + (1_000 * (1 - 0.0043)) = 30947.9 BNB
    // 2. Pool's BNB target value should be:
    // = (((30_945.6 - 100) * 350 + 27_030) + 4000000) * 10000 / 20000
    // = 7_411_495.0 USD
    // 3. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 350 + 27_030) + 4000000) * 10000 / 20000
    // = 7_411_495.0 USD
    assertEq(poolGetterFacet.liquidityOf(address(bnb)), 30_945.6 ether);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 7_411_495.0 ether);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 7_411_495.0 ether);

    // Assuming someone short BNB 20_000 USD with 2_000 DAI as collateral.
    dai.mint(address(poolDiamond), 2_000 ether);
    poolPerpTradeFacet.increasePosition(
      address(this), 0, address(dai), address(bnb), 20_000 * 1e30, false
    );

    // The following conditions are expected to be true:
    // 1. Pool's AUM should be:
    // = (((30_945.6 - 100) * 350 + 27_030) + 4000000)
    // = 14_822_990.0 USD
    // 2. Pool's BNB target value should be:
    // = (((30_945.6 - 100) * 350 + 27_030) + 4000000) * 10000 / 20000
    // = 7_411_495.0 USD
    // 3. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 350 + 27_030) + 4000000) * 10000 / 20000
    // = 7_411_495.0 USD
    // 4. Pool's BNB current value should be:
    // = ((30_945.6 - 100) * 350 + 27_030)
    // = 10_822_990.0 USD
    // 5. Pool's DAI current value should be:
    // = 4_000_000 USD
    assertEq(poolGetterFacet.getAumE18(true), 14_822_990 ether);
    assertEq(poolGetterFacet.getTargetValue(address(bnb)), 7_411_495.0 ether);
    assertEq(poolGetterFacet.getTargetValue(address(dai)), 7_411_495.0 ether);
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(bnb), true), 10_822_990 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(dai), true), 4_000_000 ether
    );

    // Assuming BNB price went up to 400 USD
    bnbPriceFeed.setLatestAnswer(400 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(400 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(400 * 10 ** 8);

    // The following conditions are expected to be true:
    // 1. Pool's BNB target value should be:
    // = (((30_945.6 - 100) * 400 + 27_030) + (4000000 + (20_000 * (400 - 350) / 350))) * 10000 / 20000
    // = 8_184_063.571428571428571428 USD
    // 2. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 400 + 27_030) + (4000000 + (20_000 * (400 - 350) / 350))) * 10000 / 20000
    // = 8_184_063.571428571428571428 USD
    // 3. Pool's BNB current value should be:
    // = ((30_945.6 - 100) * 400 + 27_030)
    // = 12_365_270.0 USD
    // 4. Pool's DAI current value should be:
    // = 4_000_000 + (20_000 * (400 - 350) / 350) USD
    // = 4_028_571.4285714286
    assertEq(
      poolGetterFacet.getTargetValue(address(bnb)),
      8_184_063.571428571428571428 ether
    );
    assertEq(
      poolGetterFacet.getTargetValue(address(dai)),
      8_184_063.571428571428571428 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(bnb), true), 12_365_270.0 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(dai), true),
      4_002_857.142857142857142857 ether
    );

    // Assuming short is in proft.
    // Set price to 320 USD
    bnbPriceFeed.setLatestAnswer(320 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(320 * 10 ** 8);
    bnbPriceFeed.setLatestAnswer(320 * 10 ** 8);

    // The following conditions are expected to be true:
    // 1. Pool's BNB target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350))) * 10000 / 20000
    // = 6_947_953.857142857 USD
    // 2. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350))) * 10000 / 20000
    // = 6_947_953.857142857 USD
    // 3. Pool's BNB current value should be:
    // = ((30_945.6 - 100) * 320 + 27_030)
    // = 9_897_622.0 USD
    // 4. Pool's DAI current value should be:
    // = 4_000_000 + (20_000 * (320 - 350) / 350) USD
    // = 3_998_285.714285714
    assertEq(
      poolGetterFacet.getTargetValue(address(bnb)),
      6_947_953.857142857142857142 ether
    );
    assertEq(
      poolGetterFacet.getTargetValue(address(dai)),
      6_947_953.857142857142857142 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(bnb), true), 9_897_622.0 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(dai), true),
      3_998_285.714285714285714285 ether
    );

    // Add USDC to the allow token list
    tokens = new address[](1);
    tokens[0] = address(usdc);
    tokenConfigs = new LibPoolConfigV1.TokenConfig[](1);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: usdc.decimals(),
      weight: 500,
      minProfitBps: 75,
      usdDebtCeiling: 0,
      shortCeiling: 0,
      bufferLiquidity: 0,
      openInterestLongCeiling: 0
    });
    poolAdminFacet.setTokenConfigs(tokens, tokenConfigs);

    // Feed USDC price
    usdcPriceFeed.setLatestAnswer(1 * 10 ** 8);
    usdcPriceFeed.setLatestAnswer(1 * 10 ** 8);
    usdcPriceFeed.setLatestAnswer(1 * 10 ** 8);

    // The following conditions are expected to be true:
    // 1. Pool's BNB target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350))) * 10000 / 20500
    // = 6_778_491.567944251 USD
    // 2. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350))) * 10000 / 20500
    // = 6_778_491.567944251 USD
    // 3. Pool's USDC target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350))) * 500 / 20500
    // = 338_924.57839721255 USD
    // 4. Pool's BNB current value should be:
    // = ((30_945.6 - 100) * 320 + 27_030)
    // = 9_897_622.0 USD
    // 5. Pool's DAI current value should be:
    // = 4_000_000 + ((20_000 * (320 - 350) / 350) * 20_000 / 20_000) USD
    // = 3_998_285.714285714
    assertEq(
      poolGetterFacet.getTargetValue(address(bnb)),
      6_778_491.567944250871080139 ether
    );
    assertEq(
      poolGetterFacet.getTargetValue(address(dai)),
      6_778_491.567944250871080139 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(bnb), true), 9_897_622.0 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(dai), true),
      3_998_285.714285714285714285 ether
    );

    // Add 100_000 USDC as liquidity
    usdc.mint(address(poolDiamond), 100_000 * 10 ** 6);
    poolLiquidityFacet.addLiquidity(address(this), address(usdc), address(this));

    // The following conditions are expected to be true:
    // 1. Pool's BNB target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350)) + 100_000) * 10000 / 20500
    // = 6_827_272.0557491295 USD
    // 2. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350)) + 100_000) * 10000 / 20500
    // = 6_827_272.0557491295 USD
    // 3. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350)) + 100_000) * 500 / 20500
    // = 341_363.6027874565 USD
    // 4. Pool's USDC liquidity should be:
    // = 100_000 USDC
    assertEq(
      poolGetterFacet.getTargetValue(address(bnb)),
      6_827_272.055749128919860626 ether
    );
    assertEq(
      poolGetterFacet.getTargetValue(address(dai)),
      6_827_272.055749128919860626 ether
    );
    assertEq(
      poolGetterFacet.getTargetValue(address(usdc)),
      341_363.602787456445993031 ether
    );
    assertEq(poolGetterFacet.liquidityOf(address(usdc)), 100_000 * 10 ** 6);

    // Assuming someone short BNB 10_000 USD with 1_000 USDC as collateral.
    usdc.mint(address(poolDiamond), 1_000 * 10 ** 6);
    poolPerpTradeFacet.increasePosition(
      address(this), 0, address(usdc), address(bnb), 10_000 * 1e30, false
    );

    // The following conditions are expected to be true:
    // 1. Pool's BNB target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350)) + 100_000) * 10000 / 20500
    // = 6_827_272.0557491295 USD
    // 2. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350)) + 100_000) * 10000 / 20500
    // = 6_827_272.0557491295 USD
    // 3. Pool's DAI target value should be:
    // = (((30_945.6 - 100) * 320 + 27_030) + (4000000 + (20_000 * (320 - 350) / 350)) + 100_000) * 500 / 20500
    // = 341_363.6027874565 USD
    // 4. Pool's USDC liquidity should be:
    // = 100_000 USDC
    // 5. Pool's BNB current value should be:
    // = ((30_945.6 - 100) * 320 + 27_030)
    // = 9_897_622.0 USD
    // 6. Pool's DAI current value should be:
    // = 4_000_000 + ((20_000 * (320 - 350) / 350) * 20_000 / 30_000) USD
    // = 3_998_857.1428571427 USD
    // 7. Pool's USDC current value should be:
    // = 100_000 + ((20_000 * (320 - 350) / 350) * 10_000 / 30_000) USD
    // = 99_428.57142857143 USD
    assertEq(
      poolGetterFacet.getTargetValue(address(bnb)),
      6_827_272.055749128919860626 ether
    );
    assertEq(
      poolGetterFacet.getTargetValue(address(dai)),
      6_827_272.055749128919860626 ether
    );
    assertEq(
      poolGetterFacet.getTargetValue(address(usdc)),
      341_363.602787456445993031 ether
    );
    assertEq(poolGetterFacet.liquidityOf(address(usdc)), 100_000 * 10 ** 6);
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(bnb), true), 9_897_622.0 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(dai), true),
      3_998_857.142857142857142857 ether
    );
    assertEq(
      poolGetterFacet.getCurrentValueOf(address(usdc), true),
      99_428.571428571428571428 ether
    );
  }
}
