// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// OZ
import {ReentrancyGuardUpgradeable} from
  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Alperp
import {PythPriceFeed} from "@alperp/core/PythPriceFeed.sol";
import {MarketOrderRouter} from
  "@alperp/periphery/market-orders/MarketOrderRouter.sol";

contract MarketOrderExecutor is OwnableUpgradeable, ReentrancyGuardUpgradeable {
  PythPriceFeed public pythPriceFeed;
  MarketOrderRouter public marketOrderRouter;
  mapping(address => bool) public isExecutor;

  event SetExecutor(address executor, bool prevIsExecutor, bool newIsExecutor);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _pythPriceFeed, address _marketOrderRouter)
    external
    initializer
  {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    pythPriceFeed = PythPriceFeed(payable(_pythPriceFeed));
    marketOrderRouter = MarketOrderRouter(payable(_marketOrderRouter));
  }

  function setExecutor(address executor, bool isExecutor_) external onlyOwner {
    emit SetExecutor(executor, isExecutor[executor], isExecutor_);
    isExecutor[executor] = isExecutor_;
  }

  function execute(
    uint256 increasePositionsEndIndex,
    uint256 decreasePositionsEndIndex,
    bytes[] calldata pythUpdateDataChecksum,
    address[] calldata tokens,
    uint256[] calldata prices,
    address payable feeTo
  ) external {
    // Check if the caller is an executor
    require(isExecutor[msg.sender], "!executor");

    // Update pyth price feed
    pythPriceFeed.setCachedPrices(pythUpdateDataChecksum, tokens, prices);

    // Execute market orders
    marketOrderRouter.executeIncreasePositions(increasePositionsEndIndex, feeTo);
    marketOrderRouter.executeDecreasePositions(decreasePositionsEndIndex, feeTo);
  }
}
