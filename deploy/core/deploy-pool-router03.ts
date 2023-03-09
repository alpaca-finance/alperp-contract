import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const WNATIVE = config.Tokens.WBNB;
const POOL_DIAMOND = config.Pools.ALP.poolDiamond;
const PRICE_UPDATER = config.Pools.ALP.pythPriceFeed;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const PoolRouter = await ethers.getContractFactory("PoolRouter03", deployer);

  console.log(`> Deploying PoolRouter03 Contract`);
  const poolRouter = await PoolRouter.deploy(
    WNATIVE,
    POOL_DIAMOND,
    PRICE_UPDATER
  );
  console.log(`> ⛓ Tx summited: ${poolRouter.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await poolRouter.deployed();
  console.log(`> Tx mined!`);
  console.log(`> ✅ Deployed at: ${poolRouter.address}`);

  config.PoolRouter = poolRouter.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly`);
  await tenderly.verify({
    address: poolRouter.address,
    name: "PoolRouter03",
  });
  console.log(`> ✅ Verified on Tenderly`);
};

export default func;
func.tags = ["PoolRouter03"];
