import { HardhatRuntimeEnvironment } from "hardhat/types";
import { outputJSONFile } from "../constants";
import {
  Action,
  EventSource,
  IDecreaseOrder,
  IIncreaseOrder,
  ILongShortLog,
  IOrder,
  IPerpLog,
  ISwapLog,
  ISwapOrder,
  Log3,
  OrderStatus,
  QueryResponse,
  Transaction,
  TypeLog,
} from "../interfaces";
import { getEventID, getLocalOutputPath, readFile, writeFile } from "../utils";

const orderFilePath: string = getLocalOutputPath(outputJSONFile.order.filename);
const positionLogsFilePath: string = getLocalOutputPath(
  outputJSONFile.positionLog.filename
);

export const _getOrderId = (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  eventSource: EventSource
): string => {
  const id =
    account + "-" + subAccount + "-" + type + "-" + index + "-" + eventSource;
  return id;
};

export const _handleCreateOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  timestamp: string,
  triggerPrice: string,
  triggerAboveThreshold: boolean,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  let defaultIncreaseOrder: IIncreaseOrder | null = {
    id: "",
    eventSource: eventSource,
    purchaseToken: "",
    purchaseTokenAmount: "",
    collateralToken: "",
    indexToken: "",
    sizeDelta: "",
    isLong: false,
  };
  let defaultDecreaseOrder: IDecreaseOrder | null = {
    id: "",
    eventSource: eventSource,
    collateralToken: "",
    collateralDelta: "",
    indexToken: "",
    sizeDelta: "",
    isLong: false,
  };
  let defaultSwapOrder: ISwapOrder | null = {
    id: "",
    eventSource: eventSource,
    path: [],
    amountIn: "",
    minOut: "",
  };

  switch (type) {
    case "increase":
      (defaultIncreaseOrder as IIncreaseOrder).id = id;
      defaultDecreaseOrder = null;
      defaultSwapOrder = null;
      break;
    case "decrease":
      (defaultDecreaseOrder as IDecreaseOrder).id = id;
      defaultIncreaseOrder = null;
      defaultSwapOrder = null;
      break;
    case "swap":
      (defaultSwapOrder as ISwapOrder).id = id;
      defaultIncreaseOrder = null;
      defaultDecreaseOrder = null;
      break;
  }

  savedOrders.data[outputJSONFile.order.queryResponseKey].push({
    id: id,
    eventSource: eventSource,
    account: account,
    subAccount: subAccount,
    createdTimestamp: timestamp,
    index: index,
    type: type,
    status: OrderStatus.Open,
    triggerPrice: triggerPrice,
    triggerAboveThreshold: triggerAboveThreshold,
    increaseOrder: defaultIncreaseOrder,
    decreaseOrder: defaultDecreaseOrder,
    swapOrder: defaultSwapOrder,
  });

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleCreateOrder");
};

export const _handleCancelOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  timestamp: string,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;
  hit.status = OrderStatus.Cancelled;
  hit.cancelledTimestamp = timestamp;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleCancelOrder");
};

export const _handleExecuteOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  timestamp: string,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;
  hit.status = OrderStatus.Executed;
  hit.executedTimestamp = timestamp;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleExecuteOrder");
};

export const _handleUpdateOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  triggerPrice: string,
  triggerAboveThreshold: boolean,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;
  hit.triggerPrice = triggerPrice;
  hit.triggerAboveThreshold = triggerAboveThreshold;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleUpdateOrder");
};

export const _handleCreateIncreaseOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  purchaseToken: string,
  purchaseTokenAmount: string,
  collateralToken: string,
  indexToken: string,
  sizeDelta: string,
  isLong: boolean,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;

  (hit.increaseOrder as IIncreaseOrder).purchaseToken = purchaseToken;
  (hit.increaseOrder as IIncreaseOrder).purchaseTokenAmount =
    purchaseTokenAmount;
  (hit.increaseOrder as IIncreaseOrder).collateralToken = collateralToken;
  (hit.increaseOrder as IIncreaseOrder).indexToken = indexToken;
  (hit.increaseOrder as IIncreaseOrder).sizeDelta = sizeDelta;
  (hit.increaseOrder as IIncreaseOrder).isLong = isLong;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleCreateIncreaseOrder");
};

export const _handleUpdateIncreaseOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  sizeDelta: string,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;

  (hit.increaseOrder as IIncreaseOrder).sizeDelta = sizeDelta;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleUpdateIncreaseOrder");
};

export const _handleCreateDecreaseOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  collateralToken: string,
  collateralDelta: string,
  indexToken: string,
  sizeDelta: string,
  isLong: boolean,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;

  (hit.decreaseOrder as IDecreaseOrder).collateralToken = collateralToken;
  (hit.decreaseOrder as IDecreaseOrder).collateralDelta = collateralDelta;
  (hit.decreaseOrder as IDecreaseOrder).indexToken = indexToken;
  (hit.decreaseOrder as IDecreaseOrder).sizeDelta = sizeDelta;
  (hit.decreaseOrder as IDecreaseOrder).isLong = isLong;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleCreateDecreaseOrder");
};

export const _handleUpdateDecreaseOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  collateralDelta: string,
  sizeDelta: string,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;

  (hit.decreaseOrder as IDecreaseOrder).collateralDelta = collateralDelta;
  (hit.decreaseOrder as IDecreaseOrder).sizeDelta = sizeDelta;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleUpdateDecreaseOrder");
};

export const _handleCreateSwapOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  path: string[],
  amountIn: string,
  minOut: string,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;

  (hit.swapOrder as ISwapOrder).path = path;
  (hit.swapOrder as ISwapOrder).amountIn = amountIn;
  (hit.swapOrder as ISwapOrder).minOut = minOut;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleCreateSwapOrder");
};

export const _handleUpdateSwapOrder = async (
  account: string,
  subAccount: string,
  type: string,
  index: string,
  path: string[],
  amountIn: string,
  eventSource: EventSource
): Promise<void> => {
  const id = _getOrderId(account, subAccount, type, index, eventSource);
  const savedOrders = readFile<QueryResponse<Array<IOrder>>>(orderFilePath);
  const hit = savedOrders.data[outputJSONFile.order.queryResponseKey].find(
    (order) => {
      return order.id === id;
    }
  );
  if (!hit) return;

  (hit.swapOrder as ISwapOrder).path = path;
  (hit.swapOrder as ISwapOrder).amountIn = amountIn;

  writeFile(savedOrders, orderFilePath);
  console.log(">> ✅ DONE _handleUpdateSwapOrder");
};

export const _storeLongShortLog = async (
  account: string,
  subAccount: string,
  type: TypeLog,
  action: Action,
  log: Log3,
  tx: Transaction,
  hre: HardhatRuntimeEnvironment,
  timestamp: string,
  indexToken: string,
  sizeDelta: string,
  isLong: boolean,
  triggerPrice: string,
  triggerAboveThreshold: boolean,
  markPrice: string,
  eventSource: EventSource
) => {
  const perpLogs =
    readFile<QueryResponse<Array<IPerpLog>>>(positionLogsFilePath);
  const id = getEventID(log, tx, hre);
  const longShortLog: ILongShortLog = {
    id: id,
    indexToken: indexToken,
    sizeDelta: sizeDelta,
    isLong: isLong,
    triggerPrice: triggerPrice,
    triggerAboveThreshold: triggerAboveThreshold,
    markPrice: markPrice,
  } as ILongShortLog;
  const perpLog: IPerpLog = {
    id: id,
    tx: tx.hash,
    type: type,
    action: action,
    account: account,
    subAccount: subAccount,
    createdAt: timestamp,
    longShortLog: longShortLog,
    eventSource: eventSource,
  } as IPerpLog;
  perpLogs.data[outputJSONFile.positionLog.queryResponseKey] = perpLogs.data[
    outputJSONFile.positionLog.queryResponseKey
  ].concat([perpLog]);
};

export const _storeSwapLog = async (
  account: string,
  subAccount: string,
  type: TypeLog,
  action: Action,
  log: Log3,
  tx: Transaction,
  hre: HardhatRuntimeEnvironment,
  timestamp: string,
  path: string[],
  amountIn: string,
  amountOut: string,
  triggerPrice: string,
  triggerAboveThreshold: boolean,
  eventSource: EventSource
) => {
  const perpLogs =
    readFile<QueryResponse<Array<IPerpLog>>>(positionLogsFilePath);

  const id = getEventID(log, tx, hre);
  const swapLog: ISwapLog = {
    id: id,
    path: path,
    amountIn: amountIn,
    amountOut: amountOut,
    triggerPrice: triggerPrice,
    triggerAboveThreshold: triggerAboveThreshold,
  } as ISwapLog;
  const perpLog: IPerpLog = {
    id: id,
    tx: tx.hash,
    type: type,
    action: action,
    account: account,
    subAccount: subAccount,
    createdAt: timestamp,
    swapLog: swapLog,
    eventSource: eventSource,
  } as IPerpLog;
  perpLogs.data[outputJSONFile.positionLog.queryResponseKey] = perpLogs.data[
    outputJSONFile.positionLog.queryResponseKey
  ].concat([perpLog]);
};
