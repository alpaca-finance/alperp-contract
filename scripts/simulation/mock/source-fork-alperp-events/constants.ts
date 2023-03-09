import {
  IMarketOrderRouterEventsKey,
  IOrderBookEventsKey,
  IOutputJSONFile,
  IPositionEventsKey,
  IPositionLogEventsKey,
  IStatisticEventsKey,
} from "./interfaces";

export const ZERO: string = "0";

export const positionEvents: Array<IPositionEventsKey> = [
  "UpdatePosition",
  "ClosePosition",
];

export const positionLogEvents: Array<IPositionLogEventsKey> = [
  "IncreasePosition",
  "DecreasePosition",
];

export const statisticEvents: Array<IStatisticEventsKey> = [
  "IncreasePosition",
  "DecreasePosition",
  "Swap",
  "CollectBorrowingFee",
  "CollectPositionFee",
  "CollectSwapFee",
];

export const orderEvents: Array<IOrderBookEventsKey> = [
  "CreateIncreaseOrder",
  "CancelIncreaseOrder",
  "ExecuteIncreaseOrder",
  "UpdateIncreaseOrder",
  "CreateDecreaseOrder",
  "CancelDecreaseOrder",
  "ExecuteDecreaseOrder",
  "UpdateDecreaseOrder",
  "CreateSwapOrder",
  "CancelSwapOrder",
  "ExecuteSwapOrder",
  "UpdateSwapOrder",
];

export const marketOrderEvents: Array<IMarketOrderRouterEventsKey> = [
  "CreateIncreasePosition",
  "CancelIncreasePosition",
  "ExecuteIncreasePosition",
  "CreateDecreasePosition",
  "CancelDecreasePosition",
  "ExecuteDecreasePosition",
  "CreateSwapOrder",
  "CancelSwapOrder",
  "ExecuteSwapOrder",
];

export const events: Array<string> = [
  ...statisticEvents,
  ...positionEvents,
  ...positionLogEvents,
  ...orderEvents,
  ...marketOrderEvents,
];

export const LIQUIDATORS: Array<string> = [];

export const outputJSONFile: Record<
  "dayData" | "order" | "position" | "positionLog" | "statistic",
  IOutputJSONFile
> = {
  dayData: {
    filename: "daydata",
    queryResponseKey: "dayDatas",
  },
  order: {
    filename: "orders",
    queryResponseKey: "orders",
  },
  position: {
    filename: "positions",
    queryResponseKey: "perpPositions",
  },
  positionLog: {
    filename: "position_logs",
    queryResponseKey: "PositionLogs",
  },
  statistic: {
    filename: "statistics",
    queryResponseKey: "statistics",
  },
};

export const defaultDateDataData = {
  data: { [outputJSONFile.dayData.queryResponseKey]: [] },
};
export const defaultOrderData = {
  data: { [outputJSONFile.order.queryResponseKey]: [] },
};
export const defaultPositionData = {
  data: { [outputJSONFile.position.queryResponseKey]: [] },
};
export const defaultPositionLogData = {
  data: { [outputJSONFile.positionLog.queryResponseKey]: [] },
};
export const defaultStatisticData = {
  data: { [outputJSONFile.statistic.queryResponseKey]: [] },
};
