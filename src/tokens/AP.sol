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

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IMiningPoint } from "../interfaces/IMiningPoint.sol";

contract AP is ERC20Upgradeable, OwnableUpgradeable, IMiningPoint {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  struct AccountInfo {
    uint256 amount;
    bool isClaimed;
  }

  uint256 public latestIndex;
  /// @dev mapping(index => weekTimestamp)
  mapping(uint256 => uint256) public indexWeekTimestamp;

  mapping(address => bool) public isRewardToken;
  mapping(address => bool) public isMinter;

  /// @dev mapping(weekTimestamp => totalSupply)
  mapping(uint256 => uint256) public weeklyTotalSupply;
  /// @dev mapping(weekTimestamp => mapping(rewardToken => amount))
  mapping(uint256 => mapping(address => uint256))
    public weeklyRewardTokenBalanceOf;
  /// @dev mapping(weekTimestamp => mapping(account => AccountInfo))
  mapping(uint256 => mapping(address => AccountInfo))
    public weeklyAccountBalanceOf;

  event AP_SetMinter(address _minter, bool _newAllow);
  event AP_SetRewardToken(address _rewardToken, bool _newAllow);
  event AP_Mint(uint256 _weekTimestamp, address _to, uint256 _amount);
  event AP_FeedRewardToken(
    uint256 _weekTimestamp,
    address _rewardToken,
    uint256 _amount
  );
  event AP_Claim(
    uint256 _weekTimestamp,
    address _to,
    uint256 _pointAmount,
    uint256 _rewardAmount
  );
  event EmergencyWithdraw(
    address _rewardToken,
    address _receiver,
    uint256 _amount
  );

  error AP_BulkClaimInvalidParams();
  error AP_NotMinter();
  error AP_NotRewardToken();
  error AP_AlreadyFed();
  error AP_FeedInvalidWeekTimestamp();
  error AP_BulkFeedInvalidParams();
  error AP_InvalidClaim();
  error AP_Unsupported();

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
    ERC20Upgradeable.__ERC20_init("Alperp Point", "AP");
  }

  modifier onlyMinter() {
    if (!isMinter[msg.sender]) revert AP_NotMinter();
    _;
  }

  function _parseWeekTimestamp(uint256 _timestamp)
    internal
    pure
    returns (uint256)
  {
    return _timestamp / (1 weeks);
  }

  function setMinter(address _minter, bool _allow) external onlyOwner {
    isMinter[_minter] = _allow;
    emit AP_SetMinter(_minter, _allow);
  }

  function setRewardToken(address _rewardToken, bool _allow)
    external
    onlyOwner
  {
    isRewardToken[_rewardToken] = _allow;
    emit AP_SetRewardToken(_rewardToken, _allow);
  }

  function mint(address _to, uint256 _amount) public onlyMinter {
    uint256 weekTimestamp = _parseWeekTimestamp(block.timestamp);

    // accounting weekly amount
    weeklyTotalSupply[weekTimestamp] =
      weeklyTotalSupply[weekTimestamp] +
      _amount;
    weeklyAccountBalanceOf[weekTimestamp][_to].amount = _amount;

    _mint(_to, _amount);

    emit AP_Mint(weekTimestamp, _to, _amount);
  }

  function _feed(
    uint256 _weekTimestamp,
    address _rewardToken,
    uint256 _amount
  ) public onlyMinter {
    if (_weekTimestamp >= _parseWeekTimestamp(block.timestamp)) {
      revert AP_FeedInvalidWeekTimestamp();
    }

    if (!isRewardToken[_rewardToken]) {
      revert AP_NotRewardToken();
    }

    if (weeklyRewardTokenBalanceOf[_weekTimestamp][_rewardToken] != 0) {
      revert AP_AlreadyFed();
    }

    // accounting
    weeklyRewardTokenBalanceOf[_weekTimestamp][_rewardToken] = _amount;

    // transfer
    IERC20Upgradeable(_rewardToken).safeTransferFrom(
      msg.sender,
      address(this),
      _amount
    );

    // update indexing
    indexWeekTimestamp[latestIndex] = _weekTimestamp;
    latestIndex += 1;

    emit AP_FeedRewardToken(_weekTimestamp, _rewardToken, _amount);
  }

  function feed(
    uint256 _weekTimestamp,
    address _rewardToken,
    uint256 _amount
  ) public onlyMinter {
    _feed(_weekTimestamp, _rewardToken, _amount);
  }

  function bulkFeed(
    uint256[] memory _weekTimestamps,
    address[] memory _rewardTokens,
    uint256[] memory _amounts
  ) public onlyMinter {
    if (
      _weekTimestamps.length != _rewardTokens.length ||
      _weekTimestamps.length != _amounts.length
    ) {
      revert AP_BulkFeedInvalidParams();
    }

    for (uint256 i = 0; i < _weekTimestamps.length; i++) {
      _feed(_weekTimestamps[i], _rewardTokens[i], _amounts[i]);
    }
  }

  function _claim(
    uint256 _weekTimestamp,
    address _rewardToken,
    address _to
  ) public {
    AccountInfo memory accountAmount = weeklyAccountBalanceOf[_weekTimestamp][
      _to
    ];
    if (accountAmount.amount == 0 || accountAmount.isClaimed) {
      revert AP_InvalidClaim();
    }

    // calculate reward sharing
    uint256 reward = (accountAmount.amount *
      weeklyRewardTokenBalanceOf[_weekTimestamp][_rewardToken]) /
      weeklyTotalSupply[_weekTimestamp];

    // transfer
    IERC20Upgradeable(_rewardToken).safeTransfer(_to, reward);

    // then burn
    _burn(_to, accountAmount.amount);

    // update claim
    weeklyAccountBalanceOf[_weekTimestamp][_to].isClaimed = true;

    emit AP_Claim(_weekTimestamp, _to, accountAmount.amount, reward);
  }

  function claim(
    uint256 _weekTimestamp,
    address _rewardToken,
    address _to
  ) public {
    _claim(_weekTimestamp, _rewardToken, _to);
  }

  function bulkClaim(
    uint256[] memory _weekTimestamps,
    address[] memory _rewardTokens,
    address[] memory _tos
  ) public {
    if (
      _weekTimestamps.length != _rewardTokens.length ||
      _weekTimestamps.length != _tos.length
    ) {
      revert AP_BulkClaimInvalidParams();
    }

    for (uint256 i = 0; i < _weekTimestamps.length; i++) {
      _claim(_weekTimestamps[i], _rewardTokens[i], _tos[i]);
    }
  }

  function emergencyWithdraw(address _rewardToken, address _receiver)
    external
    onlyOwner
  {
    IERC20Upgradeable rewardTokenContract = IERC20Upgradeable(_rewardToken);
    uint256 balance = rewardTokenContract.balanceOf(address(this));
    rewardTokenContract.safeTransfer(_receiver, balance);

    emit EmergencyWithdraw(_rewardToken, _receiver, balance);
  }

  function _transfer(
    address,
    address,
    uint256
  ) internal pure override {
    revert AP_Unsupported();
  }

  function _approve(
    address,
    address,
    uint256
  ) internal pure override {
    revert AP_Unsupported();
  }
}
