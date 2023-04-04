import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { TradeMiningManager__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const MINER_MANAGER_ADDRESS = config.TradeMining.address;
  const MINING_POINT_ADDRESS = config.TradeMining.miningPoint;

  const deployer = (await ethers.getSigners())[0];
  const tradeMiningManager = TradeMiningManager__factory.connect(
    MINER_MANAGER_ADDRESS,
    deployer
  );

  console.log(`> Setting mining point for miner`);
  const tx = await tradeMiningManager.setAp(MINING_POINT_ADDRESS);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> Tx mined!`);

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetMiningManagerPoint"];
