import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const WNativeRelayer = await ethers.getContractFactory(
    "WNativeRelayer",
    deployer
  );

  console.log(`> Deploying WNativeRelayer Contract`);
  const wnativeRelayer = await WNativeRelayer.deploy(config.Tokens.WBNB);
  console.log(`> ⛓ Tx summited: ${wnativeRelayer.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await wnativeRelayer.deployed();
  console.log(`> Tx mined!`);
  console.log(`> ✅ Deployed at: ${wnativeRelayer.address}`);

  config.WNativeRelayer = wnativeRelayer.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly`);
  await tenderly.verify({
    address: wnativeRelayer.address,
    name: "WNativeRelayer",
  });
  console.log(`> ✅ Verified on Tenderly`);
};

export default func;
func.tags = ["WNativeRelayer"];
