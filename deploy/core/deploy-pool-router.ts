import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const WNATIVE = config.Tokens.WBNB;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolRouter = await ethers.getContractFactory("PoolRouter", deployer);

  console.log(`Deploying PoolRouter Contract`);
  const poolRouter = await PoolRouter.deploy(
    WBNB,
    config.Pools.ALP.poolDiamond
  );
  await poolRouter.deployed();
  console.log(`Deployed at: ${poolRouter.address}`);

  config.PoolRouter = poolRouter.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: poolRouter.address,
    name: "PoolRouter",
  });
};

export default func;
func.tags = ["PoolRouter"];
