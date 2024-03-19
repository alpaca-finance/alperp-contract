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

import {OwnableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ITradeMiningManager} from "@alperp/interfaces/ITradeMiningManager.sol";
import {IAP} from "@alperp/interfaces/IAP.sol";

contract TradeMiningManager is ITradeMiningManager, OwnableUpgradeable {
  /// Errors
  error TradeMiningManager_NotWhitelisted();
  error TradeMiningManager_InvalidPeriod();
  error TradeMiningManager_InvalidEndTimestamp();

  /// Configs
  /// @notice The start timestamp of the period
  uint64 public startTimestamp;
  /// @notice The end timestamp of the period
  uint64 public endTimestamp;
  /// @notice mapping(authorized address => allowFlag)
  mapping(address => bool) public authed;
  /// @notice AP (Alpaca Point) contract
  IAP public alpacaPoint;

  event TradeMiningManager_SetAuth(
    address _user, bool _prevAuth, bool _newAuth
  );
  event TradeMiningManager_SetAp(address _prevAp, address _newAp);
  event TradeMiningManager_SetPeriod(
    uint64 _prevStartTimestamp,
    uint64 _prevEndTimestamp,
    uint64 _newStartTimestamp,
    uint64 _newEndTimestamp
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(IAP _ap) external initializer {
    OwnableUpgradeable.__Ownable_init();
    alpacaPoint = _ap;
  }

  /// @notice Only allow authed msg.sender to call the function
  modifier onlyAuth() {
    if (!authed[msg.sender]) revert TradeMiningManager_NotWhitelisted();
    _;
  }

  /// @notice Authorize a address to call privileged functions
  /// @param _user The address to be authorized
  /// @param _allow Whether to allow or disallow the address
  function setAuth(address _user, bool _allow) external onlyOwner {
    emit TradeMiningManager_SetAuth(_user, authed[_user], _allow);
    authed[_user] = _allow;
  }

  /// @notice Set the period of trade mining
  /// @param _startTimestamp The start timestamp of the period
  /// @param _endTimestamp The end timestamp of the period
  function setPeriod(uint64 _startTimestamp, uint64 _endTimestamp)
    external
    onlyOwner
  {
    if (_endTimestamp < _startTimestamp) {
      revert TradeMiningManager_InvalidPeriod();
    }
    if (_endTimestamp <= block.timestamp) {
      revert TradeMiningManager_InvalidEndTimestamp();
    }

    emit TradeMiningManager_SetPeriod(
      startTimestamp, endTimestamp, _startTimestamp, _endTimestamp
    );
    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
  }

  /// @notice Set trade mining point
  /// @param _ap The address of the TMP
  function setAp(IAP _ap) external onlyOwner {
    emit TradeMiningManager_SetAp(address(alpacaPoint), address(_ap));
    alpacaPoint = _ap;
  }

  /// @notice On increase position. Trigger when trader increase position.
  /// @dev Mint AP to the trader if it's in the period.
  /// @param _primaryAccount The primary account of the position
  /// @param _sizeDelta The size delta of the position (in USD 1e30)
  function onIncreasePosition(
    address _primaryAccount,
    uint256,
    address,
    address,
    uint256 _sizeDelta,
    bool
  ) external onlyAuth {
    // Check if it's in the period
    if (block.timestamp < startTimestamp || block.timestamp > endTimestamp) {
      // Not in the period, then do nothing
      return;
    }

    // Mint AP to the trader
    // Convert 1e30 -> 1e18 => / 1e12
    alpacaPoint.mint(_primaryAccount, _sizeDelta / 1e12);
  }

  /// @notice On decrease position. NOT IMPLEMENTED. Reserved for future use.
  function onDecreasePosition(
    address _primaryAccount,
    uint256,
    address,
    address,
    uint256 _sizeDelta,
    bool
  ) external onlyAuth {
    // Check if it's in the period
    if (block.timestamp < startTimestamp || block.timestamp > endTimestamp) {
      // Not in the period, then do nothing
      return;
    }

    // Mint AP to the trader
    // Convert 1e30 -> 1e18 => / 1e12
    alpacaPoint.mint(_primaryAccount, _sizeDelta / 1e12);
  }

  /// @notice On liquidate position. NOT IMPLEMENTED. Reserved for future use.
  function onLiquidatePosition(
    address,
    uint256,
    address,
    address,
    uint256,
    bool
  ) external view onlyAuth {
    return;
  }

  /// @notice On swap. NOT IMPLEMENTED. Reserved for future use.
  function onSwap(address, address, address, uint256, uint256)
    external
    view
    onlyAuth
  {
    return;
  }

  /// @notice On add liquidity. NOT IMPLEMENTED. Reserved for future use.
  function onAddLiquidity(address, address, uint256, uint256, address)
    external
    view
    onlyAuth
  {
    return;
  }

  /// @notice On remove liquidity. NOT IMPLEMENTED. Reserved for future use.
  function onRemoveLiquidity(
    address,
    address,
    uint256, // ALP amount
    uint256,
    address
  ) external view onlyAuth {
    return;
  }
}
