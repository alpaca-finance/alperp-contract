import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  const tx = await pool.setIsDynamicFeeEnable(true);
  const txReceipt = await tx.wait();
  console.log(`Execute setIsDynamicFeeEnable with tx: ${tx.hash}`);
};

export default func;
func.tags = ["SetIsDynamicFeeEnable"];
