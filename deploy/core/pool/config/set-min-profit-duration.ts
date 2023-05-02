import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const MIN_DURATION = 180; // 3 min

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  console.log(`> Setting Pool's min profit duration`);
  const tx = await pool.setMinProfitDuration(MIN_DURATION);
  await tx.wait();
  console.log(`> ✅ Done setting Pool's min profit duration`);
};

export default func;
func.tags = ["SetMinProfitDuration"];
