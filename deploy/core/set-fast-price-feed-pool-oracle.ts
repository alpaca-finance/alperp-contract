import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FastPriceFeed__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const POOL_ORACLE = config.Pools.ALP.oracle;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const fastPriceFeed = FastPriceFeed__factory.connect(
    config.Pools.ALP.fastPriceFeed,
    deployer
  );

  console.log("> Set Fast Price Feed Pool oracle");
  const tx = await fastPriceFeed.setPoolOracle(POOL_ORACLE);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetFastPriceFeedPoolOracle"];
