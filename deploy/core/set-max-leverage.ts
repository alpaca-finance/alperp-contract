import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const plugin = config.Pools.ALP.orderbook;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  const tx = await pool.setMaxLeverage(100 * 10000);
  const txReceipt = await tx.wait();
  console.log(`Execute setMaxLeverage`);
};

export default func;
func.tags = ["SetMaxLeverage"];
