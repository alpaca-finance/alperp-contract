import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const LIQUIDATORS = ["0xFef9d28767de30F4239B9b40Bc915919b0bcACe8"];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );

  console.log(`> Allow liquidators...`);
  const tx = await pool.setAllowLiquidators(LIQUIDATORS, true);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> Tx mined!`);

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetAllowLiquidators"];
