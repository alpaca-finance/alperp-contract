import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const MINING_POINT = config.TradeMining.miningPoint;

  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying TradeMiningManager Contract`);
  const TradeMiningManager = await ethers.getContractFactory(
    "TradeMiningManager",
    deployer
  );
  const tradeMiningManager = await upgrades.deployProxy(TradeMiningManager, [
    MINING_POINT,
  ]);
  console.log(`> ⛓ Tx submitted: ${tradeMiningManager.deployTransaction.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await tradeMiningManager.deployed();
  console.log(`> Tx mined!`);
  console.log(`> Deployed at: ${tradeMiningManager.address}`);

  config.TradeMining.address = tradeMiningManager.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly...`);
  const implAddress = await getImplementationAddress(
    ethers.provider,
    tradeMiningManager.address
  );
  await tenderly.verify({
    address: implAddress,
    name: "TradeMiningManager",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["TradeMiningManager"];
