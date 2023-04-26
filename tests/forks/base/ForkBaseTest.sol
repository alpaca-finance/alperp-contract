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

/// Alperp Tests
import {Config} from "@alperp-tests/forks/base/Config.sol";
import {
  BaseTest,
  AP,
  Paradeen,
  PoolOracle,
  Orderbook02,
  PoolRouter04,
  PythPriceFeed,
  IERC20,
  ChainlinkPriceFeedInterface,
  AccessControlFacetInterface,
  console,
  ProxyAdmin,
  ALPStaking,
  TransparentUpgradeableProxy,
  ALP,
  RewardDistributor,
  console2,
  IPancakeV3Router
} from "@alperp-tests/base/BaseTest.sol";

/// Pyth
import {MockPyth as FakePyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

abstract contract ForkBaseTest is BaseTest, Config {
  address internal constant EVE = address(0x888888);

  ProxyAdmin internal forkProxyAdmin;

  IERC20 internal forkBtcb;
  IERC20 internal forkEth;
  IERC20 internal forkWbnb;
  IERC20 internal forkBusd;
  IERC20 internal forkUsdt;
  IERC20 internal forkUsdc;
  IERC20 internal forkAlpaca;

  ChainlinkPriceFeedInterface internal forkBusdPriceFeed;
  ChainlinkPriceFeedInterface internal forkWbtcPriceFeed;
  ChainlinkPriceFeedInterface internal forkBnbPriceFeed;

  bytes32 internal forkBtcbPythPriceId;
  bytes32 internal forkWbnbPythPriceId;
  bytes32 internal forkEthPythPriceId;
  bytes32 internal forkUsdtPythPriceId;
  bytes32 internal forkUsdcPythPriceId;

  AccessControlFacetInterface internal forkPoolAccessControlFacet;

  PoolRouter04 forkPoolRouter04;
  Orderbook02 forkOrderBook02;
  Paradeen forkParadeen;
  AP forkAp;
  PoolOracle forkPoolOracle;
  RewardDistributor forkRewardDistributor;
  PythPriceFeed forkPythPriceFeed;
  IPancakeV3Router forkPancakeV3Router;

  constructor() {
    forkProxyAdmin = ProxyAdmin(PROXY_ADMIN);

    forkBtcb = IERC20(BTCB_TOKEN);
    forkEth = IERC20(ETH_TOKEN);
    forkWbnb = IERC20(WBNB_TOKEN);
    forkUsdt = IERC20(USDT_TOKEN);
    forkUsdc = IERC20(USDC_TOKEN);
    forkBusd = IERC20(BUSD_TOKEN);
    forkAlpaca = IERC20(ALPACA_TOKEN);

    forkBusdPriceFeed = ChainlinkPriceFeedInterface(BUSD_CHAINLINK_ORACLE);
    forkWbtcPriceFeed = ChainlinkPriceFeedInterface(WBTC_CHAINLINK_ORACLE);
    forkBnbPriceFeed = ChainlinkPriceFeedInterface(BNB_CHAINLINK_ORACLE);

    forkPoolAccessControlFacet =
      AccessControlFacetInterface(POOL_DIAMOND_ADDRESS);

    forkPoolRouter04 = PoolRouter04(payable(POOL_ROUTER_04));
    forkOrderBook02 = Orderbook02(payable(ORDER_BOOK));
    forkAp = AP(AP_ADDRESS);
    forkParadeen = Paradeen(PARADEEN);
    forkPoolOracle = PoolOracle(POOL_ORACLE);
    forkRewardDistributor = RewardDistributor(payable(REWARD_DISTRIBUTOR));
    forkPythPriceFeed = PythPriceFeed(payable(PYTH_PRICE_FEED));
    forkPancakeV3Router = IPancakeV3Router(payable(PANCAKE_V3_ROUTER));
  }

  function upgrade(address target, string memory contractName) internal {
    // Deploy new logic
    bytes memory logicBytecode = abi.encodePacked(
      vm.getCode(
        string(
          abi.encodePacked(
            "./out/", contractName, ".sol/", contractName, ".json"
          )
        )
      )
    );
    address logic;
    assembly {
      logic := create(0, add(logicBytecode, 0x20), mload(logicBytecode))
    }

    // Upgrade proxy to a new logic
    vm.prank(DEPLOYER, DEPLOYER);
    forkProxyAdmin.upgrade(TransparentUpgradeableProxy(payable(target)), logic);
  }
}
