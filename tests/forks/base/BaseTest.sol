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

/// Alperp
import {PythPriceFeed} from "@alperp/core/PythPriceFeed.sol";
import {PoolRouter04} from "@alperp/periphery/pool-routers/PoolRouter04.sol";
import {Orderbook02} from "@alperp/periphery/limit-orders/Orderbook02.sol";
import {AP} from "@alperp/trade-mining/AP.sol";
import {Paradeen} from "@alperp/trade-mining/Paradeen.sol";
import {PoolOracle} from "@alperp/core/PoolOracle.sol";

/// Alperp Tests
import {BaseTest} from "@alperp-tests/base/BaseTest.sol";
import {VM} from "@alperp-tests/utils/VM.sol";
import {DSTest} from "@alperp-tests/base/DSTest.sol";
import {Config} from "@alperp-tests/forks/base/Config.sol";

/// OZ
import {ProxyAdmin} from
  "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

/// Pyth
import {MockPyth as FakePyth} from "@pythnetwork/pyth-sdk-solidity/MockPyth.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

abstract contract ForkBaseTest is BaseTest, Config {
  address internal constant EVE = address(0x888888);
}
