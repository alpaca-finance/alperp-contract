import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { WNativeRelayer__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();
const whitelistedCaller = [config.PoolRouter, config.Pools.ALP.orderbook];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const wnativeRelayer = WNativeRelayer__factory.connect(
    config.WNativeRelayer,
    deployer
  );
  const tx = await wnativeRelayer.setCallerOk(whitelistedCaller, true);
  await tx.wait();
  console.log(`Done Set CallerOK to ${whitelistedCaller.join(", ")}`);
};

export default func;
func.tags = ["WNativeRelayerSetCallerOK"];
