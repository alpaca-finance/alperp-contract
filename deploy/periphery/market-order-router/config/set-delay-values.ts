import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../../../utils/config";
import { MarketOrderRouter__factory } from "../../../../typechain";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Setting delay params`);
  const marketOrderRouter = MarketOrderRouter__factory.connect(
    config.MarketOrderRouter,
    deployer
  );
  let tx = await marketOrderRouter.setDelayValues(10, 180, 1800);
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for confirmation...`);
  await tx.wait(3);
  console.log(`> 🟢 Done`);
};

export default func;
func.tags = ["MarketOrderRouter_SetDelayValues"];
