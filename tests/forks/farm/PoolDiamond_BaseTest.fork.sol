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

/// OZ
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// Pyth
import {MockPyth as FakePyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

/// Chainlink
import {ChainlinkPriceFeedInterface} from
  "@alperp/interfaces/ChainLinkPriceFeedInterface.sol";

/// Alperp Tests
import {ForkBaseTest} from "@alperp-tests/forks/base/BaseTest.sol";
import {console} from "@alperp-tests/utils/console.sol";
import {math} from "@alperp-tests/utils/math.sol";

/// Alperp
import {PoolDiamond} from "@alperp/core/pool-diamond/PoolDiamond.sol";
import {PoolOracle} from "@alperp/core/PoolOracle.sol";
import {PoolRouter04} from "@alperp/periphery/pool-routers/PoolRouter04.sol";
import {DiamondLoupeFacet} from
  "@alperp/core/pool-diamond/facets/DiamondLoupeFacet.sol";
import {
  OwnershipFacet,
  OwnershipFacetInterface
} from "@alperp/core/pool-diamond/facets/OwnershipFacet.sol";
import {
  GetterFacet,
  GetterFacetInterface
} from "@alperp/core/pool-diamond/facets/GetterFacet.sol";
import {
  FundingRateFacet,
  FundingRateFacetInterface
} from "@alperp/core/pool-diamond/facets/FundingRateFacet.sol";
import {
  LiquidityFacet,
  LiquidityFacetInterface
} from "@alperp/core/pool-diamond/facets/LiquidityFacet.sol";
import {
  PerpTradeFacet,
  PerpTradeFacetInterface
} from "@alperp/core/pool-diamond/facets/PerpTradeFacet.sol";
import {
  AdminFacet,
  AdminFacetInterface
} from "@alperp/core/pool-diamond/facets/AdminFacet.sol";
import {
  FarmFacet,
  FarmFacetInterface
} from "@alperp/core/pool-diamond/facets/FarmFacet.sol";
import {
  AccessControlFacet,
  AccessControlFacetInterface
} from "@alperp/core/pool-diamond/facets/AccessControlFacet.sol";
import {DiamondInitializer} from
  "@alperp/core/pool-diamond/initializers/DiamondInitializer.sol";
import {AccessControlInitializer} from
  "@alperp/core/pool-diamond/initializers/AccessControlInitializer.sol";
import {PoolConfigInitializer} from
  "@alperp/core/pool-diamond/initializers/PoolConfigInitializer.sol";
import {PythPriceFeed} from "@alperp/core/PythPriceFeed.sol";

import {LibAccessControl} from
  "@alperp/core/pool-diamond/libraries/LibAccessControl.sol";
import {LibPoolConfigV1} from
  "@alperp/core/pool-diamond/libraries/LibPoolConfigV1.sol";
import {ALP} from "@alperp/tokens/ALP.sol";
import {IVault} from "@alperp/apis/alpaca/IVault.sol";
import {AlpacaVaultFarmStrategy} from "@alperp/core/AlpacaVaultFarmStrategy.sol";
import {
  DiamondCutFacet,
  DiamondCutInterface
} from "@alperp/core/pool-diamond/facets/DiamondCutFacet.sol";

contract PoolDiamond_BaseForkTest is ForkBaseTest {
  PoolRouter04 internal poolRouter;
  PoolOracle internal poolOracle;
  address internal poolDiamond;

  IVault internal alpacaBusdVault;
  IVault internal alpacaWbtcVault;
  IVault internal alpacaBnbVault;

  AlpacaVaultFarmStrategy internal busdFarmStrategy;
  AlpacaVaultFarmStrategy internal wbtcFarmStrategy;
  AlpacaVaultFarmStrategy internal bnbFarmStrategy;

  AdminFacetInterface internal poolAdminFacet;
  GetterFacetInterface internal poolGetterFacet;
  LiquidityFacetInterface internal poolLiquidityFacet;
  PerpTradeFacetInterface internal poolPerpTradeFacet;
  FarmFacetInterface internal poolFarmFacet;
  AccessControlFacetInterface internal poolAccessControlFacet;
  FundingRateFacetInterface internal poolFundingRateFacet;

  ALP internal alp;

  IERC20 internal forkBusd;
  IERC20 internal forkWbtc;
  IERC20 internal forkBnb;

  ChainlinkPriceFeedInterface internal forkBusdPriceFeed;
  ChainlinkPriceFeedInterface internal forkWbtcPriceFeed;
  ChainlinkPriceFeedInterface internal forkBnbPriceFeed;

  PythPriceFeed internal pythPriceFeed;
  IPyth internal pyth;

  function buildDefaultSetTokenConfigInput()
    internal
    view
    returns (address[] memory, LibPoolConfigV1.TokenConfig[] memory)
  {
    address[] memory tokens = new address[](3);
    tokens[0] = address(forkBusd);
    tokens[1] = address(forkWbtc);
    tokens[2] = address(forkBnb);

    LibPoolConfigV1.TokenConfig[] memory tokenConfigs =
      new LibPoolConfigV1.TokenConfig[](3);
    tokenConfigs[0] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: true,
      isShortable: false,
      decimals: 18,
      weight: 10000,
      minProfitBps: 75,
      usdDebtCeiling: 50000000 ether,
      shortCeiling: 0,
      bufferLiquidity: 10000 ether,
      openInterestLongCeiling: 0
    });
    tokenConfigs[1] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: 18,
      weight: 20000,
      minProfitBps: 75,
      usdDebtCeiling: 100000000 ether,
      shortCeiling: 100000000 * PRICE_PRECISION,
      bufferLiquidity: 10 ether,
      openInterestLongCeiling: 100000000 ether
    });
    tokenConfigs[2] = LibPoolConfigV1.TokenConfig({
      accept: true,
      isStable: false,
      isShortable: true,
      decimals: 18,
      weight: 20000,
      minProfitBps: 75,
      usdDebtCeiling: 100000000 ether,
      shortCeiling: 100000000 * PRICE_PRECISION,
      bufferLiquidity: 10 ether,
      openInterestLongCeiling: 100000000 ether
    });

    return (tokens, tokenConfigs);
  }

  /// @dev Foundry's setUp method
  function setUp() public virtual {
    forkBusd = IERC20(BUSD_TOKEN);
    forkWbtc = IERC20(WBTC_TOKEN);
    forkBnb = IERC20(WBNB_TOKEN);

    forkBusdPriceFeed = ChainlinkPriceFeedInterface(BUSD_CHAINLINK_ORACLE);
    forkWbtcPriceFeed = ChainlinkPriceFeedInterface(WBTC_CHAINLINK_ORACLE);
    forkBnbPriceFeed = ChainlinkPriceFeedInterface(BNB_CHAINLINK_ORACLE);

    PoolConfigConstructorParams memory poolConfigParams =
    PoolConfigConstructorParams({
      treasury: TREASURY,
      fundingInterval: 1 hours,
      mintBurnFeeBps: 30,
      taxBps: 50,
      stableBorrowingRateFactor: 100,
      borrowingRateFactor: 100,
      fundingRateFactor: 25,
      liquidationFeeUsd: 5 * PRICE_PRECISION
    });

    (poolOracle, poolDiamond) = deployPoolDiamond(poolConfigParams);

    alpacaBusdVault = IVault(ALPACA_BUSD_VAULT);
    busdFarmStrategy =
      deployAlpacaVaultFarmStrategy(BUSD_TOKEN, address(alpacaBusdVault));

    alpacaWbtcVault = IVault(ALPACA_WBTC_VAULT);
    wbtcFarmStrategy =
      deployAlpacaVaultFarmStrategy(WBTC_TOKEN, address(alpacaWbtcVault));

    alpacaBnbVault = IVault(ALPACA_BNB_VAULT);
    bnbFarmStrategy =
      deployAlpacaVaultFarmStrategy(WBNB_TOKEN, address(alpacaBnbVault));

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
    poolRouter =
      deployPoolRouter(address(forkBnb), poolDiamond, address(pythPriceFeed));
    poolAdminFacet.setRouter(address(poolRouter));

    alp.setWhitelist(address(poolRouter), true);

    // for majority of orderbook test cases, can omit pyth price first
    pythPriceFeed.setFavorRefPrice(true);
    pythPriceFeed.setUpdater(address(poolRouter), true);
    pythPriceFeed.setMaxPriceAge(15);
  }

  function deployPoolRouter(
    address _wNative,
    address _pool,
    address _oraclePriceUpdater
  ) internal returns (PoolRouter04) {
    bytes memory _logicBytecode =
      abi.encodePacked(vm.getCode("./out/PoolRouter04.sol/PoolRouter04.json"));

    bytes memory _initializer = abi.encodeWithSelector(
      bytes4(keccak256("initialize(address,address,address)")),
      _wNative,
      _pool,
      _oraclePriceUpdater
    );
    address _proxy = _setupUpgradeable(_logicBytecode, _initializer);

    return PoolRouter04(payable(_proxy));
  }

  function deployAlpacaVaultFarmStrategy(address token_, address vault_)
    internal
    returns (AlpacaVaultFarmStrategy)
  {
    AlpacaVaultFarmStrategy strategy = new AlpacaVaultFarmStrategy(
      token_,
      vault_,
      poolDiamond
    );

    // TODO: make sure if the approve logic is really allowed here
    vm.prank(address(strategy));
    IERC20(token_).approve(address(vault_), type(uint256).max);

    return strategy;
  }
}
