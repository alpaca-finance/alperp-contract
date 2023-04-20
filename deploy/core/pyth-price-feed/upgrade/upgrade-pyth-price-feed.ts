import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PythPriceFeed = await ethers.getContractFactory(
    "PythPriceFeed",
    deployer
  );

  console.log(`> Preparing to upgrade PythPriceFeed`);
  const newPythPriceFeed = await upgrades.prepareUpgrade(
    config.Pools.ALP.pythPriceFeed,
    PythPriceFeed
  );
  console.log(`> Done`);

  console.log(
    `> New PythPriceFeed Implementation address: ${newPythPriceFeed}`
  );
  const upgradeTx = await upgrades.upgradeProxy(
    config.Pools.ALP.pythPriceFeed,
    PythPriceFeed
  );
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait();
  console.log(`> 🟢 Tx is mined!`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    config.Pools.ALP.pythPriceFeed
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
