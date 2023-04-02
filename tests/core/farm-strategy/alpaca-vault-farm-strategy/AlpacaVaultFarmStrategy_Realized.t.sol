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
  AlpacaVaultFarmStrategy_BaseTest,
  console,
  stdError,
  AlpacaVaultFarmStrategy,
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
  MockStrategy,
  MockDonateVault,
  ALP
} from "./AlpacaVaultFarmStrategy_BaseTest.t.sol";

contract AlpacaVaultFarmStrategy_Realized is AlpacaVaultFarmStrategy_BaseTest {
  function setUp() public override {
    super.setUp();

    randomErc20.mint(address(this), 100 ether);
  }

  function testRealized_whenCallerIsNotWhitelistedPool() external {
    vm.expectRevert(abi.encodeWithSignature("NotWhitelistedPool()"));
    farmStrategy.realized(10 ether);
  }

  function testRealized_whenProfit() external {
    randomErc20.transfer(address(farmStrategy), 10 ether);

    vm.prank(mockPoolAddress);
    farmStrategy.run(10 ether);

    assertEq(randomErc20.balanceOf(address(mockPoolAddress)), 0);

    vm.prank(mockPoolAddress);
    int256 delta = farmStrategy.realized(8 ether);

    assertEq(randomErc20.balanceOf(address(mockPoolAddress)), 2 ether);
    assertEq(delta, 2 ether);
  }

  function testRealized_whenLoss() external {
    vm.prank(mockPoolAddress);

    assertEq(randomErc20.balanceOf(address(mockPoolAddress)), 0);

    vm.prank(mockPoolAddress);
    int256 delta = farmStrategy.realized(10 ether);

    assertEq(randomErc20.balanceOf(address(mockPoolAddress)), 0);

    assertEq(delta, -10 ether);
  }
}
