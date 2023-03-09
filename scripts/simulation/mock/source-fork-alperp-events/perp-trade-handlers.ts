import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  QueryResponse,
  IStatistic,
  Log2,
  Log3,
  Transaction,
  IPosition,
  IPositionLog,
  Exposure,
  PositionLogEvents,
  IPositionLogEventsKey,
  IPerpTradeEventHandlers,
  IHandler,
  IDayData,
  ILongShortLog,
  EventSource,
  IPerpLog,
  TypeLog,
  Action,
  ISwapLog,
} from "./interfaces";
import {
  writeFile,
  readFile,
  getPreviousEventID,
  getEventID,
  getLocalOutputPath,
} from "./utils";
import { DateTime } from "luxon";
import { LIQUIDATORS, outputJSONFile } from "./constants";

const dayDataFilePath: string = getLocalOutputPath(
  outputJSONFile.dayData.filename
);
const positionsFilePath: string = getLocalOutputPath(
  outputJSONFile.position.filename
);
const positionLogsFilePath: string = getLocalOutputPath(
  outputJSONFile.positionLog.filename
);
const statisticFilePath: string = getLocalOutputPath(
  outputJSONFile.statistic.filename
);

const _loadDayData = async (
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<QueryResponse<Array<IDayData>>> => {
  const date = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  const id = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger() / 86400
  ).toString();

  const dayData = readFile<QueryResponse<Array<IDayData>>>(dayDataFilePath);
  const hit = dayData.data[outputJSONFile.dayData.queryResponseKey].find(
    (dayData) => dayData.id === id
  );
  if (!hit) {
    dayData.data[outputJSONFile.dayData.queryResponseKey].push({
      id: id,
      date: date,
      volumeUSD: "0",
      feeUSD: "0",
    });

    _updateAccumData(id, hre);
  }

  return dayData;
};

const _updateDayData = async (
  totalTradingVolume: string,
  totalFee: string,
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const dayData = await _loadDayData(tx, hre);
  const id = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger() / 86400
  ).toString();

  const hit = dayData.data[outputJSONFile.dayData.queryResponseKey].find(
    (dayData) => dayData.id === id
  );
  if (!hit) {
    return;
  }

  hit.volumeUSD = hre.ethers.BigNumber.from(hit.volumeUSD)
    .add(totalTradingVolume)
    .toString();
  hit.feeUSD = hre.ethers.BigNumber.from(hit.feeUSD).add(totalFee).toString();

  writeFile(dayData, dayDataFilePath);
};

const _accumulateTradingVolume = async (
  size: string,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const statistic = await _loadStatistic();
  statistic.data[
    outputJSONFile.statistic.queryResponseKey
  ][0].totalTradingVolume = hre.ethers.BigNumber.from(
    statistic.data[outputJSONFile.statistic.queryResponseKey][0]
      .totalTradingVolume
  )
    .add(hre.ethers.BigNumber.from(size))
    .toString();

  writeFile(statistic, statisticFilePath);
};

const _accumulateTradingFee = async (
  size: string,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const statistic = await _loadStatistic();
  statistic.data[outputJSONFile.statistic.queryResponseKey][0].totalFees =
    hre.ethers.BigNumber.from(
      statistic.data[outputJSONFile.statistic.queryResponseKey][0].totalFees
    )
      .add(hre.ethers.BigNumber.from(size))
      .toString();

  writeFile(statistic, statisticFilePath);
};

const _loadStatistic = async (): Promise<QueryResponse<Array<IStatistic>>> => {
  const savedStatistic =
    readFile<QueryResponse<Array<IStatistic>>>(statisticFilePath);
  const hit = savedStatistic.data[outputJSONFile.statistic.queryResponseKey][0];
  if (!hit) {
    savedStatistic.data[outputJSONFile.statistic.queryResponseKey].push({
      id: "0",
      totalFees: "0",
      totalTradingVolume: "0",
      openInterest: "0",
      accVolume7Days: "0",
      accVolume30Days: "0",
      avgVolume7Days: "0",
      avgVolume30Days: "0",
    });
  }
  return savedStatistic;
};

const _updateAccumData = async (
  currentIndex: string,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const stats = await _loadStatistic();
  let tmp = hre.ethers.constants.Zero;
  for (let i = 0; i < 31; i++) {
    if (i === 7)
      stats.data[outputJSONFile.statistic.queryResponseKey][0].accVolume7Days =
        tmp.toString(); // 7, 30
    if (i === 30) {
      stats.data[outputJSONFile.statistic.queryResponseKey][0].accVolume30Days =
        tmp.toString();
      break;
    }

    const dayData = readFile<QueryResponse<Array<IDayData>>>(dayDataFilePath);
    const daydatas = dayData.data[outputJSONFile.dayData.queryResponseKey].find(
      (dayData) =>
        dayData.id ===
        hre.ethers.BigNumber.from(currentIndex)
          .sub(i + 1)
          .toString()
    );
    if (!daydatas) {
      continue;
    }

    tmp = tmp.add(daydatas.volumeUSD);
  }

  stats.data[outputJSONFile.statistic.queryResponseKey][0].avgVolume7Days =
    hre.ethers.BigNumber.from(
      stats.data[outputJSONFile.statistic.queryResponseKey][0].accVolume7Days
    )
      .div(7)
      .toString();
  stats.data[outputJSONFile.statistic.queryResponseKey][0].avgVolume30Days =
    hre.ethers.BigNumber.from(
      stats.data[outputJSONFile.statistic.queryResponseKey][0].accVolume30Days
    )
      .div(30)
      .toString();

  writeFile(stats, statisticFilePath);
};

const _storeLongShortLog = async (
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

const _storeSwapLog = async (
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

export const handleUpdatePosition: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleUpdatePosition");
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  const savedPositions =
    readFile<QueryResponse<Array<IPosition>>>(positionsFilePath);
  const savedLogs =
    readFile<QueryResponse<Array<IPositionLog>>>(positionLogsFilePath);
  const relatedLog = savedLogs.data[
    outputJSONFile.positionLog.queryResponseKey
  ].find((savedLog) => {
    return savedLog.id === getPreviousEventID(log[1], tx, hre);
  });
  if (!relatedLog) {
    return;
  }
  const positionId = log[0].inputs[0].value;
  const hit = savedPositions.data[
    outputJSONFile.position.queryResponseKey
  ].find((position) => {
    return position.id === positionId;
  });
  if (!hit) {
    savedPositions.data[outputJSONFile.position.queryResponseKey].push({
      id: positionId,
      positionId: positionId,
      primaryAccount: relatedLog.primaryAccount,
      subAccountId: relatedLog.subAccountId,
      collateralToken: relatedLog.collateralToken,
      indexToken: relatedLog.indexToken,
      exposure: relatedLog.exposure,
      size: log[0].inputs[1].value,
      collateral: log[0].inputs[2].value,
      averagePrice: log[0].inputs[3].value,
      entryBorrowingRate: log[0].inputs[4].value,
      reserveAmount: log[0].inputs[5].value,
      realizedPnl: log[0].inputs[6].value,
      price: log[0].inputs[7].value,
      entryFundingRate: log[0].inputs[8].value,
      fundingFeeDebt: log[0].inputs[9].value,
      openInterest: log[0].inputs[10].value,
      createdAt: timestampUnix,
      updatedAt: timestampUnix,
      closedAt: null,
      liquidatedAt: null,
    });
  } else {
    hit.size = log[0].inputs[1].value;
    hit.collateral = log[0].inputs[2].value;
    hit.averagePrice = log[0].inputs[3].value;
    hit.entryBorrowingRate = log[0].inputs[4].value;
    hit.reserveAmount = log[0].inputs[5].value;
    hit.realizedPnl = log[0].inputs[6].value;
    hit.price = log[0].inputs[7].value;
    hit.entryFundingRate = log[0].inputs[8].value;
    hit.fundingFeeDebt = log[0].inputs[9].value;
    hit.openInterest = log[0].inputs[10].value;
    hit.updatedAt = timestampUnix;
    hit.closedAt = null;
    hit.liquidatedAt = null;
  }

  writeFile(savedPositions, positionsFilePath);
  console.log(">> ✅ DONE handleUpdatePosition");
};

export const handleClosePosition: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleClosePosition");
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  const savedPositions =
    readFile<QueryResponse<Array<IPosition>>>(positionsFilePath);
  const savedLogs =
    readFile<QueryResponse<Array<IPositionLog>>>(positionLogsFilePath);
  const relatedLog = savedLogs.data[
    outputJSONFile.positionLog.queryResponseKey
  ].find((savedLog) => {
    return savedLog.id === getPreviousEventID(log[1], tx, hre);
  });
  if (!relatedLog) {
    return;
  }
  const positionId = log[0].inputs[0].value;
  const hit = savedPositions.data[
    outputJSONFile.position.queryResponseKey
  ].find((position) => {
    return position.id === positionId;
  });
  if (!hit) {
    console.log(`Position ${positionId} not found`);
    return;
  }
  hit.size = log[0].inputs[1].value;
  hit.collateral = log[0].inputs[2].value;
  hit.averagePrice = log[0].inputs[3].value;
  hit.entryBorrowingRate = log[0].inputs[4].value;
  hit.reserveAmount = log[0].inputs[5].value;
  hit.realizedPnl = log[0].inputs[6].value;
  hit.entryFundingRate = log[0].inputs[7].value;
  hit.openInterest = log[0].inputs[8].value;
  hit.price = "0";
  hit.fundingFeeDebt = "0";
  hit.updatedAt = timestampUnix;
  hit.closedAt = timestampUnix;
  hit.liquidatedAt = null;
  hit.price = relatedLog.price;

  writeFile(savedPositions, positionsFilePath);
  console.log(">> ✅ DONE handleClosePosition");
};

export const handleIncreasePosition: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleIncreasePosition");
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  const savedLogs =
    readFile<QueryResponse<Array<IPositionLog>>>(positionLogsFilePath);

  const logIndex = hre.ethers.BigNumber.from(log[1].logIndex)
    .toNumber()
    .toString();
  const positionLog: IPositionLog = {
    id: getEventID(log[1], tx, hre),
    tx: tx.hash,
    logIndex: logIndex,
    positionId: log[0].inputs[0].value,
    primaryAccount: log[0].inputs[1].value,
    subAccountId: log[0].inputs[2].value,
    collateralToken: log[0].inputs[3].value,
    indexToken: log[0].inputs[4].value,
    collateralDeltaUsd: log[0].inputs[5].value,
    sizeDelta: log[0].inputs[6].value,
    exposure: log[0].inputs[7].value ? Exposure.Long : Exposure.Short,
    price: log[0].inputs[8].value,
    feeUsd: log[0].inputs[9].value,
    eventName: PositionLogEvents[log[0].name as IPositionLogEventsKey],
    createdAt: timestampUnix,
  } as IPositionLog;

  savedLogs.data[outputJSONFile.positionLog.queryResponseKey] = savedLogs.data[
    outputJSONFile.positionLog.queryResponseKey
  ].concat([positionLog]);

  await _accumulateTradingVolume(log[0].inputs[6].value, hre);
  await _updateDayData(log[0].inputs[6].value, "0", tx, hre);

  writeFile(savedLogs, positionLogsFilePath);
  console.log(">> ✅ DONE handleIncreasePosition");
};

export const handleDecreasePosition: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleDecreasePosition");
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  const savedLogs =
    readFile<QueryResponse<Array<IPositionLog>>>(positionLogsFilePath);

  const logIndex = hre.ethers.BigNumber.from(log[1].logIndex)
    .toNumber()
    .toString();
  const positionLog: IPositionLog = {
    id: getEventID(log[1], tx, hre),
    tx: tx.hash,
    logIndex: logIndex,
    positionId: log[0].inputs[0].value,
    primaryAccount: log[0].inputs[1].value,
    subAccountId: log[0].inputs[2].value,
    collateralToken: log[0].inputs[3].value,
    indexToken: log[0].inputs[4].value,
    collateralDeltaUsd: log[0].inputs[5].value,
    sizeDelta: log[0].inputs[6].value,
    exposure: log[0].inputs[7].value ? Exposure.Long : Exposure.Short,
    price: log[0].inputs[8].value,
    feeUsd: log[0].inputs[9].value,
    eventName: PositionLogEvents[log[0].name as IPositionLogEventsKey],
    createdAt: timestampUnix,
  } as IPositionLog;

  savedLogs.data[outputJSONFile.positionLog.queryResponseKey] = savedLogs.data[
    outputJSONFile.positionLog.queryResponseKey
  ].concat([positionLog]);

  await _accumulateTradingVolume(log[0].inputs[6].value, hre);
  await _updateDayData(log[0].inputs[6].value, "0", tx, hre);

  if (LIQUIDATORS.map((l) => l.toLowerCase()).includes(tx.from.toLowerCase())) {
    await _storeLongShortLog(
      log[0].inputs[1].value,
      log[0].inputs[2].value,
      TypeLog.LongShort,
      Action.Liquidation,
      log[1],
      tx,
      hre,
      timestampUnix,
      log[0].inputs[4].value,
      log[0].inputs[6].value,
      log[0].inputs[7].value,
      "0",
      false,
      log[0].inputs[8].value,
      EventSource.PerpTradeFacet
    );
  }
  writeFile(savedLogs, positionLogsFilePath);
  console.log(">> ✅ DONE handleDecreasePosition");
};

export const handleSwap: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleSwap");
  const timestampUnix = Math.floor(
    DateTime.fromISO(tx.timestamp).toUnixInteger()
  ).toString();
  const deployer = (await hre.ethers.getSigners())[0];
  const getterFacet = (
    await hre.ethers.getContractFactory("GetterFacet", deployer)
  ).attach(log[1].address);
  const token = (await hre.ethers.getContractFactory("ERC20", deployer)).attach(
    log[0].inputs[1].value
  );
  const oracle = (
    await hre.ethers.getContractFactory("PoolOracle", deployer)
  ).attach(await getterFacet.oracle());

  let midPrice = (await oracle.getMaxPrice(log[0].inputs[1].value))
    .add(await oracle.getMinPrice(log[0].inputs[1].value))
    .div(2);

  let size = midPrice
    .mul(log[0].inputs[3].value)
    .div(hre.ethers.utils.parseUnits("1", await token.decimals()));

  await _accumulateTradingVolume(size.toString(), hre);
  await _updateDayData(size.toString(), "0", tx, hre);
  _storeSwapLog(
    log[0].inputs[0].value,
    "0",
    TypeLog.Swap,
    Action.Swap,
    log[1],
    tx,
    hre,
    timestampUnix,
    [log[0].inputs[1].value, log[0].inputs[2].value],
    log[0].inputs[3].value,
    log[0].inputs[4].value,
    "0",
    false,
    EventSource.LiquidityFacet
  );

  console.log(">> ✅ DONE handleSwap");
};

export const handleCollectPositionFee: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleCollectPositionFee");
  await _accumulateTradingFee(log[0].inputs[2].value, hre);
  await _updateDayData("0", log[0].inputs[2].value, tx, hre);
  console.log(">> ✅ DONE handleCollectPositionFee");
};

export const handleCollectBorrowingFee: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleCollectBorrowingFee");
  await _accumulateTradingFee(log[0].inputs[2].value, hre);
  await _updateDayData("0", log[0].inputs[2].value, tx, hre);
  console.log(">> ✅ DONE handleCollectBorrowingFee");
};

export const handleCollectSwapFee: IHandler = async (
  log: [Log2, Log3],
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  console.log(">> handleCollectSwapFee");
  await _accumulateTradingFee(log[0].inputs[2].value, hre);
  await _updateDayData("0", log[0].inputs[2].value, tx, hre);
  console.log(">> ✅ DONE handleCollectSwapFee");
};

export const handlers: IPerpTradeEventHandlers = {
  IncreasePosition: handleIncreasePosition,
  DecreasePosition: handleDecreasePosition,
  UpdatePosition: handleUpdatePosition,
  ClosePosition: handleClosePosition,
  Swap: handleSwap,
  CollectBorrowingFee: handleCollectBorrowingFee,
  CollectPositionFee: handleCollectPositionFee,
  CollectSwapFee: handleCollectSwapFee,
};
