import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolRouter04__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const poolRouter = PoolRouter04__factory.connect(config.PoolRouter, deployer);

  console.log(`> Set WNativeRelayer...`);
  const tx = await poolRouter.setWNativeRelayer(config.WNativeRelayer);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Tx mined!`);
};

export default func;
func.tags = ["SetWNativeRelayer"];
