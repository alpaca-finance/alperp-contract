import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FastPriceFeed__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const minAuthorizations = 1;
const signers = ["0xCc4B77A97eBa4734c6D61c189B2B499F93C9710E"]; // DEPLOYER
const updaters = ["0x0B3C34456013c66E28A856492B300ee61cbC8fc5"]; // ORDER EXECUTOR

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const fastPriceFeed = FastPriceFeed__factory.connect(
    config.Pools.ALP.fastPriceFeed,
    deployer
  );

  console.log("> Init FastPriceFeed");
  const tx = await fastPriceFeed.init(minAuthorizations, signers, updaters);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["InitFastPriceFeed"];
