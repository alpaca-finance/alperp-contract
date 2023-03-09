import { config as dotEnvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "./scripts/simulation/interactable";
import "./scripts/simulation/mock/source-fork-alperp-events";

dotEnvConfig();

import * as tdly from "@tenderly/hardhat-tenderly";
tdly.setup({ automaticVerifications: false });

import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "hardhat-deploy";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    mainnet: {
      chainId: 56,
      url: process.env.BSC_MAINNET_RPC,
      accounts:
        process.env.BSC_MAINNET_PRIVATE_KEY !== undefined
          ? [process.env.BSC_MAINNET_PRIVATE_KEY]
          : [],
    },
    tenderly: {
      chainId: 56,
      url: process.env.BSC_TENDERLY_RPC,
      accounts:
        process.env.BSC_TENDERLY_PRIVATE_KEY !== undefined
          ? [process.env.BSC_TENDERLY_PRIVATE_KEY]
          : [],
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1,
      },
    },
  },
  paths: {
    sources: "./src",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  typechain: {
    outDir: "./typechain",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 100000,
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT_NAME!,
    username: process.env.TENDERLY_USERNAME!,
    privateVerification: true,
  },
};

export default config;
