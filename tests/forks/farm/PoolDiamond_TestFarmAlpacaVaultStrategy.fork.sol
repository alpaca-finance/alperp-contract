// SPDX-License-Identifier: MIT
/**
 * ∩~~~~∩
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
  PoolDiamond_BaseForkTest,
  console,
  LibAccessControl,
  PoolOracle,
  LibPoolConfigV1,
  IERC20,
  ALP,
  FundingRateFacetInterface,
  AccessControlFacetInterface,
  PerpTradeFacetInterface,
  AdminFacetInterface,
  GetterFacetInterface,
  FarmFacetInterface,
  LiquidityFacetInterface,
  math
} from "./PoolDiamond_BaseTest.fork.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

struct OraclePrice {
  uint256 wbtcMinPrice;
  uint256 wbtcMaxPrice;
  uint256 busdMinPrice;
  uint256 busdMaxPrice;
}

contract PoolDiamond_ForkTestFarmAlpacaVaultStrategy is
  PoolDiamond_BaseForkTest
{
  using SafeMath for uint256;

  OraclePrice internal prices;

  /// @dev Foundry's setUp method
  function setUp() public override {
    super.setUp();

    vm.prank(WBTC_PHILANTROPHIST);
    forkWbtc.transfer(address(this), 1000 ether);

    vm.prank(BUSD_PHILANTROPHIST);
    forkBusd.transfer(address(this), 1000 ether);

    (address[] memory tokens, PoolOracle.PriceFeedInfo[] memory priceFeedInfo) =
      buildDefaultSetPriceFeedInput();
    poolOracle.setPriceFeed(tokens, priceFeedInfo);

    (
      address[] memory tokens2,
      LibPoolConfigV1.TokenConfig[] memory tokenConfigs2
    ) = buildDefaultSetTokenConfigInput();
    poolAdminFacet.setTokenConfigs(tokens2, tokenConfigs2);

    // set as pending
    poolFarmFacet.setStrategyOf(address(forkBusd), busdFarmStrategy);
    vm.warp(block.timestamp + 1 weeks + 1);
    // committing the pending strategy
    poolFarmFacet.setStrategyOf(address(forkBusd), busdFarmStrategy);

    // set as pending
    poolFarmFacet.setStrategyOf(address(forkWbtc), wbtcFarmStrategy);
    vm.warp(block.timestamp + 1 weeks + 1);
    // committing the pending strategy
    poolFarmFacet.setStrategyOf(address(forkWbtc), wbtcFarmStrategy);

    // set as pending
    poolFarmFacet.setStrategyOf(address(forkWbnb), bnbFarmStrategy);
    vm.warp(block.timestamp + 1 weeks + 1);
    // committing the pending strategy
    poolFarmFacet.setStrategyOf(address(forkWbnb), bnbFarmStrategy);

    // Grant Farm Keeper Role For EVE
    poolAccessControlFacet.grantRole(LibAccessControl.FARM_KEEPER, EVE);

    // 20240.97 e30
    prices.wbtcMinPrice = poolOracle.getMinPrice(address(forkWbtc));
    // 20245.458 e30
    prices.wbtcMaxPrice = poolOracle.getMaxPrice(address(forkWbtc));
    // 1 e30
    prices.busdMinPrice = poolOracle.getMinPrice(address(forkBusd));
    // 1.00000761 e30
    prices.busdMaxPrice = poolOracle.getMaxPrice(address(forkBusd));
  }

  function testFarmableModuleCorrectness_WhenAddLiquidity() public {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(WBTC_TOKEN, 5000);

    forkWbtc.approve(address(poolRouter), 5 ether);
    // 1. adding liquidity into an empty pool
    poolRouter.addLiquidity(
      address(forkWbtc), 5 ether, address(this), 0, zeroBytesArr()
    );

    // there are 0.003% deposit fee
    // = 5 * (1-0.003)
    // = 4.985 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertCloseWei(
      poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether, 2
    );
    assertEq(poolGetterFacet.strategyDataOf(address(forkWbtc)).principle, 0);

    // should not be different more than price * 2 rounded up
    // min AUM = liquidity * min price
    // 4.985 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      100901.23545 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 4.985 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      100923.60813 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 2. FarmKeeper trying to farm & rebalance the pool
    // a profit/loss should be realized after this as there are part of liquidity in the farming vault
    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), true);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertCloseWei(
      poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether, 2
    );
    // 50% of liquidity will be rebalanced into farmable module
    // = 4.985 / 2
    // = 2.4925 in both pool and farm module
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );
    // 2.4925 + 0.015 (0.003% deposit fee in the reserve)
    assertEq(forkWbtc.balanceOf(address(poolDiamond)), 2.5075 ether);

    // min AUM = liquidity * min price
    // 4.985 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      100901.23545 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 4.985 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      100923.60813 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 3. adding more liquidity
    forkWbtc.approve(address(poolRouter), 5 ether);
    // adding liquidity will also realizeFarmPnL
    poolRouter.addLiquidity(
      address(forkWbtc), 5 ether, address(this), 0, zeroBytesArr()
    );

    // principle is left unchanged as there are no rebalancing, 2 wei is from precision loss
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // current liquidity
    // = 4.985 + (5 * (1-0.003))
    // = 9.97 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 9.97 ether, 2
    );
    assertCloseWei(
      poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.03 ether, 2
    );

    // min AUM = liquidity * min price
    // 9.97 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      201802.4709 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 9.97 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      201847.21626 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );
  }

  function testFarmableModuleCorrectness_WhenAddAndRemoveLiquidity() public {
    // Set strategy target bps to be 50%
    poolFarmFacet.setStrategyTargetBps(WBTC_TOKEN, 5000);

    forkWbtc.approve(address(poolRouter), 5 ether);
    // 1. adding liquidity into an empty pool
    poolRouter.addLiquidity(
      address(forkWbtc), 5 ether, address(this), 0, zeroBytesArr()
    );

    // there are 0.003% deposit fee
    // = 5 * (1-0.003)
    // = 4.985 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertCloseWei(
      poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether, 2
    );
    assertEq(poolGetterFacet.strategyDataOf(address(forkWbtc)).principle, 0);

    // should not be different more than price * 2 rounded up
    // min AUM = liquidity * min price
    // 4.985 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      100901.23545 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 4.985 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      100923.60813 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 2. FarmKeeper trying to farm & rebalance the pool
    // a profit/loss should be realized after this as there are part of liquidity in the farming vault
    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), true);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertCloseWei(
      poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether, 2
    );
    // 50% of liquidity will be rebalanced into farmable module
    // = 4.985 / 2
    // = 2.4925 in both pool and farm module
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );
    // 2.4925 + 0.015 (0.003% deposit fee in the reserve)
    assertEq(forkWbtc.balanceOf(address(poolDiamond)), 2.5075 ether);

    // min AUM = liquidity * min price
    // 4.985 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      100901.23545 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 4.985 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      100923.60813 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 3. adding more liquidity
    forkWbtc.approve(address(poolRouter), 5 ether);
    // adding liquidity will also realizeFarmPnL
    poolRouter.addLiquidity(
      address(forkWbtc), 5 ether, address(this), 0, zeroBytesArr()
    );

    // principle is left unchanged as there are no rebalancing, 2 wei is from precision loss
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // current liquidity
    // = 4.985 + (5 * (1-0.003))
    // = 9.97 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 9.97 ether, 2
    );
    assertCloseWei(
      poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.03 ether, 2
    );

    // min AUM = liquidity * min price
    // 9.97 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      201802.4709 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 9.97 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      201847.21626 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // waiting for cooldown
    vm.warp(block.timestamp + 1 days);

    // 4. removing liquidity
    IERC20(address(alp)).approve(address(poolRouter), 100000 ether);

    poolRouter.removeLiquidity(
      address(forkWbtc),
      100000 ether, // liquidity,
      address(this),
      0,
      zeroBytesArr()
    );

    // lpUsdValue = (liquidity * aum) / alp.totalSupply();
    // = (100000 * 201802.470899999999959518) / 201780.103179561193469636;
    // = 100011.085196253914975546

    // amountOut = usdValue / tokenPrice
    // = 100011.085196253914975546 / 20245.458
    // = 4.939927029373892898

    // 0.003% remove liquidity fee
    // = 4.939927029373892898 * 0.003
    // = 0.014819781088121678

    // amountReceived
    // = 4.939927029373892898 - 0.014819781088121678
    // = 4.92510724828577122

    // remaning liquidity
    // 9.97 - (4.939927029373892898)
    // = 5.030072970626107102
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)),
      5.030072970626107102 ether,
      2
    );

    // total fee collected
    // 0.03 + 0.014819781088121678
    assertCloseWei(
      poolGetterFacet.feeReserveOf(address(forkWbtc)),
      0.044819781088121678 ether,
      2
    );

    // principle is left unchanged as there are no rebalancing
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // min AUM = liquidity * min price
    // 5.030072970626107102 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      101813.556096253915068368 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 5.030072970626107102 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      101836.131063746085037042 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 5. FarmKeeper trying to farm & rebalance the pool
    // a profit/loss should be realized after this as there are part of liquidity in the farming vault
    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), true);

    assertCloseBps(
      poolGetterFacet.liquidityOf(address(forkWbtc)),
      5.030072970626107102 ether,
      2
    );

    // principle can be different from targetDeloyedFund because of share calculation during a withdrawl, but it shouldn't be that different (10 BPS delta)
    // 5.030072970626107102 / 2
    assertCloseBps(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.515036485313053551 ether,
      10
    );
  }

  function testFarmableModuleCorrectness_WhenIncreasePerpPosition() public {
    poolFarmFacet.setStrategyTargetBps(address(forkWbtc), 5000);
    poolFarmFacet.setStrategyTargetBps(address(forkBusd), 5000);

    forkWbtc.approve(address(poolRouter), 5 ether);
    // 1. adding liquidity into an empty pool
    poolRouter.addLiquidity(
      address(forkWbtc), 5 ether, address(this), 0, zeroBytesArr()
    );

    // there are 0.003% deposit fee
    // = 5 * (1-0.003)
    // = 4.985 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertEq(poolGetterFacet.strategyDataOf(address(forkWbtc)).principle, 0);

    // min AumE18
    // forkWbtc AUM ( forkWbtc liquidity * forkWbtc min price)
    // = 4.985 * 20240.97
    // = 100901.23545
    assertEq(poolGetterFacet.getAumE18(false), 100901.23545 ether);

    // max AumE18
    // forkWbtc AUM ( forkWbtc liquidity * forkWbtc max price)
    // = 4.985 * 20245.458
    // = 100923.60813
    assertEq(poolGetterFacet.getAumE18(true), 100923.60813 ether);

    // strategy should hold no ibToken, as there are none rebalanced into the vault yet
    assertEq(alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy)), 0);

    // 2. FarmKeeper trying to farm & rebalance the forkWbtc in the pool
    // a profit/loss should be realized after this as there are part of liquidity in the farming vault

    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), true);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    uint256 valueConvertFromShare;
    uint256 ibWbtcBalance = alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy));
    valueConvertFromShare = (ibWbtcBalance * (alpacaWbtcVault.totalToken()))
      / (alpacaWbtcVault.totalSupply());

    assertCloseWei(
      valueConvertFromShare,
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2
    );

    // should not be different more than price * 2 rounded up
    // min AUM = liquidity * min price
    // 4.985 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      100901.23545 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 4.985 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      100923.60813 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 3. interests generated
    vm.warp(block.timestamp + 1 weeks);

    vm.startPrank(WBTC_PHILANTROPHIST);
    forkWbtc.approve(address(alpacaWbtcVault), 100 ether);
    // call deposit to trigger accrue interest
    alpacaWbtcVault.deposit(100 ether);
    vm.stopPrank();

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // Getting AUM will include unaccrued pnl
    // hence, calculating liquidity after pnl

    // liquidity when include the interests
    // 4.985 + 0.000275816295065400
    // = 4.985275816295065400

    // then AUMs would be
    // min price
    // 20240.97 * (4.985274615372603486)
    // = 100906.793931518405982021 ether

    uint256 wbtcShare;
    uint256 wbtcExpectedValue;
    uint256 wbtcDelta;
    uint256 wbtcLiquidity = 4.985 ether;
    {
      wbtcShare = alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy));
      wbtcExpectedValue = (wbtcShare * (alpacaWbtcVault.totalToken()))
        / (alpacaWbtcVault.totalSupply());

      wbtcDelta = wbtcExpectedValue
        - poolGetterFacet.strategyDataOf(address(forkWbtc)).principle;

      // TODO: find a way to accurately calculate the delta
      // assertEq(delta, 275816295065400);

      wbtcLiquidity = wbtcLiquidity + wbtcDelta;
    }

    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max price
    // 20245.458 * (4.985274615372603486)
    //  = 100906793931518405982021
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 4. Call farm to accrue interests
    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), false);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // AUM should remain unchange since getting AUM before is already include the interests
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 5. more interests generated and farm is called to accrue
    vm.warp(block.timestamp + 5 weeks);

    vm.startPrank(WBTC_PHILANTROPHIST);
    forkWbtc.approve(address(alpacaWbtcVault), 100 ether);
    alpacaWbtcVault.deposit(100 ether);
    vm.stopPrank();

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // Getting AUM includes any unaccrued pnl
    // hence, calculating liquidity after pnl

    // liquidity when include the interests
    // 4.985274615372603486 + 0.001146193878221987
    // = 4.986420809250825473 e18 liquidity
    // then AUM would be
    // prices * (4.985274615372603486 + 0.001146193878221987)
    {
      wbtcShare = alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy));
      wbtcExpectedValue = (wbtcShare * (alpacaWbtcVault.totalToken()))
        / (alpacaWbtcVault.totalSupply());

      wbtcDelta = wbtcExpectedValue
        - poolGetterFacet.strategyDataOf(address(forkWbtc)).principle;

      wbtcLiquidity = wbtcLiquidity + wbtcDelta;
    }

    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), false);

    // only liquidity changes as the interest is accrued
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );

    // other should still remains the same
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 6. ALICE adding forkBusd liquidity
    vm.prank(BUSD_PHILANTROPHIST);
    forkBusd.transfer(ALICE, 10000 ether);

    vm.startPrank(ALICE);

    forkBusd.approve(address(poolRouter), 10000 ether);
    poolRouter.addLiquidity(
      address(forkBusd), 10000 ether, address(this), 0, zeroBytesArr()
    );

    // forkWbtc should remain the same
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // there are 0.003% deposit fee
    // = 10000 * (1-0.003)
    // = 9970 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkBusd)), 9970 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkBusd)), 30 ether);
    assertEq(poolGetterFacet.strategyDataOf(address(forkBusd)).principle, 0);

    // AUMs = forkWbtc aum + forkBusd aum
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      9970 ether + (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) + 2 // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      9970.0758717 ether + (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) + 2 // 20245.458 * 2 rounded up
    );

    vm.stopPrank();

    // 7. BOB open a short position
    vm.prank(BUSD_PHILANTROPHIST);
    forkBusd.transfer(BOB, 10000 ether);

    vm.startPrank(BOB);
    forkBusd.approve(address(poolRouter), 20 ether);
    poolRouter.increasePosition(
      0,
      address(forkBusd),
      address(forkBusd),
      20 ether, // use 20e18 forkBusd as collateral
      0,
      address(forkWbtc),
      20 * (PRICE_PRECISION), // position size of 20 usd
      false,
      prices.wbtcMinPrice,
      zeroBytesArr()
    );
    vm.stopPrank();

    // there is 0.001% increase position fee
    // (20 * 0.001)
    // = 0.02 USD

    // forkBusd required for 0.02 USD
    // 0.02 / 1.00000761
    // = 0.019999847801158233

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkBusd)), 9970 ether, 2
    );
    assertEq(
      poolGetterFacet.feeReserveOf(address(forkBusd)),
      30 ether + 0.019999847801158233 ether
    );
    assertEq(poolGetterFacet.strategyDataOf(address(forkBusd)).principle, 0);

    GetterFacetInterface.GetPositionReturnVars memory position;
    {
      position = poolGetterFacet.getPosition(
        BOB, address(forkBusd), address(forkWbtc), false
      );
      assertEq(position.size, 20 * PRICE_PRECISION);
    }

    // AUMs = forkWbtc aum + forkBusd aum
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      9970 ether + 0.004434570082362653 ether
        + (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) + 2 // 20240.97 * 2 rounded up
    );

    // forkWbtc's AUM = 100952.373064013598578951 + short position loss
    // = 100952.373064013598578951 + ((priceDelta * shortSize) / shortAvgPrice)
    // = 100952.373064013598578951 + ((4.488 * 20) / 20240.97)
    // = 100952.373064013598578951 + 0.004434570082362653
    // forkBusd's AUM = 9970.0758717

    // AUM = sum of each token AUM
    // = (100952.373064013598578951 + 0.004434570082362653) + 9970.0758717
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      9970.0758717 ether + 0.004434570082362653 ether
        + (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) + 2 // 20245.458 * 2 rounded up
    );
  }

  function testFarmableModuleCorrectness_WhenIncreaseAndDecreasePerpPosition()
    public
  {
    poolFarmFacet.setStrategyTargetBps(address(forkWbtc), 5000);
    poolFarmFacet.setStrategyTargetBps(address(forkBusd), 5000);

    forkWbtc.approve(address(poolRouter), 5 ether);
    // 1. adding liquidity into an empty pool
    poolRouter.addLiquidity(
      address(forkWbtc), 5 ether, address(this), 0, zeroBytesArr()
    );

    // there are 0.003% deposit fee
    // = 5 * (1-0.003)
    // = 4.985 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertEq(poolGetterFacet.strategyDataOf(address(forkWbtc)).principle, 0);

    // min AumE18
    // forkWbtc AUM ( forkWbtc liquidity * forkWbtc min price)
    // = 4.985 * 20240.97
    // = 100901.23545
    assertEq(poolGetterFacet.getAumE18(false), 100901.23545 ether);

    // max AumE18
    // forkWbtc AUM ( forkWbtc liquidity * forkWbtc max price)
    // = 4.985 * 20245.458
    // = 100923.60813
    assertEq(poolGetterFacet.getAumE18(true), 100923.60813 ether);

    // strategy should hold no ibToken, as there are none rebalanced into the vault yet
    assertEq(alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy)), 0);

    // 2. FarmKeeper trying to farm & rebalance the forkWbtc in the pool
    // a profit/loss should be realized after this as there are part of liquidity in the farming vault

    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), true);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    uint256 valueConvertFromShare;
    uint256 ibWbtcBalance = alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy));
    valueConvertFromShare = (ibWbtcBalance * (alpacaWbtcVault.totalToken()))
      / (alpacaWbtcVault.totalSupply());

    assertCloseWei(
      valueConvertFromShare,
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2
    );

    // should not be different more than price * 2 rounded up
    // min AUM = liquidity * min price
    // 4.985 * 20240.97
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      100901.23545 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max AUM = liquidity * max price
    // 4.985 * 20245.458
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      100923.60813 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 3. interests generated
    vm.warp(block.timestamp + 1 weeks);

    vm.startPrank(WBTC_PHILANTROPHIST);
    forkWbtc.approve(address(alpacaWbtcVault), 100 ether);
    // call deposit to trigger accrue interest
    alpacaWbtcVault.deposit(100 ether);
    vm.stopPrank();

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 4.985 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // Getting AUM includes any unaccrued pnl
    // hence, calculating liquidity after pnl

    uint256 wbtcShare;
    uint256 wbtcExpectedValue;
    uint256 wbtcDelta;
    uint256 wbtcLiquidity = 4.985 ether;
    {
      wbtcShare = alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy));
      wbtcExpectedValue = (wbtcShare * (alpacaWbtcVault.totalToken()))
        / (alpacaWbtcVault.totalSupply());

      wbtcDelta = wbtcExpectedValue
        - poolGetterFacet.strategyDataOf(address(forkWbtc)).principle;

      // TODO: find a way to accurately calculate the delta
      // assertEq(delta, 275816295065400);

      wbtcLiquidity = wbtcLiquidity + wbtcDelta;
    }

    // liquidity when include the interests
    // 4.985 + 0.000274615372603486
    // = 4.985274615372603486

    // then AUMs would be
    // min price
    // 20240.97 * (4.985274615372603486)
    // = 100906.793931518405982021 ether

    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      ((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );

    // max price
    // 20245.458 * (4.985274615372603486)
    //  = 100906793931518405982021
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      ((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 4. Call farm to accrue interests
    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), false);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // AUM should remain unchange since getting AUM before is already include the interests
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      ((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      ((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 5. more interests generated and farm is called to accrue
    vm.warp(block.timestamp + 5 weeks);

    vm.startPrank(WBTC_PHILANTROPHIST);
    forkWbtc.approve(address(alpacaWbtcVault), 100 ether);
    alpacaWbtcVault.deposit(100 ether);
    vm.stopPrank();

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // Getting AUM includes any unaccrued pnl
    // hence, calculating liquidity after pnl

    {
      wbtcShare = alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy));
      wbtcExpectedValue = (wbtcShare * (alpacaWbtcVault.totalToken()))
        / (alpacaWbtcVault.totalSupply());

      wbtcDelta = wbtcExpectedValue
        - poolGetterFacet.strategyDataOf(address(forkWbtc)).principle;

      // TODO: find a way to accurately calculate the delta
      // assertEq(delta, 275816295065400);

      wbtcLiquidity = wbtcLiquidity + wbtcDelta;
    }

    // liquidity when include the interests
    // 4.985274615372603486 + 0.001146193878221987
    // = 4.986420809250825473 e18 liquidity
    // then AUM would be
    // prices * (4.985274615372603486 + 0.001146193878221987)

    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      ((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      ((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), false);

    // only liquidity changes as the interest is accrued
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );

    // other should still remains the same
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      ((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      ((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    // 6. ALICE adding forkBusd liquidity
    vm.prank(BUSD_PHILANTROPHIST);
    forkBusd.transfer(ALICE, 10000 ether);

    vm.startPrank(ALICE);

    forkBusd.approve(address(poolRouter), 10000 ether);
    poolRouter.addLiquidity(
      address(forkBusd), 10000 ether, address(this), 0, zeroBytesArr()
    );

    // forkWbtc should remain the same
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // there are 0.003% deposit fee
    // = 10000 * (1-0.003)
    // = 9970 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkBusd)), 9970 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkBusd)), 30 ether);
    assertEq(poolGetterFacet.strategyDataOf(address(forkBusd)).principle, 0);

    // AUMs = forkWbtc aum + forkBusd aum
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      9970 ether + (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) + 2 // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      9970.0758717 ether + (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) + 2 // 20245.458 * 2 rounded up
    );

    vm.stopPrank();

    // 7. BOB open a short position
    vm.prank(BUSD_PHILANTROPHIST);
    forkBusd.transfer(BOB, 10000 ether);

    vm.startPrank(BOB);
    forkBusd.approve(address(poolRouter), 20 ether);
    poolRouter.increasePosition(
      0,
      address(forkBusd),
      address(forkBusd),
      20 ether, // use 20e18 forkBusd as collateral
      0,
      address(forkWbtc),
      20 * (PRICE_PRECISION), // position size of 20 usd
      false,
      prices.wbtcMinPrice,
      zeroBytesArr()
    );
    vm.stopPrank();

    // there is 0.001% increase position fee
    // (20 * 0.001)
    // = 0.02 USD

    // forkBusd required for 0.02 USD
    // 0.02 / 1.00000761
    // = 0.019999847801158233

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkBusd)), 9970 ether, 2
    );
    assertEq(
      poolGetterFacet.feeReserveOf(address(forkBusd)),
      30 ether + 0.019999847801158233 ether
    );
    assertEq(poolGetterFacet.strategyDataOf(address(forkBusd)).principle, 0);

    GetterFacetInterface.GetPositionReturnVars memory position;
    {
      position = poolGetterFacet.getPosition(
        BOB, address(forkBusd), address(forkWbtc), false
      );
      assertEq(position.size, 20 * PRICE_PRECISION);
    }

    // AUMs = forkWbtc aum + forkBusd aum
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      9970 ether + 0.004434570082362653 ether
        + (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) + 2 // 20240.97 * 2 rounded up
    );

    // forkWbtc's AUM = 100952.373064013598578951 + short position loss
    // = 100952.373064013598578951 + ((priceDelta * shortSize) / shortAvgPrice)
    // = 100952.373064013598578951 + ((4.488 * 20) / 20240.97)
    // = 100952.373064013598578951 + 0.004434570082362653
    // forkBusd's AUM = 9970.0758717

    // AUM = sum of each token AUM
    // = (100952.373064013598578951 + 0.004434570082362653) + 9970.0758717
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      9970.0758717 ether + 0.004434570082362653 ether
        + (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) + 2 // 20245.458 * 2 rounded up
    );
    vm.prank(BUSD_PHILANTROPHIST);
    forkBusd.transfer(BOB, 1000 ether);

    vm.startPrank(BOB);
    // 6. BOB reduce his short position
    forkBusd.approve(address(poolRouter), 1000 ether);
    poolRouter.decreasePosition(
      0,
      address(forkBusd),
      address(forkWbtc),
      10 * (PRICE_PRECISION), // withdraw 10 collateral
      10 * (PRICE_PRECISION), // repay 10 debt
      false,
      address(this),
      prices.wbtcMaxPrice,
      address(forkBusd),
      0,
      zeroBytesArr()
    );
    vm.stopPrank();

    // forkWbtc is untouched
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), wbtcLiquidity, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.015 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2.4925 ether,
      2
    );

    // short position loss count as platform profit
    // and will be added to the liquidity

    // calculating position PnL
    // average price is min price at the open the position period
    // avgPrice = 20240.97

    // priceDelta = price - avgPrice
    // 20245.458 - 20240.97
    // = 4.488

    // positionDelta = (size * vars.priceDelta) / averagePrice
    // (20 * 4.488) / 20240.97
    // 0.004434570082362653568480166711

    // delta = (positionDelta * sizeDelta) / position.size;
    // = (0.004434570082362653568480166711 * 10) / 20
    // = 0.00221726816777057

    // 9970 + 0.00221726816777057
    // = 9970.00221726816777057
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkBusd)),
      9970.00221726816777057 ether,
      2
    );

    // 0.001% fee from position delta
    // = 10 * 0.001
    // = 0.01 usd

    // convert to forkBusd amount as it is
    // = 0.01 / forkBusd max price
    // = 0.01 / 1.00000761
    // = 0.009999923900579116
    assertEq(
      poolGetterFacet.feeReserveOf(address(forkBusd)),
      30.019999847801158233 ether + 0.009999923900579116 ether
    );
    assertEq(poolGetterFacet.strategyDataOf(address(forkBusd)).principle, 0);

    {
      position = poolGetterFacet.getPosition(
        BOB, address(forkBusd), address(forkWbtc), false
      );
      assertEq(position.size, 10 * PRICE_PRECISION);
    }

    // forkWbtc's AUM = 100929.994007262622089557 + short position loss
    // = 100929.994007262622089557 + ((priceDelta * shortSize) / shortAvgPrice)
    // = 100929.994007262622089557 + ((4.488 * 10) / 20240.97)
    // = 100929.994007262622089557 + 0.002217285041181326
    // getAUM, regardless of true of false, when it comes to short delta, we will always use the max price
    // forkBusd's AUM = 9970.00221726816777057
    // AUM = sum of each token AUM
    // = (100929.994007262622089557 + 0.002217285041181326) + 9970.00221726816777057

    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      9970.00221726816777057 ether + 0.002217285041181326 ether
        + (((20240.97 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) + 2 // 20240.97 * 2 rounded up
    );

    // forkWbtc's AUM = 100952.373064013598578951 + short position loss
    // = 100952.373064013598578951 + ((priceDelta * shortSize) / shortAvgPrice)
    // = 100952.373064013598578951 + ((4.488 * 10) / 20240.97)
    // = 100952.373064013598578951 + 0.002217285041181326
    // forkBusd's AUM = 9970.00221726816777057 * 1.00000761
    // = 9970.078088985041181326

    // AUM = sum of each token AUM
    // = (100952.373064013598578951 + 0.002217285041181326) + 9970.078088985041181326
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      9970.078088985041181326 ether + 0.002217285041181326 ether
        + (((20245.458 * 10 ** 8) * wbtcLiquidity) / 10 ** 8),
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) + 2 // 20245.458 * 2 rounded up
    );
  }

  function testFarmableModuleCorrectness_WhenWithdrawnAllFromTheVault() public {
    poolFarmFacet.setStrategyTargetBps(address(forkWbtc), 5000);
    poolFarmFacet.setStrategyTargetBps(address(forkBusd), 5000);

    forkWbtc.approve(address(poolRouter), 100 ether);
    // 1. adding liquidity into an empty pool
    poolRouter.addLiquidity(
      address(forkWbtc), 100 ether, address(this), 0, zeroBytesArr()
    );

    // there are 0.003% deposit fee
    // = 100 * (1-0.003)
    // = 4.985 liquidity
    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 99.7 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.3 ether);
    assertEq(poolGetterFacet.strategyDataOf(address(forkWbtc)).principle, 0);

    // min AumE18
    // forkWbtc AUM ( forkWbtc liquidity * forkWbtc min price)
    // = 99.7 * 20240.97
    // = 2018024.709
    assertEq(poolGetterFacet.getAumE18(false), 2018024.709 ether);

    // max AumE18
    // forkWbtc AUM ( forkWbtc liquidity * forkWbtc max price)
    // = 99.7 * 20245.458
    // = 2018472.1626
    assertEq(poolGetterFacet.getAumE18(true), 2018472.1626 ether);

    // strategy should hold no ibToken, as there are none rebalanced into the vault yet
    assertEq(alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy)), 0);

    // 2. FarmKeeper trying to farm & rebalance the forkWbtc in the pool
    // a profit/loss should be realized after this as there are part of liquidity in the farming vault

    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), true);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 99.7 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.3 ether);
    assertCloseWei(
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      49.85 ether,
      2
    );

    // share minted
    uint256 valueConvertFromShare;
    uint256 ibWbtcBalance = alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy));
    valueConvertFromShare = (ibWbtcBalance * (alpacaWbtcVault.totalToken()))
      / (alpacaWbtcVault.totalSupply());

    assertCloseWei(
      valueConvertFromShare,
      poolGetterFacet.strategyDataOf(address(forkWbtc)).principle,
      2
    );

    // Getting AUM will include unaccrued pnl
    // which is 0.104011249804650889 increase in liquidity

    // shareToValue = share * totalToken / totalSupply
    // = 2377012174490028971 * 1048117954129818399284 / 1034693642825666881636
    // = 2.407851980673595786

    // should not be different more than price * 2 rounded up
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      2018024.709 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      2018472.1626 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );

    poolFarmFacet.setStrategyTargetBps(address(forkWbtc), 0);

    vm.prank(EVE);
    poolFarmFacet.farm(address(forkWbtc), true);

    assertCloseWei(
      poolGetterFacet.liquidityOf(address(forkWbtc)), 99.7 ether, 2
    );
    assertEq(poolGetterFacet.feeReserveOf(address(forkWbtc)), 0.3 ether);
    assertEq(poolGetterFacet.strategyDataOf(address(forkWbtc)).principle, 0);

    // share burned as all has been withdrawn
    assertEq(alpacaWbtcVault.balanceOf(address(wbtcFarmStrategy)), 0);

    // Getting AUM will include unaccrued pnl
    // which is 0.104011249804650889 increase in liquidity

    // shareToValue = share * totalToken / totalSupply
    // = 2377012174490028971 * 1048117954129818399284 / 1034693642825666881636
    // = 2.407851980673595786

    // should not be different more than price * 2 rounded up
    assertCloseWei(
      poolGetterFacet.getAumE18(false),
      2018024.709 ether,
      math.roundUpE30(prices.wbtcMinPrice.mul(2)) // 20240.97 * 2 rounded up
    );
    assertCloseWei(
      poolGetterFacet.getAumE18(true),
      2018472.1626 ether,
      math.roundUpE30(prices.wbtcMaxPrice.mul(2)) // 20245.458 * 2 rounded up
    );
  }
}
