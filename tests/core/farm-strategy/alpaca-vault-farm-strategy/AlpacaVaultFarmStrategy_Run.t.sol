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

contract AlpacaVaultFarmStrategy_Run is AlpacaVaultFarmStrategy_BaseTest {
  function setUp() public override {
    super.setUp();

    randomErc20.mint(address(this), 100 ether);
    randomErc20.mint(mockPoolAddress, 100 ether);
  }

  function testRun_whenCallerIsNotWhitelistedPool() external {
    vm.expectRevert(abi.encodeWithSignature("NotWhitelistedPool()"));
    farmStrategy.run(10 ether);
  }

  function testRun_whenAmountIsInsufficient() external {
    vm.expectRevert("AlpacaFarmStrategy: Insufficient amount to deposit");

    vm.prank(mockPoolAddress);
    farmStrategy.run(10 ether);
  }

  function testRun_shouldDepositTokenIntoVaultProperly() external {
    randomErc20.transfer(address(farmStrategy), 10 ether);

    assertEq(randomErc20.balanceOf(address(farmStrategy)), 10 ether);
    assertEq(randomErc20.balanceOf(address(mockVault)), 0);

    vm.prank(mockPoolAddress);
    farmStrategy.run(10 ether);

    assertEq(randomErc20.balanceOf(address(farmStrategy)), 0);
    assertEq(randomErc20.balanceOf(address(mockVault)), 10 ether);
  }
}
