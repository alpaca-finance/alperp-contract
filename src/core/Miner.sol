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

pragma solidity 0.8.17;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IMiner } from "../interfaces/IMiner.sol";
import { IMiningPoint } from "../interfaces/IMiningPoint.sol";

contract Miner is IMiner, OwnableUpgradeable {
  uint256 startTimestamp;
  uint256 endTimestamp;
  mapping(address => bool) public isWhitelist;

  IMiningPoint miningPoint;

  event Miner_SetWhitelist(address whitelisted, bool _newAllow);
  event Miner_SetPoint(address _newApAddr);
  event Miner_SetPeriod(uint256 _startTimestamp, uint256 _endTimestamp);

  error Miner_InvlidMiningPoint();
  error Miner_NotWhitelisted();
  error Miner_InvlidPeriod();

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  modifier onlyWhitelisted() {
    if (!isWhitelist[msg.sender]) revert Miner_NotWhitelisted();
    _;
  }

  function setWhitelist(address _whitelisted, bool _allow) external onlyOwner {
    isWhitelist[_whitelisted] = _allow;

    emit Miner_SetWhitelist(_whitelisted, _allow);
  }

  function setPeriod(uint256 _startTimestamp, uint256 _endTimestamp)
    external
    onlyOwner
  {
    if (_endTimestamp < _startTimestamp) {
      revert Miner_InvlidPeriod();
    }

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;

    emit Miner_SetPeriod(_startTimestamp, _endTimestamp);
  }

  function setMiningPoint(address _miningPoint) external onlyOwner {
    miningPoint = IMiningPoint(_miningPoint);

    emit Miner_SetPoint(_miningPoint);
  }

  function increasePosition(
    address _primaryAccount,
    uint256,
    address,
    address,
    uint256 _sizeDelta,
    uint256,
    bool
  ) external onlyWhitelisted {
    if (address(miningPoint) == address(0)) {
      revert Miner_InvlidMiningPoint();
    }

    if (block.timestamp < startTimestamp || block.timestamp > endTimestamp) {
      return;
    }

    miningPoint.mint(_primaryAccount, _sizeDelta);

    return;
  }

  /// @dev thoese function below
  /// just implement for the other campagin future
  /// not use as of now
  function decreasePosition(
    address,
    uint256,
    address,
    address,
    uint256,
    uint256,
    bool
  ) external view onlyWhitelisted {
    return;
  }

  function liquidatePosition(
    address,
    uint256,
    address,
    address,
    uint256,
    uint256,
    bool
  ) external view onlyWhitelisted {
    return;
  }

  function swap(
    address,
    address,
    address,
    uint256,
    uint256
  ) external view onlyWhitelisted {
    return;
  }

  function addLiquidity(
    address,
    address,
    uint256,
    uint256,
    address
  ) external view onlyWhitelisted {
    return;
  }

  function removeLiquidity(
    address,
    address,
    uint256, // ALP amount
    uint256,
    address
  ) external view onlyWhitelisted {
    return;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
