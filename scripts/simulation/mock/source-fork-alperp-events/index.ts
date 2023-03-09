import fs from "fs";
import { task, types } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  Log2,
  IRootObject,
  Log3,
  IUnionPerpTradeEvents,
  IOrderBookEvents,
  IMarketOrderRouterEvents,
  ITenderlySimulationList,
} from "./interfaces";
import {
  existedFile,
  fetchTenderlyForkSimulate,
  fetchTenderlyForkTransactionList,
  getActiveTransaction,
  getLocalOutputPath,
  getSimulatedListCachePath,
  readFile,
  uploadAllOutputSchema,
  writeFile,
} from "./utils";
import {
  defaultDateDataData,
  defaultOrderData,
  defaultPositionData,
  defaultPositionLogData,
  defaultStatisticData,
  events,
  outputJSONFile,
} from "./constants";
import { handlers as perpTradeHandlers } from "./perp-trade-handlers";
import { handlers as orderbookHandler } from "./orderbook-handlers/perp-orderbook-handlers";
import { handlers as marketOrderRouterHandlers } from "./orderbook-handlers/perp-market-order-router-handlers";

import { getConfig } from "../../utils";
import { IConfig } from "../../interfaces";
import { DateTime } from "luxon";

const mapSimulateData: (
  hre: HardhatRuntimeEnvironment,
  simulationResp: IRootObject
) => Promise<void> = async (
  hre: HardhatRuntimeEnvironment,
  { transaction, simulation }: IRootObject
): Promise<void> => {
  const config: IConfig = getConfig(hre);

  const logs: Array<[Log2, Log3]> =
    transaction.transaction_info.logs
      ?.map((log, index) => {
        return [log as Log2, simulation.receipt.logs[index] as Log3] as [
          Log2,
          Log3
        ];
      })
      .filter((log) => {
        return events.includes(log[0].name);
      }) ?? [];

  for (const log of logs) {
    console.info(
      `>> Sourcing log name ${log[0].name} from contract: ${log[1].address}`
    );
    if (
      !!perpTradeHandlers[log[0].name as IUnionPerpTradeEvents] &&
      log[1].address.toLowerCase() ===
        config.Pools.ALP.poolDiamond.toLowerCase()
    ) {
      console.info(`>> Sourcing from perp trade`);
      await perpTradeHandlers[log[0].name as IUnionPerpTradeEvents](
        log,
        transaction,
        hre
      );
    }

    if (
      !!orderbookHandler[log[0].name as IOrderBookEvents] &&
      log[1].address.toLowerCase() === config.Pools.ALP.orderbook.toLowerCase()
    ) {
      console.info(`>> Sourcing from limit order book`);
      await orderbookHandler[log[0].name as IOrderBookEvents](
        log,
        transaction,
        hre
      );
    }

    if (
      !!marketOrderRouterHandlers[log[0].name as IMarketOrderRouterEvents] &&
      log[1].address.toLowerCase() ===
        config.Pools.ALP.marketOrderRouter.toLowerCase()
    ) {
      console.info(`>> Sourcing from market order router`);
      await marketOrderRouterHandlers[log[0].name as IMarketOrderRouterEvents](
        log,
        transaction,
        hre
      );
    }

    console.info(`>> ✅ DONE Sourcing log name ${log[0].name}`);
  }
};

task(
  "invoke:source_fork_alperp_events",
  "Source events from tenderly and put into json files"
)
  .addParam("forkId", "Tenderly Fork Id")
  .addParam("shouldUpload", "Upload to s3", false, types.boolean)
  .setAction(
    async (
      { forkId, shouldUpload }: { forkId: string; shouldUpload: boolean },
      hre: HardhatRuntimeEnvironment
    ) => {
      // clear local file
      writeFile(
        defaultDateDataData,
        getLocalOutputPath(outputJSONFile.dayData.filename)
      );
      writeFile(
        defaultOrderData,
        getLocalOutputPath(outputJSONFile.order.filename)
      );
      writeFile(
        defaultPositionData,
        getLocalOutputPath(outputJSONFile.position.filename)
      );
      writeFile(
        defaultPositionLogData,
        getLocalOutputPath(outputJSONFile.positionLog.filename)
      );
      writeFile(
        defaultStatisticData,
        getLocalOutputPath(outputJSONFile.statistic.filename)
      );

      // get all transaction
      const simulationListCachePath: string = getSimulatedListCachePath(forkId);
      let simulationListCache: Array<ITenderlySimulationList> = [];
      if (existedFile(simulationListCachePath)) {
        const fileData: Array<ITenderlySimulationList> = readFile<
          Array<ITenderlySimulationList>
        >(simulationListCachePath);
        simulationListCache = fileData;
      }
      const newSimulated: Array<ITenderlySimulationList> =
        await fetchTenderlyForkTransactionList(
          forkId,
          simulationListCache[0]?.id ?? "0x0",
          1 // first page
        );
      console.info(`>> found new ${newSimulated.length} simulation(s)`);
      const simulationList: Array<ITenderlySimulationList> = [
        ...newSimulated,
        ...simulationListCache,
      ].sort(
        (a: ITenderlySimulationList, b: ITenderlySimulationList) =>
          DateTime.fromISO(b.created_at).toSeconds() -
          DateTime.fromISO(a.created_at).toSeconds()
      );
      // save cache list
      writeFile(simulationList, simulationListCachePath);

      // convert Array<ITenderlySimulationList> to Record<string, ITenderlySimulationList>
      // for reducing CPU usage that find ITenderlySimulationList.id in array
      const mapTransaction: Record<string, ITenderlySimulationList> =
        simulationList.reduce(
          (
            acc: Record<string, ITenderlySimulationList>,
            cur: ITenderlySimulationList
          ) => {
            acc[cur.id] = cur;
            return acc;
          },
          {} as Record<string, ITenderlySimulationList>
        );

      // get active transaction
      const activeTransactions: Array<ITenderlySimulationList> =
        getActiveTransaction(mapTransaction, simulationList[0]).reverse(); // reverse for ordering by createdDate

      for (const tx of activeTransactions) {
        // fetch each simulation
        const simulateResp: IRootObject = await fetchTenderlyForkSimulate(
          forkId,
          tx.id
        );

        // map data
        await mapSimulateData(hre, simulateResp);
      }

      // upload to cloud
      if (shouldUpload) {
        await uploadAllOutputSchema(forkId);
      }
    }
  );

task(
  "invoke:source_single_fork_alperp_events",
  "Source events from tenderly and put into json files"
)
  .addParam("forkId", "Tenderly Fork Id")
  .addParam("simulationId", "Simulation Id")
  .addParam("shouldUpload", "Upload to s3", false, types.boolean)
  .setAction(
    async (
      {
        forkId,
        simulationId,
        shouldUpload,
      }: { forkId: string; simulationId: string; shouldUpload: boolean },
      hre: HardhatRuntimeEnvironment
    ) => {
      // fetch simulation
      const simulateResp: IRootObject = await fetchTenderlyForkSimulate(
        forkId,
        simulationId
      );

      // map data
      await mapSimulateData(hre, simulateResp);

      // upload to cloud
      if (shouldUpload) {
        await uploadAllOutputSchema(forkId);
      }
    }
  );
