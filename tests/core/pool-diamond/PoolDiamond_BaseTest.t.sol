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

/// OZ
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Pyth
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

/// Alperp tests
import {
  BaseTest,
  MockWNative,
  console,
  stdError,
  MockStrategy,
  MockDonateVault,
  ALP,
  AP,
  MockFlashLoanBorrower,
  LibPoolConfigV1,
  PoolOracle,
  PoolRouter04,
  OwnershipFacetInterface,
  GetterFacetInterface,
  LiquidityFacetInterface,
  PerpTradeFacetInterface,
  AdminFacetInterface,
  FarmFacetInterface,
  AccessControlFacetInterface,
  LibAccessControl,
  FundingRateFacetInterface,
  Orderbook02,
  MarketOrderExecutor,
  MarketOrderRouter,
  FastPriceFeed,
  PythPriceFeed,
  FakePyth,
  TradeMiningManager
} from "@alperp-tests/base/BaseTest.sol";

abstract contract PoolDiamond_BaseTest is BaseTest {
  PoolOracle internal poolOracle;
  address internal poolDiamond;
  PoolRouter04 internal poolRouter;
  ALP internal alp;
  TradeMiningManager internal tradeMiningManager;
  AP internal ap;

  MockWNative internal revenueToken;

  AdminFacetInterface internal poolAdminFacet;
  GetterFacetInterface internal poolGetterFacet;
  LiquidityFacetInterface internal poolLiquidityFacet;
  PerpTradeFacetInterface internal poolPerpTradeFacet;
  FarmFacetInterface internal poolFarmFacet;
  AccessControlFacetInterface internal poolAccessControlFacet;
  FundingRateFacetInterface internal poolFundingRateFacet;

  Orderbook02 internal orderbook;
  MarketOrderExecutor internal marketOrderExecutor;
  MarketOrderRouter internal marketOrderRouter;

  PythPriceFeed internal pythPriceFeed;
  FakePyth internal pyth;

  function setUp() public virtual {
    revenueToken = deployMockWNative();

    BaseTest.PoolConfigConstructorParams memory poolConfigParams = BaseTest
      .PoolConfigConstructorParams({
      treasury: TREASURY,
      fundingInterval: 1 hours,
      mintBurnFeeBps: 30,
      taxBps: 50,
      stableBorrowingRateFactor: 100,
      borrowingRateFactor: 100,
      fundingRateFactor: 25,
      liquidationFeeUsd: 5 * 10 ** 30
    });

    (poolOracle, poolDiamond) = deployPoolDiamond(poolConfigParams);

    (address[] memory tokens, PoolOracle.PriceFeedInfo[] memory priceFeedInfo) =
      buildDefaultSetPriceFeedInput();
    poolOracle.setPriceFeed(tokens, priceFeedInfo);

    poolAdminFacet = AdminFacetInterface(poolDiamond);
    poolGetterFacet = GetterFacetInterface(poolDiamond);
    poolLiquidityFacet = LiquidityFacetInterface(poolDiamond);
    poolPerpTradeFacet = PerpTradeFacetInterface(poolDiamond);
    poolFarmFacet = FarmFacetInterface(poolDiamond);
    poolAccessControlFacet = AccessControlFacetInterface(poolDiamond);
    poolFundingRateFacet = FundingRateFacetInterface(poolDiamond);

    alp = poolGetterFacet.alp();

    // Pyth PriceFeed
    pyth = deployFakePyth(1, 0.01 ether); // no older than 1 sec for getPrice, 0.01 for fee
    pythPriceFeed = deployPythPriceFeed(address(pyth));

    // Deploy Trade Mining
    ap = deployAP();
    tradeMiningManager = deployTradeMiningManager(address(ap));

    poolRouter = deployPoolRouter(
      address(bnb),
      poolDiamond,
      address(pythPriceFeed),
      address(tradeMiningManager)
    );
    poolAdminFacet.setRouter(address(poolRouter));

    alp.setWhitelist(address(poolRouter), true);
    // Grant Farm Keeper Role For This testing contract
    poolAccessControlFacet.grantRole(
      LibAccessControl.FARM_KEEPER, address(this)
    );

    // Deploy & config periphery contracts.
    // Orderbook for limit order
    // Deploy Orderbook
    orderbook = deployOrderbook(
      poolDiamond,
      address(poolOracle),
      address(bnb),
      0.01 ether,
      1 ether,
      address(pythPriceFeed)
    );
    // Allow orderbook as a plugin on poolDiamond
    poolAdminFacet.setPlugin(address(orderbook), true);
    // MarketOrderRouter for market order
    // Deploy MarketOrderRouter
    marketOrderRouter = deployMarketOrderRouter(
      poolDiamond,
      address(poolOracle),
      address(tradeMiningManager),
      address(bnb),
      1 ether,
      0.01 ether
    );
    // Deploy MarketOrderExecutor
    marketOrderExecutor = deployMarketOrderExecutor(
      address(pythPriceFeed), address(marketOrderRouter)
    );
    // Set address(this) to be the executor
    marketOrderExecutor.setExecutor(address(this), true);
    // Set address(this) as a admin of MarketOrderRouter
    marketOrderRouter.setAdmin(address(this));
    // Allow marketOrderExecutor as a position keeper on MarketOrderRouter
    marketOrderRouter.setPositionKeeper(address(marketOrderExecutor), true);
    // Allow marketOrderRouter as a plugin on poolDiamond
    poolAdminFacet.setPlugin(address(marketOrderRouter), true);

    // For majority of orderbook test cases, can omit pyth price first
    pythPriceFeed.setFavorRefPrice(true);
    pythPriceFeed.setUpdater(address(orderbook), true);
    pythPriceFeed.setUpdater(address(poolRouter), true);
    pythPriceFeed.setUpdater(address(marketOrderExecutor), true);
    pyth.updatePriceFeeds{value: 0.04 ether}(buildPythUpdateData(40_000 * 1e8, 400 * 1e8, 1800 * 1e8, 1 * 1e8));
    tokens = new address[](4);
    tokens[0] = address(wbtc);
    tokens[1] = address(bnb);
    tokens[2] = address(weth);
    tokens[3] = address(dai);
    bytes32[] memory tokenIds = new bytes32[](4);
    tokenIds[0] = WBTC_PRICE_ID;
    tokenIds[1] = WBNB_PRICE_ID;
    tokenIds[2] = ETH_PRICE_ID;
    tokenIds[3] = DAI_PRICE_ID;
    pythPriceFeed.setTokenPriceIds(tokens, tokenIds);
    pythPriceFeed.setMaxPriceAge(15);

    // Config trade mining.
    ap.setMinter(address(tradeMiningManager), true);
    tradeMiningManager.setAuth(address(poolRouter), true);
    tradeMiningManager.setAuth(address(marketOrderRouter), true);
    tradeMiningManager.setAuth(address(orderbook), true);
    tradeMiningManager.setPeriod(1, 1735689600);
    tradeMiningManager.setAp(ap);

    // Set tradeMiningManager on poolRouter and orderbook.
    poolRouter.setTradeMiningManager(tradeMiningManager);
    orderbook.setTradeMiningManager(tradeMiningManager);
  }

  function checkPoolBalanceWithState(address token, int256 offset) internal {
    uint256 balance = IERC20(token).balanceOf(address(poolDiamond));
    assertEq(
      balance,
      uint256(
        int256(poolGetterFacet.liquidityOf(token))
          + int256(poolGetterFacet.feeReserveOf(token)) + offset
      )
    );
  }

  function getPriceBits(uint256 wbtcPrice, uint256 wethPrice, uint256 bnbPrice)
    internal
    pure
    returns (uint256)
  {
    uint256 priceBits = 0;
    priceBits = priceBits | (wbtcPrice << (0 * 32));
    priceBits = priceBits | (wethPrice << (1 * 32));
    priceBits = priceBits | (bnbPrice << (2 * 32));
    return priceBits;
  }
}
