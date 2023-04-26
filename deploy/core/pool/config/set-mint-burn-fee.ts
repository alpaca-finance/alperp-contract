import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const mintFeeBps = 30;

  console.log(`> Set mint/burn fee bps to ${mintFeeBps}`);

  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  const tx = await pool.setMintBurnFeeBps(mintFeeBps);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> 🟢 Done`);
};

export default func;
func.tags = ["AdminFacet_SetMintBurnFeeBps"];
