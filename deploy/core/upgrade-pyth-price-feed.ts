import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const TARGET_ADDRESS = config.Pools.ALP.pythPriceFeed;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PythPriceFeed = await ethers.getContractFactory("PythPriceFeed", deployer);

  console.log(`> Preparing to upgrade PythPriceFeed`);
  const newPythPriceFeed = await upgrades.prepareUpgrade(
    TARGET_ADDRESS,
    PythPriceFeed
  );
  console.log(`> Done`);

  console.log(`> New PythPriceFeed Implementation address: ${newPythPriceFeed}`);
  const upgradeTx = await upgrades.upgradeProxy(TARGET_ADDRESS, PythPriceFeed);
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait();
  console.log(`> Tx is mined!`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    TARGET_ADDRESS
  );

  console.log(`> Verify contract on Tenderly`);
  await tenderly.verify({
    address: implAddress,
    name: "PythPriceFeed",
  });
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["UpgradePythPriceFeed"];
