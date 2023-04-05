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

/// OZ
import {IERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// Alperp
import {IAP} from "@alperp/interfaces/IAP.sol";

/// @title AP (Alperp Point) is a non-transferable ERC20-compatible token.
/// Build specifically for Alperp's liquidity/trade mining program.
contract AP is OwnableUpgradeable, IAP {
  /// Dependencies
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// Errors
  error AP_BulkClaimInvalidParams();
  error AP_NotMinter();
  error AP_NotRewardToken();
  error AP_AlreadyFed();
  error AP_FeedInvalidWeekTimestamp();
  error AP_BulkFeedInvalidParams();
  error AP_InvalidClaim();
  error AP_Unsupported();

  /// Constants
  uint256 public constant WEEK = 7 days;

  /// ERC20 standard extension.
  string public constant name = "Alperp Point";
  string public constant symbol = "AP";
  uint8 public constant decimals = 18;

  /// @notice mapping(minter => isAllow)
  mapping(address => bool) public isMinter;
  /// @notice mapping(epoch => totalSupply)
  mapping(uint256 => uint256) public weeklyTotalSupply;
  /// @notice mapping(epoch => mapping(account => points))
  mapping(uint256 => mapping(address => uint256)) public weeklyBalanceOf;

  event SetMinter(address _minter, bool _newAllow);
  event Mint(uint256 _weekTimestamp, address _to, uint256 _amount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  modifier onlyMinter() {
    if (!isMinter[msg.sender]) revert AP_NotMinter();
    _;
  }

  /// @notice Return the total supply of the current epoch.
  function totalSupply() external view returns (uint256) {
    return weeklyTotalSupply[_floorCurrentWeek()];
  }

  /// @notice Return the balance of the given address in the current epoch.
  function balanceOf(address _account) external view returns (uint256) {
    return weeklyBalanceOf[_floorCurrentWeek()][_account];
  }

  /// @notice ERC20-compatible transfer function. Disabled.
  function transfer(address, /* _to */ uint256 /* _amount */ )
    external
    pure
    override
    returns (bool)
  {
    revert AP_Unsupported();
  }

  /// @notice ERC20-compatible allowance function.
  /// @dev Always return 0 due to the fact that AP is non-transferable.
  function allowance(address, /* owner*/ address /* spender*/ )
    external
    pure
    override
    returns (uint256)
  {
    return 0;
  }

  /// @notice ERC20-compatible approve function. Disabled.
  function approve(address, /* _spender */ uint256 /* _amount */ )
    external
    pure
    override
    returns (bool)
  {
    revert AP_Unsupported();
  }

  /// @notice ERC20-compatible transferFrom function. Disabled.
  function transferFrom(
    address,
    /* _from */
    address,
    /* _to */
    uint256 /* _amount */
  ) external pure override returns (bool) {
    revert AP_Unsupported();
  }

  /// @notice Return floor week timestamp.
  function _floorCurrentWeek() internal view returns (uint256) {
    return (block.timestamp / WEEK) * WEEK;
  }

  /// @notice Allow minter to mint AP.
  /// @param _minter The address to allow minting.
  /// @param _allow Whether to allow or disallow.
  function setMinter(address _minter, bool _allow) external onlyOwner {
    isMinter[_minter] = _allow;
    emit SetMinter(_minter, _allow);
  }

  /// @notice Mint AP to the given address.
  /// @dev Only minter can call this function.
  /// @param _to The address to mint AP to.
  /// @param _amount The amount of AP to mint.
  function mint(address _to, uint256 _amount) public onlyMinter {
    uint256 weekCursor = _floorCurrentWeek();

    // accounting weekly amount
    weeklyTotalSupply[weekCursor] += _amount;
    unchecked {
      // overflow not possible as user's balance is always less than total supply
      weeklyBalanceOf[weekCursor][_to] += _amount;
    }

    // Log
    emit Transfer(address(0), _to, _amount);
    emit Mint(weekCursor, _to, _amount);
  }
}
