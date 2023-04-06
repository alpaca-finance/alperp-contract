import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolRouter04 = await ethers.getContractFactory(
    "PoolRouter04",
    deployer
  );

  console.log(`> Preparing to upgrade PoolRouter04`);
  const newPoolRouter04 = await upgrades.prepareUpgrade(
    config.PoolRouter,
    PoolRouter04
  );
  console.log(`> Done`);

  console.log(`> New PoolRouter04 Implementation address: ${newPoolRouter04}`);
  const upgradeTx = await upgrades.upgradeProxy(
    config.PoolRouter,
    PoolRouter04
  );
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait();
  console.log(`> Tx is mined!`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    config.PoolRouter
  );

  console.log(`> Verify contract on Tenderly`);
  await tenderly.verify({
    address: implAddress,
    name: "PoolRouter04",
  });
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["UpgradePoolRouter04"];
