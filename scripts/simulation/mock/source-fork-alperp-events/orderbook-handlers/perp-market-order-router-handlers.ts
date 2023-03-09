import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DateTime } from "luxon";
import {
  Action,
  EventSource,
  IMarketOrderRouterEventHandlers,
  Log2,
  Log3,
  Transaction,
  TypeLog,
} from "../interfaces";
import {
  _handleCancelOrder,
  _handleCreateDecreaseOrder,
  _handleCreateIncreaseOrder,
  _handleCreateOrder,
  _handleCreateSwapOrder,
  _handleExecuteOrder,
  _handleUpdateDecreaseOrder,
  _handleUpdateIncreaseOrder,
  _handleUpdateOrder,
  _handleUpdateSwapOrder,
  _storeLongShortLog,
  _storeSwapLog,
} from "./common";
import { ZERO } from "../constants";

export const handleCreateIncreasePosition = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleCreateOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[11].value,
    timestampUnix,
    log[0].inputs[8].value,
    !log[0].inputs[7].value,
    EventSource.MarketOrderRouter
  );
  await _handleCreateIncreaseOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[11].value,
    log[0].inputs[2].value[0],
    log[0].inputs[4].value,
    log[0].inputs[2].value[log[0].inputs[2].value.length - 1],
    log[0].inputs[3].value,
    log[0].inputs[6].value,
    log[0].inputs[7].value,
    EventSource.MarketOrderRouter
  );
  await _storeLongShortLog(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    TypeLog.LongShort,
    Action.CreateIncreaseOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[3].value,
    log[0].inputs[6].value,
    log[0].inputs[7].value,
    log[0].inputs[8].value,
    !log[0].inputs[7].value,
    "0",
    EventSource.MarketOrderRouter
  );
};

export const handleCancelIncreasePosition = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleCancelOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[10].value,
    timestampUnix,
    EventSource.MarketOrderRouter
  );
  await _storeLongShortLog(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    TypeLog.LongShort,
    Action.CancelIncreaseOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[3].value,
    log[0].inputs[6].value,
    log[0].inputs[7].value,
    "0",
    !log[0].inputs[7].value,
    "0",
    EventSource.MarketOrderRouter
  );
};

export const handleExecuteIncreasePosition = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleExecuteOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[10].value,
    timestampUnix,
    EventSource.MarketOrderRouter
  );
  await _storeLongShortLog(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    TypeLog.LongShort,
    Action.ExecuteIncreaseOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[3].value,
    log[0].inputs[6].value,
    log[0].inputs[7].value,
    "0",
    !log[0].inputs[7].value,
    log[0].inputs[11].value,
    EventSource.MarketOrderRouter
  );
};

export const handleCreateDecreasePosition = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleCreateOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[12].value,
    timestampUnix,
    log[0].inputs[8].value,
    log[0].inputs[6].value,
    EventSource.MarketOrderRouter
  );
  await _handleCreateDecreaseOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[12].value,
    log[0].inputs[2].value[0],
    log[0].inputs[4].value,
    log[0].inputs[3].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    EventSource.MarketOrderRouter
  );
  await _storeLongShortLog(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    TypeLog.LongShort,
    Action.CreateDecreaseOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[3].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    log[0].inputs[8].value,
    log[0].inputs[6].value,
    "0",
    EventSource.MarketOrderRouter
  );
};

export const handleCancelDecreasePosition = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleCancelOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[9].value,
    timestampUnix,
    EventSource.MarketOrderRouter
  );
  await _storeLongShortLog(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    TypeLog.LongShort,
    Action.CancelDecreaseOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[3].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    "0",
    log[0].inputs[6].value,
    "0",
    EventSource.MarketOrderRouter
  );
};

export const handleExecuteDecreasePosition = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleExecuteOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[9].value,
    timestampUnix,
    EventSource.MarketOrderRouter
  );
  await _storeLongShortLog(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    TypeLog.LongShort,
    Action.ExecuteDecreaseOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[3].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    "0",
    log[0].inputs[6].value,
    log[0].inputs[10].value,
    EventSource.MarketOrderRouter
  );
};

export const handleCreateSwapOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleCreateOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[7].value,
    timestampUnix,
    "0",
    true,
    EventSource.MarketOrderRouter
  );
  await _handleCreateSwapOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[7].value,
    log[0].inputs[1].value as Array<string>,
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    EventSource.MarketOrderRouter
  );
  await _storeSwapLog(
    log[0].inputs[0].value,
    "0",
    TypeLog.Swap,
    Action.CreateSwapOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[1].value,
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    "0",
    true,
    EventSource.MarketOrderRouter
  );
};

export const handleCancelSwapOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleCancelOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[8].value,
    timestampUnix,
    EventSource.MarketOrderRouter
  );
  await _storeSwapLog(
    log[0].inputs[0].value,
    "0",
    TypeLog.Swap,
    Action.CancelSwapOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[1].value,
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    "0",
    true,
    EventSource.MarketOrderRouter
  );
};

export const handleExecuteSwapOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  await _handleExecuteOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[9].value,
    timestampUnix,
    EventSource.MarketOrderRouter
  );
  await _storeSwapLog(
    log[0].inputs[0].value,
    "0",
    TypeLog.Swap,
    Action.ExecuteSwapOrder,
    log[1],
    tx,
    hre,
    timestampUnix,
    log[0].inputs[1].value,
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    "0",
    true,
    EventSource.MarketOrderRouter
  );
};

export const handlers: IMarketOrderRouterEventHandlers = {
  CreateIncreasePosition: handleCreateIncreasePosition,
  CancelIncreasePosition: handleCancelIncreasePosition,
  ExecuteIncreasePosition: handleExecuteIncreasePosition,
  CreateDecreasePosition: handleCreateDecreasePosition,
  CancelDecreasePosition: handleCancelDecreasePosition,
  ExecuteDecreasePosition: handleExecuteDecreasePosition,
  CreateSwapOrder: handleCreateSwapOrder,
  CancelSwapOrder: handleCancelSwapOrder,
  ExecuteSwapOrder: handleExecuteSwapOrder,
};
