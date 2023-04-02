import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Miner__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const MINER_ADDRESS = config.Pools.ALP.miner;
  const MINING_POINT_ADDRESS = config.Tokens.AP;

  const deployer = (await ethers.getSigners())[0];
  const miner = Miner__factory.connect(MINER_ADDRESS, deployer);

  console.log(`> Setting mining point for miner`);
  const tx = await tradeMiningManager.setMiningPoint(MINING_POINT_ADDRESS);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> Tx mined!`);

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetMinerMiningPoint"];
