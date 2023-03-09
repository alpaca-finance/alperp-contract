import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ALP__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const COOLDOWN = 15;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = ALP__factory.connect(config.Tokens.ALP, deployer);
  const tx = await token.setLiquidityCooldown(COOLDOWN);
  const txReceipt = await tx.wait();
  console.log(`Execute setLiquidityCooldown for ALP for ${COOLDOWN} seconds`);
};

export default func;
func.tags = ["SetLiquidityCooldown"];
