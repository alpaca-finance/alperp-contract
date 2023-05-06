import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig } from "../../../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const version = "PoolRouter05";
  const deployer = (await ethers.getSigners())[0];
  const PoolRouterFactory = await ethers.getContractFactory(
    version,
    deployer
  );

  console.log(`> Preparing to upgrade PoolRouter to ${version}`);
  const newPoolRouter = await upgrades.prepareUpgrade(
    config.PoolRouter,
    PoolRouterFactory
  );
  console.log(`> Done`);

  console.log(`> New PoolRouter Implementation address: ${newPoolRouter}`);
  const upgradeTx = await upgrades.upgradeProxy(
    config.PoolRouter,
    PoolRouterFactory
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
    name: version,
  });
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["PoolRouter_Upgrade"];
