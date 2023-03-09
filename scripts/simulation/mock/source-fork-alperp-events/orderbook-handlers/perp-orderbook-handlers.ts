import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DateTime } from "luxon";
import {
  EventSource,
  IOrderBookEventHandlers,
  Log2,
  Log3,
  Transaction,
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
} from "./common";
import { ZERO } from "../constants";

export const handleCreateIncreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  _handleCreateOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[2].value,
    timestampUnix,
    log[0].inputs[9].value,
    log[0].inputs[10].value,
    EventSource.Orderbook
  );
  _handleCreateIncreaseOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    log[0].inputs[4].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    log[0].inputs[7].value,
    log[0].inputs[8].value,
    EventSource.Orderbook
  );
};

export const handleCancelIncreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  _handleCancelOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[2].value,
    timestampUnix,
    EventSource.Orderbook
  );
};

export const handleExecuteIncreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  _handleExecuteOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[2].value,
    timestampUnix,
    EventSource.Orderbook
  );
};

export const handleUpdateIncreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  _handleUpdateOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[2].value,
    log[0].inputs[4].value,
    log[0].inputs[5].value,
    EventSource.Orderbook
  );
  _handleUpdateIncreaseOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "increase",
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    EventSource.Orderbook
  );
};

export const handleCreateDecreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  _handleCreateOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[2].value,
    timestampUnix,
    log[0].inputs[8].value,
    log[0].inputs[9].value,
    EventSource.Orderbook
  );
  _handleCreateDecreaseOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    log[0].inputs[4].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    log[0].inputs[7].value,
    EventSource.Orderbook
  );
};

export const handleCancelDecreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  _handleCancelOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[2].value,
    timestampUnix,
    EventSource.Orderbook
  );
};

export const handleExecuteDecreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  _handleExecuteOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[2].value,
    timestampUnix,
    EventSource.Orderbook
  );
};

export const handleUpdateDecreaseOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  _handleUpdateOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[2].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    EventSource.Orderbook
  );
  _handleUpdateDecreaseOrder(
    log[0].inputs[0].value,
    log[0].inputs[1].value,
    "decrease",
    log[0].inputs[2].value,
    log[0].inputs[3].value,
    log[0].inputs[4].value,
    EventSource.Orderbook
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
  _handleCreateOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[1].value,
    timestampUnix,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    EventSource.Orderbook
  );
  _handleCreateSwapOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[1].value,
    log[0].inputs[2].value as Array<string>,
    log[0].inputs[3].value,
    log[0].inputs[4].value,
    EventSource.Orderbook
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
  _handleCancelOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[1].value,
    timestampUnix,
    EventSource.Orderbook
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
  _handleExecuteOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[1].value,
    timestampUnix,
    EventSource.Orderbook
  );
};

export const handleUpdateSwapOrder = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  _handleUpdateOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[1].value,
    log[0].inputs[5].value,
    log[0].inputs[6].value,
    EventSource.Orderbook
  );
  _handleUpdateSwapOrder(
    log[0].inputs[0].value,
    ZERO,
    "swap",
    log[0].inputs[1].value,
    log[0].inputs[2].value as Array<string>,
    log[0].inputs[3].value,
    EventSource.Orderbook
  );
};

export const handlers: IOrderBookEventHandlers = {
  CreateIncreaseOrder: handleCreateIncreaseOrder,
  CancelIncreaseOrder: handleCancelIncreaseOrder,
  ExecuteIncreaseOrder: handleExecuteIncreaseOrder,
  UpdateIncreaseOrder: handleUpdateIncreaseOrder,
  CreateDecreaseOrder: handleCreateDecreaseOrder,
  CancelDecreaseOrder: handleCancelDecreaseOrder,
  ExecuteDecreaseOrder: handleExecuteDecreaseOrder,
  UpdateDecreaseOrder: handleUpdateDecreaseOrder,
  CreateSwapOrder: handleCreateSwapOrder,
  CancelSwapOrder: handleCancelSwapOrder,
  ExecuteSwapOrder: handleExecuteSwapOrder,
  UpdateSwapOrder: handleUpdateSwapOrder,
};
