import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../../../utils/config";
import { upgrade } from "../../../utils/upgradeable";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const config = getConfig();
  await upgrade("ALPStaking", config.Staking.ALPStaking.address, deployer);
};

export default func;
func.tags = ["UpgradeALPStaking"];
