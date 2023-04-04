// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// OZ
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Alperp
import {AP} from "@alperp/trade-mining/AP.sol";

contract Paradeen is Initializable, OwnableUpgradeable {
  /// Dependencies
  using SafeERC20 for IERC20;

  /// Constants
  uint256 public constant VERSION = 1;
  uint256 public constant WEEK = 7 days;

  /// States
  uint256 public startWeekCursor;
  bool public isKilled;
  mapping(address => uint256) public weekCursorOf;
  uint256 internal _lock;

  /// Configs
  AP public ap;
  IERC20 public rewardToken;
  mapping(uint256 => uint256) public tokensPerWeek;
  address public emergencyReturn;

  /// Events
  event Claim(address _user, uint256 _amount);
  event Feed(uint256 _timestamp, uint256 _amount);
  event Kill();
  event SetEmergencyReturn(
    address _prevEmergencyReturn, address _newEmergencyReturn
  );

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    AP _ap,
    uint256 _startWeekCursor,
    IERC20 _rewardToken,
    address _emergencyReturn
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    ap = _ap;
    startWeekCursor = _floorTimestamp(_startWeekCursor);
    rewardToken = _rewardToken;
    emergencyReturn = _emergencyReturn;
  }

  modifier onlyLive() {
    require(!isKilled, "killed");
    _;
  }

  modifier lock() {
    require(_lock == 0, "locked");
    _lock = 1;
    _;
    _lock = 0;
  }

  /// @notice Round down timestamp to nearest week.
  /// @param _timestamp Timestamp to round down.
  function _floorTimestamp(uint256 _timestamp) internal pure returns (uint256) {
    return _timestamp / WEEK * WEEK;
  }

  /// @notice Feed reward tokens to the contract.
  /// @param _timestamps Timestamps of the rewards.
  /// @param _amounts Amounts of the rewards.
  function feed(uint256[] memory _timestamps, uint256[] memory _amounts)
    external
    onlyLive
  {
    require(_timestamps.length == _amounts.length, "bad len");

    // assign amount to each week
    for (uint256 i = 0; i < _timestamps.length;) {
      uint256 _timestamp = _floorTimestamp(_timestamps[i]);
      rewardToken.safeTransferFrom(msg.sender, address(this), _amounts[i]);
      tokensPerWeek[_timestamp] += _amounts[i];
      emit Feed(_timestamp, _amounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  /// @notice Claim reward tokens.
  /// @param _user User to claim reward tokens.
  function claim(address _user) external onlyLive lock returns (uint256) {
    uint256 _startWeekCursor = startWeekCursor;
    uint256 _userWeekCursor = weekCursorOf[_user];
    uint256 _rewards = 0;
    uint256 _maxClaimTimestamp = _floorTimestamp(block.timestamp);

    // If user's week cursor is before start week cursor,
    // only start reward calculation from "_startWeekCursor".
    if (_userWeekCursor < _startWeekCursor) {
      _userWeekCursor = _startWeekCursor;
    }

    // Go through each week from user's week cursor to 52 weeks later.
    for (uint256 _i = 0; _i < 52;) {
      // If user's week cursor is reached to max claim timestamp, then stop.
      if (_userWeekCursor >= _maxClaimTimestamp) {
        break;
      }

      // If not reach then, calculate rewards.
      uint256 _balance = ap.weeklyBalanceOf(_userWeekCursor, _user);
      if (_balance > 0) {
        uint256 _totalSupply = ap.weeklyTotalSupply(_userWeekCursor);
        _rewards += tokensPerWeek[_userWeekCursor] * _balance / _totalSupply;
      }

      _userWeekCursor += WEEK;

      unchecked {
        ++_i;
      }
    }

    // Update user's week cursor
    weekCursorOf[_user] = _userWeekCursor;
    // Transfer reward tokens
    rewardToken.safeTransfer(_user, _rewards);

    emit Claim(_user, _rewards);

    return _rewards;
  }

  /// @notice Kill the contract. Disabled all functions.
  function kill() external onlyOwner {
    isKilled = true;
    rewardToken.safeTransfer(
      emergencyReturn, rewardToken.balanceOf(address(this))
    );
    emit Kill();
  }

  function setEmergencyReturn(address _emergencyReturn) external onlyOwner {
    emit SetEmergencyReturn(emergencyReturn, _emergencyReturn);
    emergencyReturn = _emergencyReturn;
  }
}
