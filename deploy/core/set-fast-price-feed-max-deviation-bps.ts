import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FastPriceFeed__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const MAX_DEVIATION_BPS = 500;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const fastPriceFeed = FastPriceFeed__factory.connect(
    config.Pools.ALP.fastPriceFeed,
    deployer
  );

  console.log(
    `> Set Fast Price Feed Max Deviation BPS to ${MAX_DEVIATION_BPS}`
  );
  const tx = await fastPriceFeed.setMaxDeviationBasisPoints(MAX_DEVIATION_BPS);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetFastPriceFeedMaxDeviationBPS"];
