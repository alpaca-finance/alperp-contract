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

import {IERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {MerkleAirdrop} from "../airdrop/MerkleAirdrop.sol";
import {AdminFacetInterface} from
  "../core/pool-diamond/interfaces/AdminFacetInterface.sol";
import {GetterFacetInterface} from
  "../core/pool-diamond/interfaces/GetterFacetInterface.sol";
import {IPoolRouter} from "../interfaces/IPoolRouter.sol";
import {IFeedableRewarder} from "./interfaces/IFeedableRewarder.sol";
import {IPancakeV3Router} from "@alperp/interfaces/IPancakeV3Router.sol";
import {IOnchainPriceUpdater} from "@alperp/interfaces/IOnChainPriceUpdater.sol";

contract RewardDistributor is OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @dev constant
  uint256 constant MAX_BPS = 10000;

  /// @dev Token addreses
  address public rewardToken; // the token to be fed to rewarder

  /// @dev Pool and its companion addresses
  address public pool;
  address public poolRouter;
  address public alpStakingProtocolRevenueRewarder;

  /// @dev Distribution weight
  uint256 public alpStakingBps;
  uint256 public devFundBps;
  uint256 public govBps;
  uint256 public burnBps; // burnBps will be assumed as 10000 - alpStakingBps - devFundBps - govBps = burnBps

  /// @dev Fund addresses
  address public devFundAddress;
  address public govFeeder;
  address public burner;

  MerkleAirdrop public merkleAirdrop;

  uint256 public referralRevenueMaxThreshold; // in BPS (10000)

  address public feeder;

  /// Extension configs
  IOnchainPriceUpdater public pythPriceFeed;
  IPancakeV3Router public router;
  mapping(address => mapping(address => bytes)) public pathOf;

  /// @dev Error
  error RewardDistributor_BadParams();
  error RewardDistributor_BadReferralRevenueMaxThreshold();
  error RewardDistributor_BadMerkleAirdrop(
    bytes32 merkleRoote, bytes32 salt, address merkleAirdropAddress
  );
  error RewardDistributor_ReferralRevenueExceedMaxThreshold();
  error RewardDistributor_NotFeeder();
  error RewardDistributor_BadBpsSetting();

  /// @dev Events
  event LogSetParams(
    address rewardToken,
    address pool,
    address poolRouter,
    address alpStakingProtocolRevenueRewarder,
    uint256 alpStakingBps,
    address devFundAddress,
    uint256 devFundBps,
    address govFeeder,
    uint256 govBps,
    address burner,
    uint256 burnBps,
    address merkleAirdrop
  );
  event LogSetReferralRevenueMaxThreshold(
    uint256 oldThreshold, uint256 newThreshold
  );
  event LogSetFeeder(address oldFeeder, address newFeeder);
  event LogProtocolFee(
    uint256 weekTimestamp,
    uint256 referralAmount,
    uint256 stakingAmount,
    uint256 devFundAmount,
    uint256 govAmount,
    uint256 burnerAmount
  );
  event LogSetRouter(IPancakeV3Router oldRouter, IPancakeV3Router newRouter);
  event LogSetPathOf(
    address token0, address token1, bytes oldPath, bytes newPath
  );
  event LogSetPythPriceFeed(
    IOnchainPriceUpdater oldFeed, IOnchainPriceUpdater newFeed
  );
  event LogAlpSwapSuccess();
  event LogAlpSwapFailed();

  modifier onlyFeeder() {
    if (msg.sender != feeder) revert RewardDistributor_NotFeeder();
    _;
  }

  function initialize(
    address rewardToken_,
    address pool_,
    address poolRouter_,
    address alpStakingProtocolRevenueRewarder_,
    uint256 alpStakingBps_,
    address devFundAddress_,
    uint256 devFundBps_,
    address govFeeder_,
    uint256 govBps_,
    address burner_,
    MerkleAirdrop merkleAirdrop_,
    uint256 referralRevenueMaxThreshold_
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    if (MAX_BPS < (alpStakingBps_ + devFundBps_ + govBps_)) {
      revert RewardDistributor_BadParams();
    }

    rewardToken = rewardToken_;
    pool = pool_;
    poolRouter = poolRouter_;
    alpStakingProtocolRevenueRewarder = alpStakingProtocolRevenueRewarder_;
    alpStakingBps = alpStakingBps_;
    devFundAddress = devFundAddress_;
    devFundBps = devFundBps_;
    govFeeder = govFeeder_;
    govBps = govBps_;
    burner = burner_;
    burnBps = MAX_BPS - (alpStakingBps_ + devFundBps_ + govBps_);
    merkleAirdrop = merkleAirdrop_;

    referralRevenueMaxThreshold = referralRevenueMaxThreshold_;
  }

  function setParams(
    address rewardToken_,
    address pool_,
    address poolRouter_,
    address alpStakingProtocolRevenueRewarder_,
    uint256 alpStakingBps_,
    address devFundAddress_,
    uint256 devFundBps_,
    address govFeeder_,
    uint256 govBps_,
    address burner_,
    MerkleAirdrop merkleAirdrop_
  ) external onlyOwner {
    if (MAX_BPS < (alpStakingBps_ + devFundBps_ + govBps_)) {
      revert RewardDistributor_BadParams();
    }

    rewardToken = rewardToken_;
    pool = pool_;
    poolRouter = poolRouter_;
    alpStakingProtocolRevenueRewarder = alpStakingProtocolRevenueRewarder_;
    alpStakingBps = alpStakingBps_;
    devFundBps = devFundBps_;
    devFundAddress = devFundAddress_;
    govFeeder = govFeeder_;
    govBps = govBps_;
    burner = burner_;
    burnBps = MAX_BPS - (alpStakingBps_ + devFundBps_ + govBps_);
    merkleAirdrop = merkleAirdrop_;

    emit LogSetParams(
      rewardToken_,
      pool_,
      poolRouter_,
      alpStakingProtocolRevenueRewarder_,
      alpStakingBps_,
      devFundAddress_,
      devFundBps_,
      govFeeder_,
      govBps_,
      burner_,
      burnBps,
      address(merkleAirdrop_)
    );
  }

  function setReferralRevenueMaxThreshold(
    uint256 newReferralRevenueMaxThreshold
  ) external onlyOwner {
    if (newReferralRevenueMaxThreshold > 9500) {
      // should not exceed 80% of total revenue
      revert RewardDistributor_BadReferralRevenueMaxThreshold();
    }
    emit LogSetReferralRevenueMaxThreshold(
      referralRevenueMaxThreshold, newReferralRevenueMaxThreshold
    );
    referralRevenueMaxThreshold = newReferralRevenueMaxThreshold;
  }

  function setFeeder(address newFeeder) external onlyOwner {
    emit LogSetFeeder(feeder, newFeeder);
    feeder = newFeeder;
  }

  function setRouter(IPancakeV3Router newRouter) external onlyOwner {
    emit LogSetRouter(router, newRouter);
    router = newRouter;
  }

  function setPathOf(
    address[] calldata t0s,
    address[] calldata t1s,
    bytes[] calldata paths
  ) external onlyOwner {
    require(
      t0s.length == t1s.length && t1s.length == paths.length,
      "RewardDistributor: bad params"
    );
    for (uint256 i = 0; i < t0s.length;) {
      emit LogSetPathOf(t0s[i], t1s[i], pathOf[t0s[i]][t0s[i]], paths[i]);

      pathOf[t0s[i]][t1s[i]] = paths[i];

      unchecked {
        ++i;
      }
    }
  }

  function setPythPriceFeed(IOnchainPriceUpdater newPythPriceFeed)
    external
    onlyOwner
  {
    emit LogSetPythPriceFeed(pythPriceFeed, newPythPriceFeed);
    pythPriceFeed = newPythPriceFeed;
  }

  function claimAndSwap(address[] memory tokens, bytes[] memory priceUpdateData)
    external
    payable
    onlyFeeder
  {
    _claimAndSwap(tokens, priceUpdateData);
  }

  function _claimAndSwap(
    address[] memory tokens,
    bytes[] memory priceUpdateData
  ) internal {
    uint256 length = tokens.length;

    // Update pyth price first
    uint256 fee = pythPriceFeed.getUpdateFee(priceUpdateData);
    pythPriceFeed.updatePrices{value: fee}(priceUpdateData);

    for (uint256 i = 0; i < length;) {
      // 1. Withdraw protocol revenue
      _withdrawProtocolRevenue(tokens[i]);
      // 2. Swap those revenue (along with surplus) to RewardToken Token
      _swapTokenToRewardToken(
        tokens[i], IERC20Upgradeable(tokens[i]).balanceOf(address(this))
      );

      unchecked {
        i++;
      }
    }
  }

  function claimAndFeedProtocolRevenue(
    address[] memory tokens,
    uint256 feedingExpiredAt,
    uint256 weekTimestamp,
    uint256 referralRevenueAmount,
    bytes32 merkleRoot,
    bytes[] memory priceUpdateData
  ) external payable onlyFeeder {
    _claimAndSwap(tokens, priceUpdateData);
    _feedProtocolRevenue(
      feedingExpiredAt, weekTimestamp, referralRevenueAmount, merkleRoot
    );
  }

  function _feedProtocolRevenue(
    uint256 feedingExpiredAt,
    uint256 weekTimestamp,
    uint256 referralRevenueAmount,
    bytes32 merkleRoot
  ) internal {
    // Transfer referral revenue to merkle airdrop address for distribution
    uint256 totalProtocolRevenue =
      IERC20Upgradeable(rewardToken).balanceOf(address(this));
    // totalProtocolRevenue * referralRevenueMaxThreshold / 10000 < referralRevenueAmount
    if (
      totalProtocolRevenue * referralRevenueMaxThreshold
        < referralRevenueAmount * MAX_BPS
    ) revert RewardDistributor_ReferralRevenueExceedMaxThreshold();

    if (referralRevenueAmount > 0) {
      merkleAirdrop.init(weekTimestamp, merkleRoot);
      IERC20Upgradeable(rewardToken).safeTransfer(
        address(merkleAirdrop), referralRevenueAmount
      );
    }

    // Calculate reward sharing
    (
      uint256 alpStakingRewardAmount,
      uint256 devFundAmount,
      uint256 govRewardAmount,
      uint256 burnAMount
    ) = _calculateRewardSharing();

    // Feed for protocol revenue.
    _feedRewardToRewarders(feedingExpiredAt, alpStakingRewardAmount);

    // Collect Dev Fund
    _collectDevFund(rewardToken, devFundAmount);

    // Collect Gov Reward
    _collectGovReward(rewardToken, govRewardAmount);

    // Collect Gov Reward
    _collectBurn(rewardToken, burnAMount);

    emit LogProtocolFee(
      weekTimestamp,
      referralRevenueAmount,
      alpStakingRewardAmount,
      devFundAmount,
      govRewardAmount,
      burnAMount
    );
  }

  function feedProtocolRevenue(
    uint256 feedingExpiredAt,
    uint256 weekTimestamp,
    uint256 referralRevenueAmount,
    bytes32 merkleRoot
  ) external onlyFeeder {
    _feedProtocolRevenue(
      feedingExpiredAt, weekTimestamp, referralRevenueAmount, merkleRoot
    );
  }

  function _withdrawProtocolRevenue(address token) internal {
    // Withdraw the all max amount revenue from the pool
    AdminFacetInterface(pool).withdrawFeeReserve(
      token, address(this), GetterFacetInterface(pool).feeReserveOf(token)
    );
  }

  function _calculateRewardSharing()
    internal
    view
    returns (uint256, uint256, uint256, uint256)
  {
    uint256 totalRewardAmount =
      IERC20Upgradeable(rewardToken).balanceOf(address(this));

    uint256 alpStakingRewardAmount =
      (totalRewardAmount * alpStakingBps) / MAX_BPS;
    uint256 devFundAmount = (totalRewardAmount * devFundBps) / MAX_BPS;
    uint256 govRewardAmount = (totalRewardAmount * govBps) / MAX_BPS;
    uint256 burnAMount = (totalRewardAmount * burnBps) / MAX_BPS;

    return (alpStakingRewardAmount, devFundAmount, govRewardAmount, burnAMount);
  }

  function _collectDevFund(address _token, uint256 _amount) internal {
    // If no token, no need transfer
    if (_amount == 0) return;

    IERC20Upgradeable(_token).safeTransfer(devFundAddress, _amount);
  }

  function _collectGovReward(address _token, uint256 _amount) internal {
    // If no token, no need transfer
    if (_amount == 0) return;

    IERC20Upgradeable(_token).safeTransfer(govFeeder, _amount);
  }

  function _collectBurn(address _token, uint256 _amount) internal {
    // If no token, no need transfer
    if (_amount == 0) return;

    IERC20Upgradeable(_token).safeTransfer(burner, _amount);
  }

  function _swapTokenToRewardToken(address token, uint256 amount) internal {
    // If no token, no need to swap
    if (amount == 0) return;

    // If token is already reward token, no need to swap
    if (token == rewardToken) return;

    // Approve the token
    IERC20Upgradeable token_ = IERC20Upgradeable(token);
    token_.approve(poolRouter, amount);

    // Swap
    // Try ALP swap first, if fail then swap on PancakeV3
    // No need to update pyth price here, because it's already updated in _claimAndSwap
    bytes[] memory data = new bytes[](0);
    try IPoolRouter(poolRouter).swap(
      token, rewardToken, amount, 0, address(this), data
    ) {
      emit LogAlpSwapSuccess();
    } catch {
      emit LogAlpSwapFailed();
      // Swap on PancakeV3
      // SLOAD vars
      bytes memory path_ = pathOf[token][rewardToken];
      require(path_.length != 0, "P");
      if (token_.allowance(address(this), address(router)) == 0) {
        token_.approve(address(router), type(uint256).max);
      }
      router.exactInput(
        (
          IPancakeV3Router.ExactInputParams({
            path: path_,
            recipient: address(this),
            amountIn: amount,
            amountOutMinimum: 0
          })
        )
      );
    }
  }

  function _feedRewardToRewarders(
    uint256 feedingExpiredAt,
    uint256 alpStakingRewardAmount
  ) internal {
    // Approve and feed to ALPStaking
    IERC20Upgradeable(rewardToken).approve(
      alpStakingProtocolRevenueRewarder, alpStakingRewardAmount
    );
    IFeedableRewarder(alpStakingProtocolRevenueRewarder).feedWithExpiredAt(
      alpStakingRewardAmount, feedingExpiredAt
    );
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  receive() external payable {}
}
