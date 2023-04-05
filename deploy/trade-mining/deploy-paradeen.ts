import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const deployer = (await ethers.getSigners())[0];

  const AP = config.TradeMining.AP;
  const START_WEEK_CURSOR = 1680566400;
  const REWARD_TOKEN = config.Tokens.ALPACA;
  const EMERGENCY_RETURN = deployer.address;

  console.log(`> Deploying Paradeen Contract`);
  const Paradeen = await ethers.getContractFactory("Paradeen", deployer);
  const paradeen = await upgrades.deployProxy(Paradeen, [
    AP,
    START_WEEK_CURSOR,
    REWARD_TOKEN,
    EMERGENCY_RETURN,
  ]);
  console.log(`> ⛓ Tx submitted: ${paradeen.deployTransaction.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await paradeen.deployed();
  console.log(`> Tx mined!`);
  console.log(`> Deployed at: ${paradeen.address}`);

  config.TradeMining.paradeen = paradeen.address;
  config.TradeMining.rewardToken = REWARD_TOKEN;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly...`);
  const implAddress = await getImplementationAddress(
    ethers.provider,
    paradeen.address
  );
  await tenderly.verify({
    address: implAddress,
    name: "Paradeen",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["Paradeen"];
