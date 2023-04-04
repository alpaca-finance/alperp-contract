import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const W_NATIVE = config.Tokens.WBNB;
  const POOL = config.Pools.ALP.poolDiamond;
  const ORACLE_PRICE_UPDATER = config.Pools.ALP.pythPriceFeed;
  const TRADE_MINING_MANAGER = config.TradeMining.address;

  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying PoolRouter04 Contract`);
  const PoolRouter = await ethers.getContractFactory("PoolRouter04", deployer);
  const poolRouter = await upgrades.deployProxy(PoolRouter, [
    W_NATIVE,
    POOL,
    ORACLE_PRICE_UPDATER,
    TRADE_MINING_MANAGER,
  ]);
  console.log(`> ⛓ Tx submitted: ${poolRouter.deployTransaction.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await poolRouter.deployed();
  console.log(`> Tx mined!`);
  console.log(`> Deployed at: ${poolRouter.address}`);

  config.PoolRouter = poolRouter.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly...`);
  const implAddress = await getImplementationAddress(
    ethers.provider,
    poolRouter.address
  );
  await tenderly.verify({
    address: implAddress,
    name: "PoolRouter04",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["PoolRouter04"];
