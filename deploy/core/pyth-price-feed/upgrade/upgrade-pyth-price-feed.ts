import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../../../utils/config";
import { upgrade } from "../../../utils/upgradeable";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  await upgrade("PythPriceFeed", config.Pools.ALP.pythPriceFeed, deployer);
};

export default func;
func.tags = ["UpgradePythPriceFeed"];
