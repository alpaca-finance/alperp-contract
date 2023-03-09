import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PerpTradeFacet__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();
const PRIMARY_ACCOUNT = "";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = PerpTradeFacet__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );

  await (
    await pool.liquidate(
      PRIMARY_ACCOUNT,
      0,
      config.Tokens.BTCB,
      config.Tokens.BTCB,
      true,
      deployer.address,
      { gasLimit: 10000000 }
    )
  ).wait();
  console.log(`Execute liquidate`);
};

export default func;
func.tags = ["LiquidatePosition"];
