import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { TradeMiningManager__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const START_TIMESTAMP = 1680739200;
  const END_TIMESTAMP = 1684972800;

  const deployer = (await ethers.getSigners())[0];
  const tradeMiningManager = TradeMiningManager__factory.connect(
    config.TradeMining.tradeMiningManager,
    deployer
  );

  console.log(`> Setting campaign period for miner`);
  const tx = await tradeMiningManager.setPeriod(START_TIMESTAMP, END_TIMESTAMP);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> Tx mined!`);

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetMiningManagerPeriod"];
