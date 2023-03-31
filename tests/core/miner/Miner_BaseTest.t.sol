// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity >=0.8.4 <0.9.0;

import { BaseTest, Miner, AP, PoolRouter04, Orderbook02 } from "../../base/BaseTest.sol";

abstract contract Miner_BaseTest is BaseTest {
  Miner internal miner;
  AP internal miningPoint;
  PoolRouter04 internal poolRouter;
  Orderbook02 internal orderbook;

  function setUp() public virtual {
    poolRouter = deployPoolRouter(address(0), address(0), address(0));

    orderbook = deployOrderbook(
      address(0),
      address(0),
      address(0),
      0.01 ether,
      1 ether,
      address(0)
    );

    miner = deployMiner();

    miningPoint = deployAP();
    miningPoint.setMinter(address(miner), true);
  }
}
