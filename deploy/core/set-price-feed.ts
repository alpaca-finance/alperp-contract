import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolOracle__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const ORACLE = config.Pools.ALP.oracle;
const TOKENS = [
  config.Tokens.BTCB, // BTCB
  config.Tokens.ETH, // ETH
  config.Tokens.WBNB, // WBNB
  config.Tokens.USDC, // USDC
  config.Tokens.USDT, // USDT
];
const FEED_INFOS = [
  {
    priceFeed: "0x264990fbd0a4796a3e3d8e37c4d5f87a3aca5ebf", // BTCB
    decimals: 8,
    spreadBps: 0,
    isStrictStable: false,
  },
  {
    priceFeed: "0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e", // ETH
    decimals: 8,
    spreadBps: 0,
    isStrictStable: false,
  },
  {
    priceFeed: "0x0567f2323251f0aab15c8dfb1967e4e8a7d42aee", // WBNB
    decimals: 8,
    spreadBps: 0,
    isStrictStable: false,
  },
  {
    priceFeed: "0x51597f405303C4377E36123cBc172b13269EA163", // USDC
    decimals: 8,
    spreadBps: 0,
    isStrictStable: true,
  },
  {
    priceFeed: "0xB97Ad0E74fa7d920791E90258A6E2085088b4320", // USDT
    decimals: 8,
    spreadBps: 0,
    isStrictStable: true,
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const oracle = PoolOracle__factory.connect(ORACLE, deployer);

  console.log("> Setting price feeds");
  const tx = await oracle.setPriceFeed(TOKENS, FEED_INFOS);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done setting price feeds`);
};

export default func;
func.tags = ["SetPriceFeed"];
