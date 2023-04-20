// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// OZ
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// Alperp
import {PythPriceFeed} from "@alperp/core/PythPriceFeed.sol";
import {PerpTradeFacetInterface} from "@alperp/core/pool-diamond/interfaces/PerpTradeFacetInterface.sol";

contract LiquidationRouter01 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
  /// Configs
  address public pool;
  PythPriceFeed public pythPriceFeed;
  mapping(address => bool) public liquidators;

  /// Events
  event SetLiquidator(
    address liquidator, bool prevIsLiquidator, bool newIsLiquidator
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address pool_, PythPriceFeed pythPriceFeed_)
    public
    initializer
  {
    OwnableUpgradeable.__Ownable_init();

    pool = pool_;
    pythPriceFeed = pythPriceFeed_;
  }

  /// @notice Set liquidator. Only owner can call this function.
  /// @param liquidator The address of liquidator.
  /// @param isLiquidator Whether the address is liquidator.
  function setLiquidator(address liquidator, bool isLiquidator)
    external
    onlyOwner
  {
    emit SetLiquidator(liquidator, liquidators[liquidator], isLiquidator);
    liquidators[liquidator] = isLiquidator;
  }

  /// @notice Check if the position is liquidatable with force update pyth price.
  /// @dev This should be called using .callstatic
  function checkLiquidation(
    bytes[] calldata priceData,
    address account,
    address collateralToken,
    address indexToken,
    bool isLong
  )
    external
    payable
    returns (PerpTradeFacetInterface.LiquidationState, uint256, uint256, int256)
  {
    // Check
    require(liquidators[msg.sender], "!liquidator");

    // Update price
    uint256 oracleUpdateFee = pythPriceFeed.getUpdateFee(priceData);
    // Check if msg.value is enough
    require(msg.value >= oracleUpdateFee, "fee");
    // Perform the actual update prices, from here the price is updated
    pythPriceFeed.updatePrices{value: oracleUpdateFee}(priceData);

    // Check liquidation & return
    return PerpTradeFacetInterface(pool).checkLiquidation(
      account, collateralToken, indexToken, isLong, false
    );
  }

  /// @notice Liquidate a position. Only liquidator can call this function.
  function liquidate(
    bytes[] calldata priceData,
    address primaryAccount,
    uint256 subAccountId,
    address collateralToken,
    address indexToken,
    bool isLong,
    address to
  ) external payable nonReentrant {
    // Check
    require(liquidators[msg.sender], "!liquidator");

    // Update price
    uint256 oracleUpdateFee = pythPriceFeed.getUpdateFee(priceData);
    // Check if msg.value is enough
    require(msg.value >= oracleUpdateFee, "fee");
    // Perform the actual update prices, from here the price is updated
    pythPriceFeed.updatePrices{value: oracleUpdateFee}(priceData);

    // Liquidate
    PerpTradeFacetInterface(pool).liquidate(
      primaryAccount, subAccountId, collateralToken, indexToken, isLong, to
    );
  }
}
