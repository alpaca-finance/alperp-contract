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

// OZ
import {ReentrancyGuardUpgradeable} from
  "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from
  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {AddressUpgradeable} from
  "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {OwnableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Alperp
import {IWNative} from "@alperp/interfaces/IWNative.sol";
import {IOnchainPriceUpdater} from "@alperp/interfaces/IOnChainPriceUpdater.sol";
import {IWNativeRelayer} from "@alperp/interfaces/IWNativeRelayer.sol";
import {GetterFacetInterface} from "@alperp/core/pool-diamond/interfaces/GetterFacetInterface.sol";
import {LiquidityFacetInterface} from "@alperp/core/pool-diamond/interfaces/LiquidityFacetInterface.sol";
import {PerpTradeFacetInterface} from "@alperp/core/pool-diamond/interfaces/PerpTradeFacetInterface.sol";
import {PoolOracle} from "@alperp/core/PoolOracle.sol";
import {IterableMapping,Orders,OrderType,itmap} from "@alperp/periphery/limit-orders/libraries/IterableMapping.sol";
import {ITradeMiningManager} from "@alperp/interfaces/ITradeMiningManager.sol";

contract Orderbook02 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using IterableMapping for itmap;

  uint256 public constant PRICE_PRECISION = 1e30;

  struct IncreaseOrder {
    address account;
    uint256 subAccountId;
    address purchaseToken;
    uint256 purchaseTokenAmount;
    address collateralToken;
    address indexToken;
    uint256 sizeDelta;
    bool isLong;
    uint256 triggerPrice;
    bool triggerAboveThreshold;
    uint256 executionFee;
  }

  struct DecreaseOrder {
    address account;
    uint256 subAccountId;
    address collateralToken;
    uint256 collateralDelta;
    address indexToken;
    uint256 sizeDelta;
    bool isLong;
    uint256 triggerPrice;
    bool triggerAboveThreshold;
    uint256 executionFee;
  }

  struct SwapOrder {
    address account;
    address[] path;
    uint256 amountIn;
    uint256 minOut;
    uint256 triggerRatio;
    bool triggerAboveThreshold;
    bool shouldUnwrap;
    uint256 executionFee;
  }

  mapping(address => mapping(uint256 => IncreaseOrder)) public increaseOrders;
  mapping(address => uint256) public increaseOrdersIndex;
  mapping(address => mapping(uint256 => DecreaseOrder)) public decreaseOrders;
  mapping(address => uint256) public decreaseOrdersIndex;
  mapping(address => mapping(uint256 => SwapOrder)) public swapOrders;
  mapping(address => uint256) public swapOrdersIndex;

  address public weth;
  address public pool;
  PoolOracle public poolOracle;
  uint256 public minExecutionFee;
  uint256 public minPurchaseTokenAmountUsd;
  mapping(address => bool) public whitelist;
  bool public isAllowAllExecutor;
  itmap public orderList;
  IOnchainPriceUpdater public oraclePriceUpdater;

  address public wnativeRelayer;

  ITradeMiningManager public tradeMiningManager;

  event CreateIncreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    address purchaseToken,
    uint256 purchaseTokenAmount,
    address collateralToken,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee
  );
  event CancelIncreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    address purchaseToken,
    uint256 purchaseTokenAmount,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee
  );
  event ExecuteIncreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    address purchaseToken,
    uint256 purchaseTokenAmount,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee,
    uint256 executionPrice
  );
  event UpdateIncreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    uint256 sizeDelta,
    uint256 triggerPrice,
    bool triggerAboveThreshold
  );
  event CreateDecreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    address collateralToken,
    uint256 collateralDelta,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee
  );
  event CancelDecreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    address collateralToken,
    uint256 collateralDelta,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee
  );
  event ExecuteDecreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    address collateralToken,
    uint256 collateralDelta,
    address indexToken,
    uint256 sizeDelta,
    bool isLong,
    uint256 triggerPrice,
    bool triggerAboveThreshold,
    uint256 executionFee,
    uint256 executionPrice
  );
  event UpdateDecreaseOrder(
    address indexed account,
    uint256 indexed subAccountId,
    uint256 orderIndex,
    uint256 collateralDelta,
    uint256 sizeDelta,
    uint256 triggerPrice,
    bool triggerAboveThreshold
  );
  event CreateSwapOrder(
    address account,
    uint256 orderIndex,
    address[] path,
    uint256 amountIn,
    uint256 minOut,
    uint256 triggerRatio,
    bool triggerAboveThreshold,
    bool shouldUnwrap,
    uint256 executionFee
  );
  event CancelSwapOrder(
    address account,
    uint256 orderIndex,
    address[] path,
    uint256 amountIn,
    uint256 minOut,
    uint256 triggerRatio,
    bool triggerAboveThreshold,
    bool shouldUnwrap,
    uint256 executionFee
  );
  event UpdateSwapOrder(
    address account,
    uint256 ordexIndex,
    address[] path,
    uint256 amountIn,
    uint256 minOut,
    uint256 triggerRatio,
    bool triggerAboveThreshold,
    bool shouldUnwrap,
    uint256 executionFee
  );
  event ExecuteSwapOrder(
    address account,
    uint256 orderIndex,
    address[] path,
    uint256 amountIn,
    uint256 minOut,
    uint256 triggerRatio,
    bool triggerAboveThreshold,
    bool shouldUnwrap,
    uint256 executionFee,
    uint256 amountOut
  );
  event UpdateMinExecutionFee(uint256 _minExecutionFee);
  event SetWhitelist(address _whitelistAddress, bool _oldAllow, bool _newAllow);
  event SetIsAllowAllExecutor(bool _isAllow);
  event SetTradeMiningManager(
    address _prevTradeMiningManager, address _newTradeMiningManager
  );

  error InvalidSender();
  error InvalidPathLength();
  error InvalidPath();
  error InvalidAmountIn();
  error InsufficientExecutionFee();
  error OnlyNativeShouldWrap();
  error IncorrectValueTransfer();
  error NonExistentOrder();
  error InvalidPriceForExecution();
  error InsufficientCollateral();
  error BadSubAccountId();
  error NotWhitelisted();
  error InsufficientUpdatedFee(uint256 expectedFee, uint256 availableBalance);

  modifier whitelisted() {
    if (!isAllowAllExecutor && !whitelist[msg.sender]) revert NotWhitelisted();
    _;
  }

  function initialize(
    address _pool,
    address _poolOracle,
    address _wnativeRelayer,
    address _weth,
    uint256 _minExecutionFee,
    uint256 _minPurchaseTokenAmountUsd,
    address _oraclePriceUpdater
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

    pool = _pool;
    poolOracle = PoolOracle(_poolOracle);
    wnativeRelayer = _wnativeRelayer;
    weth = _weth;
    minExecutionFee = _minExecutionFee;
    minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;
    oraclePriceUpdater = IOnchainPriceUpdater(_oraclePriceUpdater);
  }

  receive() external payable {
    if (msg.sender != wnativeRelayer) revert InvalidSender();
  }

  function _updatePrices(
    bytes[] calldata _priceUpdateData,
    address[] calldata _tokens,
    uint256[] calldata _prices
  ) internal {
    oraclePriceUpdater.setCachedPrices(_priceUpdateData, _tokens, _prices);
  }

  function _updatePyth(bytes[] calldata _pythPriceUpdateData)
    internal
    returns (uint256 _fee)
  {
    _fee = oraclePriceUpdater.getUpdateFee(_pythPriceUpdateData);
    oraclePriceUpdater.updatePrices{value: _fee}(_pythPriceUpdateData);
  }

  function setWhitelist(address whitelistAddress, bool isAllow)
    external
    onlyOwner
  {
    emit SetWhitelist(whitelistAddress, whitelist[whitelistAddress], isAllow);
    whitelist[whitelistAddress] = isAllow;
  }

  function setIsAllowAllExecutor(bool isAllow) external onlyOwner {
    isAllowAllExecutor = isAllow;
    emit SetIsAllowAllExecutor(isAllow);
  }

  function setMinExecutionFee(uint256 _minExecutionFee) external onlyOwner {
    minExecutionFee = _minExecutionFee;
    emit UpdateMinExecutionFee(_minExecutionFee);
  }

  /// @notice Set a new trade mining manager
  /// @param _newTradeMiningManager A new trade mining manager
  function setTradeMiningManager(ITradeMiningManager _newTradeMiningManager)
    external
    onlyOwner
  {
    emit SetTradeMiningManager(
      address(tradeMiningManager), address(_newTradeMiningManager)
    );
    tradeMiningManager = _newTradeMiningManager;
  }

  function getSwapOrder(address _account, uint256 _orderIndex)
    public
    view
    returns (
      address path0,
      address path1,
      address path2,
      uint256 amountIn,
      uint256 minOut,
      uint256 triggerRatio,
      bool triggerAboveThreshold
    )
  {
    SwapOrder memory order = swapOrders[_account][_orderIndex];
    return (
      order.path.length > 0 ? order.path[0] : address(0),
      order.path.length > 1 ? order.path[1] : address(0),
      order.path.length > 2 ? order.path[2] : address(0),
      order.amountIn,
      order.minOut,
      order.triggerRatio,
      order.triggerAboveThreshold
    );
  }

  function createSwapOrder(
    address[] calldata _path,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _triggerRatio, // tokenB / tokenA
    bool _triggerAboveThreshold,
    uint256 _executionFee,
    bool _shouldWrap,
    bool _shouldUnwrap
  ) external payable nonReentrant {
    if (_path.length != 2 && _path.length != 3) revert InvalidPathLength();
    if (_path[0] == _path[_path.length - 1]) revert InvalidPath();
    if (_amountIn == 0) revert InvalidAmountIn();
    if (_executionFee < minExecutionFee) revert InsufficientExecutionFee();

    // always need this call because of mandatory executionFee user has to transfer in BNB
    _transferInETH(0);

    if (_shouldWrap) {
      if (_path[0] != weth) revert OnlyNativeShouldWrap();
      if (msg.value != _executionFee + _amountIn) {
        revert IncorrectValueTransfer();
      }
    } else {
      if (msg.value != _executionFee) revert IncorrectValueTransfer();
      IERC20Upgradeable(_path[0]).safeTransferFrom(
        msg.sender, address(this), _amountIn
      );
    }

    _createSwapOrder(
      msg.sender,
      _path,
      _amountIn,
      _minOut,
      _triggerRatio,
      _triggerAboveThreshold,
      _shouldUnwrap,
      _executionFee
    );
  }

  function _createSwapOrder(
    address _account,
    address[] calldata _path,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _triggerRatio,
    bool _triggerAboveThreshold,
    bool _shouldUnwrap,
    uint256 _executionFee
  ) private {
    uint256 _orderIndex = swapOrdersIndex[_account];
    SwapOrder memory order = SwapOrder(
      _account,
      _path,
      _amountIn,
      _minOut,
      _triggerRatio,
      _triggerAboveThreshold,
      _shouldUnwrap,
      _executionFee
    );
    swapOrdersIndex[_account] = _orderIndex + 1;
    swapOrders[_account][_orderIndex] = order;
    _addToOpenOrders(_account, 0, _orderIndex, OrderType.SWAP);

    emit CreateSwapOrder(
      _account,
      _orderIndex,
      _path,
      _amountIn,
      _minOut,
      _triggerRatio,
      _triggerAboveThreshold,
      _shouldUnwrap,
      _executionFee
    );
  }

  function cancelSwapOrder(uint256 _orderIndex) external nonReentrant {
    SwapOrder memory order = swapOrders[msg.sender][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    delete swapOrders[msg.sender][_orderIndex];
    _removeFromOpenOrders(msg.sender, 0, _orderIndex, OrderType.SWAP);

    if (order.path[0] == weth) {
      _transferOutETH(order.executionFee + order.amountIn, msg.sender);
    } else {
      IERC20Upgradeable(order.path[0]).safeTransfer(msg.sender, order.amountIn);
      _transferOutETH(order.executionFee, msg.sender);
    }

    emit CancelSwapOrder(
      msg.sender,
      _orderIndex,
      order.path,
      order.amountIn,
      order.minOut,
      order.triggerRatio,
      order.triggerAboveThreshold,
      order.shouldUnwrap,
      order.executionFee
    );
  }

  function validateSwapOrderPriceWithTriggerAboveThreshold(
    address[] memory _path,
    uint256 _triggerRatio
  ) public view returns (bool) {
    if (_path.length != 2 && _path.length != 3) revert InvalidPathLength();

    // limit orders don't need this validation because minOut is enough
    // so this validation handles scenarios for stop orders only
    // when a user wants to swap when a price of tokenB increases relative to tokenA
    uint256 currentRatio;
    if (_path.length == 2) {
      address tokenA = _path[0];
      address tokenB = _path[1];
      uint256 tokenAPrice;
      uint256 tokenBPrice;

      tokenAPrice = poolOracle.getMinPrice(tokenA);
      tokenBPrice = poolOracle.getMaxPrice(tokenB);

      currentRatio = (tokenBPrice * PRICE_PRECISION) / tokenAPrice;
    } else {
      address tokenA = _path[0];
      address tokenB = _path[1];
      address tokenC = _path[2];
      uint256 tokenAPrice;
      uint256 tokenBMinPrice;
      uint256 tokenBMaxPrice;
      uint256 tokenCPrice;

      tokenAPrice = poolOracle.getMinPrice(tokenA);
      tokenBMinPrice = poolOracle.getMinPrice(tokenB);
      tokenBMaxPrice = poolOracle.getMaxPrice(tokenB);
      tokenCPrice = poolOracle.getMaxPrice(tokenC);

      currentRatio = (tokenCPrice * tokenBMaxPrice * PRICE_PRECISION)
        / (tokenAPrice * tokenBMinPrice);
    }
    bool isValid = currentRatio > _triggerRatio;
    return isValid;
  }

  function updateSwapOrder(
    uint256 _orderIndex,
    uint256 _minOut,
    uint256 _triggerRatio,
    bool _triggerAboveThreshold
  ) external nonReentrant {
    SwapOrder storage order = swapOrders[msg.sender][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    order.minOut = _minOut;
    order.triggerRatio = _triggerRatio;
    order.triggerAboveThreshold = _triggerAboveThreshold;

    emit UpdateSwapOrder(
      msg.sender,
      _orderIndex,
      order.path,
      order.amountIn,
      _minOut,
      _triggerRatio,
      _triggerAboveThreshold,
      order.shouldUnwrap,
      order.executionFee
    );
  }

  function executeSwapOrder(
    address _account,
    uint256 _orderIndex,
    address payable _feeReceiver,
    bytes[] calldata _priceUpdateData,
    address[] calldata _tokens,
    uint256[] calldata _prices
  ) external nonReentrant whitelisted {
    _updatePrices(_priceUpdateData, _tokens, _prices);
    SwapOrder memory order = swapOrders[_account][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    if (order.triggerAboveThreshold) {
      // gas optimisation
      // order.minAmount should prevent wrong price execution in case of simple limit order
      if (
        !validateSwapOrderPriceWithTriggerAboveThreshold(
          order.path, order.triggerRatio
        )
      ) revert InvalidPriceForExecution();
    }

    delete swapOrders[_account][_orderIndex];
    _removeFromOpenOrders(_account, 0, _orderIndex, OrderType.SWAP);

    IERC20Upgradeable(order.path[0]).safeTransfer(pool, order.amountIn);

    uint256 _amountOut;
    if (order.path[order.path.length - 1] == weth && order.shouldUnwrap) {
      _amountOut = _swap(order.account, order.path, order.minOut, address(this));
      _transferOutETH(_amountOut, payable(order.account));
    } else {
      _amountOut = _swap(order.account, order.path, order.minOut, order.account);
    }

    _transferOutETH(order.executionFee, _feeReceiver);

    emit ExecuteSwapOrder(
      _account,
      _orderIndex,
      order.path,
      order.amountIn,
      order.minOut,
      order.triggerRatio,
      order.triggerAboveThreshold,
      order.shouldUnwrap,
      order.executionFee,
      _amountOut
    );
  }

  function validatePositionOrderPrice(
    bool _triggerAboveThreshold,
    uint256 _triggerPrice,
    address _indexToken,
    bool _maximizePrice,
    bool _raise
  ) public view returns (uint256, bool) {
    uint256 currentPrice = _maximizePrice
      ? poolOracle.getMaxPrice(_indexToken)
      : poolOracle.getMinPrice(_indexToken);
    bool isPriceValid = _triggerAboveThreshold
      ? currentPrice > _triggerPrice
      : currentPrice < _triggerPrice;
    if (_raise) {
      if (!isPriceValid) revert InvalidPriceForExecution();
    }
    return (currentPrice, isPriceValid);
  }

  function getDecreaseOrder(
    address _account,
    uint256 _subAccountId,
    uint256 _orderIndex
  )
    public
    view
    returns (
      address collateralToken,
      uint256 collateralDelta,
      address indexToken,
      uint256 sizeDelta,
      bool isLong,
      uint256 triggerPrice,
      bool triggerAboveThreshold
    )
  {
    address subAccount = getSubAccount(_account, _subAccountId);
    DecreaseOrder memory order = decreaseOrders[subAccount][_orderIndex];
    return (
      order.collateralToken,
      order.collateralDelta,
      order.indexToken,
      order.sizeDelta,
      order.isLong,
      order.triggerPrice,
      order.triggerAboveThreshold
    );
  }

  function getIncreaseOrder(
    address _account,
    uint256 _subAccountId,
    uint256 _orderIndex
  )
    public
    view
    returns (
      address purchaseToken,
      uint256 purchaseTokenAmount,
      address collateralToken,
      address indexToken,
      uint256 sizeDelta,
      bool isLong,
      uint256 triggerPrice,
      bool triggerAboveThreshold
    )
  {
    address subAccount = getSubAccount(_account, _subAccountId);
    IncreaseOrder memory order = increaseOrders[subAccount][_orderIndex];
    return (
      order.purchaseToken,
      order.purchaseTokenAmount,
      order.collateralToken,
      order.indexToken,
      order.sizeDelta,
      order.isLong,
      order.triggerPrice,
      order.triggerAboveThreshold
    );
  }

  struct CreateIncreaseOrderLocalVars {
    address purchaseToken;
    uint256 purchaseTokenAmount;
    uint256 purchaseTokenAmountUsd;
    uint256 netMsgValue;
  }

  struct CreateIncreaseOrderParams {
    uint256 subAccountId;
    address[] path;
    uint256 amountIn;
    address indexToken;
    uint256 minOut;
    uint256 sizeDelta;
    address collateralToken;
    bool isLong;
    uint256 triggerPrice;
    bool triggerAboveThreshold;
    uint256 executionFee;
    bool shouldWrap;
    bytes[] pythUpdateData;
  }

  function createIncreaseOrder(CreateIncreaseOrderParams calldata _params)
    external
    payable
    nonReentrant
  {
    CreateIncreaseOrderLocalVars memory _vars;
    // always need this call because of mandatory executionFee user has to transfer in BNB
    _vars.netMsgValue = _transferInETH(_updatePyth(_params.pythUpdateData));

    if (_params.executionFee < minExecutionFee) {
      revert InsufficientExecutionFee();
    }
    if (_params.shouldWrap) {
      if (_params.path[0] != weth) revert OnlyNativeShouldWrap();
      if (_vars.netMsgValue != _params.executionFee + _params.amountIn) {
        revert IncorrectValueTransfer();
      }
    } else {
      if (_vars.netMsgValue != _params.executionFee) {
        revert IncorrectValueTransfer();
      }
      IERC20Upgradeable(_params.path[0]).safeTransferFrom(
        msg.sender, address(this), _params.amountIn
      );
    }

    _vars.purchaseToken = _params.path[_params.path.length - 1];

    if (_params.path.length > 1) {
      if (_params.path[0] == _params.path[_params.path.length - 1]) {
        revert InvalidPath();
      }
      IERC20Upgradeable(_params.path[0]).safeTransfer(pool, _params.amountIn);
      _vars.purchaseTokenAmount =
        _swap(msg.sender, _params.path, _params.minOut, address(this));
    } else {
      _vars.purchaseTokenAmount = _params.amountIn;
    }

    {
      uint256 _purchaseTokenAmountUsd = GetterFacetInterface(pool)
        .convertTokensToUsde30(
        _vars.purchaseToken, _vars.purchaseTokenAmount, false
      );
      if (_purchaseTokenAmountUsd < minPurchaseTokenAmountUsd) {
        revert InsufficientCollateral();
      }
    }

    _createIncreaseOrder(
      msg.sender,
      _params.subAccountId,
      _vars.purchaseToken,
      _vars.purchaseTokenAmount,
      _params.collateralToken,
      _params.indexToken,
      _params.sizeDelta,
      _params.isLong,
      _params.triggerPrice,
      _params.triggerAboveThreshold,
      _params.executionFee
    );
  }

  function _createIncreaseOrder(
    address _account,
    uint256 _subAccountId,
    address _purchaseToken,
    uint256 _purchaseTokenAmount,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _triggerPrice,
    bool _triggerAboveThreshold,
    uint256 _executionFee
  ) private {
    address subAccount = getSubAccount(_account, _subAccountId);
    uint256 _orderIndex = increaseOrdersIndex[subAccount];
    IncreaseOrder memory order = IncreaseOrder(
      _account,
      _subAccountId,
      _purchaseToken,
      _purchaseTokenAmount,
      _collateralToken,
      _indexToken,
      _sizeDelta,
      _isLong,
      _triggerPrice,
      _triggerAboveThreshold,
      _executionFee
    );
    increaseOrdersIndex[subAccount] = _orderIndex + 1;
    increaseOrders[subAccount][_orderIndex] = order;
    _addToOpenOrders(_account, _subAccountId, _orderIndex, OrderType.INCREASE);

    emit CreateIncreaseOrder(
      _account,
      _subAccountId,
      _orderIndex,
      _purchaseToken,
      _purchaseTokenAmount,
      _collateralToken,
      _indexToken,
      _sizeDelta,
      _isLong,
      _triggerPrice,
      _triggerAboveThreshold,
      _executionFee
    );
  }

  function updateIncreaseOrder(
    uint256 _subAccountId,
    uint256 _orderIndex,
    uint256 _sizeDelta,
    uint256 _triggerPrice,
    bool _triggerAboveThreshold
  ) external nonReentrant {
    address subAccount = getSubAccount(msg.sender, _subAccountId);
    IncreaseOrder storage order = increaseOrders[subAccount][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    order.triggerPrice = _triggerPrice;
    order.triggerAboveThreshold = _triggerAboveThreshold;
    order.sizeDelta = _sizeDelta;

    emit UpdateIncreaseOrder(
      msg.sender,
      order.subAccountId,
      _orderIndex,
      _sizeDelta,
      _triggerPrice,
      _triggerAboveThreshold
    );
  }

  function cancelIncreaseOrder(uint256 _subAccountId, uint256 _orderIndex)
    external
    nonReentrant
  {
    address subAccount = getSubAccount(msg.sender, _subAccountId);
    IncreaseOrder memory order = increaseOrders[subAccount][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    delete increaseOrders[subAccount][_orderIndex];
    _removeFromOpenOrders(
      msg.sender, _subAccountId, _orderIndex, OrderType.INCREASE
    );

    if (order.purchaseToken == weth) {
      _transferOutETH(
        order.executionFee + order.purchaseTokenAmount, msg.sender
      );
    } else {
      IERC20Upgradeable(order.purchaseToken).safeTransfer(
        msg.sender, order.purchaseTokenAmount
      );
      _transferOutETH(order.executionFee, msg.sender);
    }

    emit CancelIncreaseOrder(
      order.account,
      order.subAccountId,
      _orderIndex,
      order.purchaseToken,
      order.purchaseTokenAmount,
      order.indexToken,
      order.sizeDelta,
      order.isLong,
      order.triggerPrice,
      order.triggerAboveThreshold,
      order.executionFee
    );
  }

  function executeIncreaseOrder(
    address _address,
    uint256 _subAccountId,
    uint256 _orderIndex,
    address payable _feeReceiver,
    bytes[] calldata _priceUpdateData,
    address[] calldata _tokens,
    uint256[] calldata _prices
  ) external nonReentrant whitelisted {
    _updatePrices(_priceUpdateData, _tokens, _prices);
    address subAccount = getSubAccount(_address, _subAccountId);
    IncreaseOrder memory order = increaseOrders[subAccount][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    // increase long should use max price
    // increase short should use min price
    (uint256 currentPrice,) = validatePositionOrderPrice(
      order.triggerAboveThreshold,
      order.triggerPrice,
      order.indexToken,
      order.isLong,
      true
    );

    delete increaseOrders[subAccount][_orderIndex];
    _removeFromOpenOrders(
      _address, _subAccountId, _orderIndex, OrderType.INCREASE
    );

    IERC20Upgradeable(order.purchaseToken).safeTransfer(
      pool, order.purchaseTokenAmount
    );

    if (order.purchaseToken != order.collateralToken) {
      address[] memory path = new address[](2);
      path[0] = order.purchaseToken;
      path[1] = order.collateralToken;

      uint256 amountOut = _swap(order.account, path, 0, address(this));
      IERC20Upgradeable(order.collateralToken).safeTransfer(pool, amountOut);
    }

    PerpTradeFacetInterface(pool).increasePosition(
      order.account,
      order.subAccountId,
      order.collateralToken,
      order.indexToken,
      order.sizeDelta,
      order.isLong
    );

    // pay executor
    _transferOutETH(order.executionFee, _feeReceiver);

    if (address(tradeMiningManager) != address(0)) {
      // If tradeMiningManager is set, then call it to update trade mining state
      tradeMiningManager.onIncreasePosition(
        order.account,
        order.subAccountId,
        order.purchaseToken,
        order.indexToken,
        order.sizeDelta,
        order.isLong
      );
    }

    emit ExecuteIncreaseOrder(
      order.account,
      order.subAccountId,
      _orderIndex,
      order.purchaseToken,
      order.purchaseTokenAmount,
      order.indexToken,
      order.sizeDelta,
      order.isLong,
      order.triggerPrice,
      order.triggerAboveThreshold,
      order.executionFee,
      currentPrice
    );
  }

  function createDecreaseOrder(
    uint256 _subAccountId,
    address _indexToken,
    uint256 _sizeDelta,
    address _collateralToken,
    uint256 _collateralDelta,
    bool _isLong,
    uint256 _triggerPrice,
    bool _triggerAboveThreshold
  ) external payable nonReentrant {
    _transferInETH(0);

    if (msg.value < minExecutionFee) revert InsufficientExecutionFee();

    _createDecreaseOrder(
      msg.sender,
      _subAccountId,
      _collateralToken,
      _collateralDelta,
      _indexToken,
      _sizeDelta,
      _isLong,
      _triggerPrice,
      _triggerAboveThreshold
    );
  }

  function _createDecreaseOrder(
    address _account,
    uint256 _subAccountId,
    address _collateralToken,
    uint256 _collateralDelta,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _triggerPrice,
    bool _triggerAboveThreshold
  ) private {
    address subAccount = getSubAccount(_account, _subAccountId);
    uint256 _orderIndex = decreaseOrdersIndex[subAccount];
    DecreaseOrder memory order = DecreaseOrder(
      _account,
      _subAccountId,
      _collateralToken,
      _collateralDelta,
      _indexToken,
      _sizeDelta,
      _isLong,
      _triggerPrice,
      _triggerAboveThreshold,
      msg.value
    );

    decreaseOrdersIndex[subAccount] = _orderIndex + 1;
    decreaseOrders[subAccount][_orderIndex] = order;
    _addToOpenOrders(_account, _subAccountId, _orderIndex, OrderType.DECREASE);

    emit CreateDecreaseOrder(
      _account,
      _subAccountId,
      _orderIndex,
      _collateralToken,
      _collateralDelta,
      _indexToken,
      _sizeDelta,
      _isLong,
      _triggerPrice,
      _triggerAboveThreshold,
      msg.value
    );
  }

  function executeDecreaseOrder(
    address _address,
    uint256 _subAccountId,
    uint256 _orderIndex,
    address payable _feeReceiver,
    bytes[] calldata _priceUpdateData,
    address[] calldata _tokens,
    uint256[] calldata _prices
  ) external nonReentrant whitelisted {
    _updatePrices(_priceUpdateData, _tokens, _prices);
    address subAccount = getSubAccount(_address, _subAccountId);
    DecreaseOrder memory order = decreaseOrders[subAccount][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    // decrease long should use min price
    // decrease short should use max price
    (uint256 currentPrice,) = validatePositionOrderPrice(
      order.triggerAboveThreshold,
      order.triggerPrice,
      order.indexToken,
      !order.isLong,
      true
    );

    delete decreaseOrders[subAccount][_orderIndex];
    _removeFromOpenOrders(
      _address, _subAccountId, _orderIndex, OrderType.DECREASE
    );

    uint256 amountOut = PerpTradeFacetInterface(pool).decreasePosition(
      order.account,
      order.subAccountId,
      order.collateralToken,
      order.indexToken,
      order.collateralDelta,
      order.sizeDelta,
      order.isLong,
      address(this)
    );

    // transfer released collateral to user
    if (order.collateralToken == weth) {
      _transferOutETH(amountOut, payable(order.account));
    } else {
      IERC20Upgradeable(order.collateralToken).safeTransfer(
        order.account, amountOut
      );
    }

    // pay executor
    _transferOutETH(order.executionFee, _feeReceiver);

    if (address(tradeMiningManager) != address(0)) {
      // If tradeMiningManager is set, then call it to update trade mining state
      tradeMiningManager.onDecreasePosition(
        order.account,
        order.subAccountId,
        order.collateralToken,
        order.indexToken,
        order.sizeDelta,
        order.isLong
      );
    }

    emit ExecuteDecreaseOrder(
      order.account,
      order.subAccountId,
      _orderIndex,
      order.collateralToken,
      order.collateralDelta,
      order.indexToken,
      order.sizeDelta,
      order.isLong,
      order.triggerPrice,
      order.triggerAboveThreshold,
      order.executionFee,
      currentPrice
    );
  }

  function cancelDecreaseOrder(uint256 _subAccountId, uint256 _orderIndex)
    external
    nonReentrant
  {
    address subAccount = getSubAccount(msg.sender, _subAccountId);
    DecreaseOrder memory order = decreaseOrders[subAccount][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    delete decreaseOrders[subAccount][_orderIndex];
    _removeFromOpenOrders(
      msg.sender, _subAccountId, _orderIndex, OrderType.DECREASE
    );
    _transferOutETH(order.executionFee, msg.sender);

    emit CancelDecreaseOrder(
      order.account,
      order.subAccountId,
      _orderIndex,
      order.collateralToken,
      order.collateralDelta,
      order.indexToken,
      order.sizeDelta,
      order.isLong,
      order.triggerPrice,
      order.triggerAboveThreshold,
      order.executionFee
    );
  }

  function updateDecreaseOrder(
    uint256 _subAccountId,
    uint256 _orderIndex,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    uint256 _triggerPrice,
    bool _triggerAboveThreshold
  ) external nonReentrant {
    address subAccount = getSubAccount(msg.sender, _subAccountId);
    DecreaseOrder storage order = decreaseOrders[subAccount][_orderIndex];
    if (order.account == address(0)) revert NonExistentOrder();

    order.triggerPrice = _triggerPrice;
    order.triggerAboveThreshold = _triggerAboveThreshold;
    order.sizeDelta = _sizeDelta;
    order.collateralDelta = _collateralDelta;

    emit UpdateDecreaseOrder(
      msg.sender,
      order.subAccountId,
      _orderIndex,
      _collateralDelta,
      _sizeDelta,
      _triggerPrice,
      _triggerAboveThreshold
    );
  }

  function _transferInETH(uint256 _offset)
    private
    returns (uint256 netMsgValue)
  {
    if (msg.value != 0) {
      IWNative(weth).deposit{value: msg.value - _offset}();
      netMsgValue = msg.value - _offset;
    }
  }

  function _transferOutETH(uint256 _amountOut, address _receiver) private {
    // prevent istanbul msg.sender.transfer problem
    IERC20Upgradeable(weth).safeTransfer(wnativeRelayer, _amountOut);
    IWNativeRelayer(wnativeRelayer).withdraw(_amountOut);

    payable(_receiver).transfer(_amountOut);
  }

  function _swap(
    address _account,
    address[] memory _path,
    uint256 _minOut,
    address _receiver
  ) private returns (uint256) {
    if (_path.length == 2) {
      return _vaultSwap(_account, _path[0], _path[1], _minOut, _receiver);
    }
    if (_path.length == 3) {
      uint256 midOut =
        _vaultSwap(_account, _path[0], _path[1], 0, address(this));
      IERC20Upgradeable(_path[1]).safeTransfer(pool, midOut);
      return _vaultSwap(_account, _path[1], _path[2], _minOut, _receiver);
    }

    revert("o");
  }

  function _vaultSwap(
    address _account,
    address _tokenIn,
    address _tokenOut,
    uint256 _minOut,
    address _receiver
  ) private returns (uint256) {
    uint256 amountOut;

    amountOut = LiquidityFacetInterface(pool).swap(
      _account, _tokenIn, _tokenOut, _minOut, _receiver
    );

    return amountOut;
  }

  function getSubAccount(address primary, uint256 subAccountId)
    internal
    pure
    returns (address)
  {
    if (subAccountId > 255) revert BadSubAccountId();
    return address(uint160(primary) ^ uint160(subAccountId));
  }

  function getShouldExecuteOrderList(bool _returnFirst, uint256 maxOrderSize)
    external
    view
    returns (bool, uint160[] memory)
  {
    uint256 orderListSize =
      orderList.size > maxOrderSize ? maxOrderSize : orderList.size;
    uint160[] memory shouldExecuteOrders = new uint160[](orderListSize * 4);
    uint256 shouldExecuteIndex = 0;
    if (orderListSize > 0) {
      for (
        uint256 i = orderList.iterate_start();
        orderList.iterate_valid(i);
        i = orderList.iterate_next(i + 1)
      ) {
        (, Orders memory order) = orderList.iterate_get(i);
        bool shouldExecute = false;
        address subAccount = getSubAccount(order.account, order.subAccountId);

        if (order.orderType == OrderType.SWAP) {
          SwapOrder memory swapOrder = swapOrders[subAccount][order.orderIndex];
          if (!swapOrder.triggerAboveThreshold) {
            shouldExecute = true;
          } else {
            shouldExecute = validateSwapOrderPriceWithTriggerAboveThreshold(
              swapOrder.path, swapOrder.triggerRatio
            );
          }
        } else if (order.orderType == OrderType.INCREASE) {
          IncreaseOrder memory increaseOrder =
            increaseOrders[subAccount][order.orderIndex];
          (, shouldExecute) = validatePositionOrderPrice(
            increaseOrder.triggerAboveThreshold,
            increaseOrder.triggerPrice,
            increaseOrder.indexToken,
            increaseOrder.isLong,
            false
          );
        } else if (order.orderType == OrderType.DECREASE) {
          DecreaseOrder memory decreaseOrder =
            decreaseOrders[subAccount][order.orderIndex];
          GetterFacetInterface.GetPositionReturnVars memory position =
          GetterFacetInterface(pool).getPosition(
            subAccount,
            decreaseOrder.collateralToken,
            decreaseOrder.indexToken,
            decreaseOrder.isLong
          );
          if (position.size > 0) {
            (, shouldExecute) = validatePositionOrderPrice(
              decreaseOrder.triggerAboveThreshold,
              decreaseOrder.triggerPrice,
              decreaseOrder.indexToken,
              !decreaseOrder.isLong,
              false
            );
          }
        }
        if (shouldExecute) {
          if (_returnFirst) {
            return (true, new uint160[](0));
          }
          shouldExecuteOrders[shouldExecuteIndex * 4] = uint160(order.account);
          shouldExecuteOrders[shouldExecuteIndex * 4 + 1] =
            uint160(order.subAccountId);
          shouldExecuteOrders[shouldExecuteIndex * 4 + 2] =
            uint160(order.orderIndex);
          shouldExecuteOrders[shouldExecuteIndex * 4 + 3] =
            uint160(order.orderType);
          shouldExecuteIndex++;
        }
      }
    }

    uint160[] memory returnList = new uint160[](shouldExecuteIndex * 4);

    for (uint256 i = 0; i < shouldExecuteIndex * 4; i++) {
      returnList[i] = shouldExecuteOrders[i];
    }

    return (shouldExecuteIndex > 0, returnList);
  }

  function _addToOpenOrders(
    address _account,
    uint256 _subAccountId,
    uint256 _index,
    OrderType _type
  ) internal {
    uint256 orderKey = getOrderKey(_account, _subAccountId, _index, _type);
    Orders memory order = Orders(_account, _subAccountId, _index, _type);
    orderList.insert(orderKey, order);
  }

  function _removeFromOpenOrders(
    address _account,
    uint256 _subAccountId,
    uint256 _index,
    OrderType _type
  ) internal {
    uint256 orderKey = getOrderKey(_account, _subAccountId, _index, _type);
    orderList.remove(orderKey);
  }

  function getOrderKey(
    address _account,
    uint256 _subAccountId,
    uint256 _index,
    OrderType _type
  ) public pure returns (uint256) {
    return uint256(
      keccak256(
        abi.encodePacked(getSubAccount(_account, _subAccountId), _index, _type)
      )
    );
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }
}
