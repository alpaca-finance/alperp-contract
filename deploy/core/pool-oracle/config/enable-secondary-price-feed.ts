import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PoolOracle__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const poolOracle = PoolOracle__factory.connect(
    config.Pools.ALP.oracle,
    deployer
  );

  console.log("> Enable Secondary Price Feed for PoolOracle");
  const tx = await poolOracle.setIsSecondaryPriceEnabled(true);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["EnableSecondaryPriceFeed"];
