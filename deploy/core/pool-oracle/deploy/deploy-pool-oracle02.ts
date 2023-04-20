import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig, writeConfigFile } from "../../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying PoolOracle02 Contract`);
  const PoolOracle02 = await ethers.getContractFactory(
    "PoolOracle02",
    deployer
  );
  const poolOracle02 = await upgrades.deployProxy(PoolOracle02, [
    config.Pools.ALP.pythPriceFeed,
  ]);
  console.log(`> ⛓ Tx submitted: ${poolOracle02.deployTransaction.hash}`);
  await poolOracle02.deployTransaction.wait(3);
  console.log(`> 🟢 Deployed at: ${poolOracle02.address}`);

  config.Pools.ALP.oracle02 = poolOracle02.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    poolOracle02.address
  );

  console.log(`> Verifying contract on Tenderly...`);
  await tenderly.verify({
    address: implAddress,
    name: "PoolOracle02",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["PoolOracle02"];
