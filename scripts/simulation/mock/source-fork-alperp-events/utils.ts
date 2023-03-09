import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  IRootObject,
  ITenderlySimulationList,
  Log3,
  QueryResponse,
  Transaction,
} from "./interfaces";
import axios, { AxiosInstance, AxiosResponse } from "axios";
import fs from "fs";
import { dirname, join as pathJoin } from "path";
import { outputJSONFile } from "./constants";
import { S3Service } from "../../utils";

export const anAxiosOnTenderly: () => AxiosInstance = (): AxiosInstance => {
  if (
    !process.env.TENDERLY_USERNAME ||
    !process.env.TENDERLY_PROJECT_NAME ||
    !process.env.TENDERLY_ACCESS_KEY
  ) {
    throw new Error(
      "Please set TENDERLY_USERNAME, TENDERLY_PROJECT_NAME and TENDERLY_ACCESS_KEY"
    );
  }

  return axios.create({
    baseURL: `https://api.tenderly.co/api/v1/account/${process.env.TENDERLY_USERNAME}/project/${process.env.TENDERLY_PROJECT_NAME}`,
    headers: {
      "X-Access-Key": process.env.TENDERLY_ACCESS_KEY,
      "Content-Type": "application/json",
    },
  });
};

export const existedFile = <T>(filePath: string): boolean => {
  return fs.existsSync(filePath);
};

export const writeFile = <T>(config: T, filePath: string) => {
  console.info(`>> Writing ${filePath}`);
  fs.mkdirSync(dirname(filePath), { recursive: true }); // create a directory
  fs.writeFileSync(filePath, JSON.stringify(config, null, 2));
  console.info(`>> ✅ DONE Writing ${filePath}`);
};

export const readFile = <T>(filePath: string): T => {
  if (!existedFile(filePath)) {
    throw new Error(`readFile:: ${filePath} not found`);
  }

  console.info(`>> Reading ${filePath}`);
  const buffer = fs.readFileSync(filePath);
  console.info(`>> ✅ DONE Reading ${filePath}`);
  return JSON.parse(buffer.toString()) as T;
};

export const getEventID = (
  log: Log3,
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): string => {
  const logIndex = hre.ethers.BigNumber.from(log.logIndex)
    .toNumber()
    .toString();
  return `${tx.hash}-${logIndex}`;
};

export const getPreviousEventID = (
  log: Log3,
  tx: Transaction,
  hre: HardhatRuntimeEnvironment
): string => {
  const logIndex = hre.ethers.BigNumber.from(log.logIndex)
    .toNumber()
    .toString();
  return `${tx.hash}-${(Number(logIndex) - 1).toString()}`;
};

export const getLocalOutputPath: (outputFIlename: string) => string = (
  outputFilename: string
): string => {
  return pathJoin(__dirname, "..", "output", `${outputFilename}.json`);
};

export const getSimulatedListCachePath: (forkId: string) => string = (
  forkId: string
): string => {
  return pathJoin(__dirname, "..", "cache", forkId, "simulate_list.json");
};

export const getSimulatedCachePath: (
  forkId: string,
  simulationId: string
) => string = (forkId: string, simulationId: string): string => {
  return pathJoin(
    __dirname,
    "..",
    "cache",
    forkId,
    "simulations",
    `${simulationId}.json`
  );
};

export const getActiveTransaction: (
  mapTransaction: Record<string, ITenderlySimulationList>,
  transaction: ITenderlySimulationList
) => Array<ITenderlySimulationList> = (
  mapTransaction: Record<string, ITenderlySimulationList>,
  transaction: ITenderlySimulationList
): Array<ITenderlySimulationList> => {
  const parentTransaction: ITenderlySimulationList | undefined =
    mapTransaction[transaction.parent_id];
  if (!parentTransaction) {
    return [transaction];
  }

  return [
    transaction,
    ...getActiveTransaction(mapTransaction, parentTransaction), // recursive
  ];
};

export const fetchTenderlyForkTransactionList: (
  forkId: string,
  lastedSimulateListCacheID: string,
  page: number,
  perPage?: number
) => Promise<Array<ITenderlySimulationList>> = async (
  forkId: string,
  lastedSimulateListCacheID: string,
  page: number,
  perPage: number | undefined = 20
): Promise<Array<ITenderlySimulationList>> => {
  const tAxios = anAxiosOnTenderly();

  const resp: AxiosResponse<{
    fork_transactions: Array<ITenderlySimulationList>;
  }> = await tAxios.get<{ fork_transactions: Array<ITenderlySimulationList> }>(
    `fork/${forkId}/transactions?page=${page}&perPage=${perPage}&exclude_internal=true`
  );

  const newTxs: Array<ITenderlySimulationList> = [];

  for (const tx of resp.data.fork_transactions) {
    if (tx.id.toLowerCase() === lastedSimulateListCacheID.toLowerCase()) {
      break;
    }

    newTxs.push(tx);
  }

  if (newTxs.length < perPage) {
    return newTxs;
  }

  const list: Array<ITenderlySimulationList> = [
    ...newTxs,
    ...(await fetchTenderlyForkTransactionList(
      forkId,
      lastedSimulateListCacheID,
      page + 1,
      perPage
    )), // recursive
  ];

  return list;
};

export const fetchTenderlyForkSimulate: (
  forkId: string,
  simulationId: string
) => Promise<IRootObject> = async (
  forkId: string,
  simulationId: string
): Promise<IRootObject> => {
  // check cache first
  const simulationCachePath: string = getSimulatedCachePath(
    forkId,
    simulationId
  );
  if (fs.existsSync(simulationCachePath)) {
    const cache: IRootObject | undefined =
      readFile<IRootObject>(simulationCachePath);
    if (cache) {
      return cache;
    }
  }

  const tAxios = anAxiosOnTenderly();

  const resp: AxiosResponse<IRootObject> = await tAxios.get<IRootObject>(
    `fork/${forkId}/simulation/${simulationId}`
  );

  // save cache
  writeFile(resp.data, simulationCachePath);

  return resp.data;
};

export const uploadAllOutputSchema: (forkId: string) => Promise<void> = async (
  forkId: string
): Promise<void> => {
  if (!process.env.AWS_S3_ACCESS_KEY || !process.env.AWS_S3_SECRET_ACCESS_KEY) {
    console.error("Please set AWS_S3_ACCESS_KEY and AWS_S3_SECRET_ACCESS_KEY");
    return;
  }

  const s3Service = new S3Service(
    process.env.AWS_S3_ACCESS_KEY as string,
    process.env.AWS_S3_SECRET_ACCESS_KEY as string
  );

  for (const output of Object.values(outputJSONFile)) {
    const fileData = readFile<QueryResponse<unknown>>(
      getLocalOutputPath(output.filename)
    );

    const fileUrl = await s3Service.upload(
      fileData,
      "alpaca-static-api.alpacafinance.org",
      `bsc/v2/alperp/mock/${output.filename}.json`
    );

    console.log(`Uploaded ${output.filename} to ${fileUrl}`);
  }
};
