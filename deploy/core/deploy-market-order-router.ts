import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const minExecutionFee = ethers.utils.parseEther("0.0055");
const depositFeeBps = ethers.BigNumber.from(30); // 0.3%

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying MarketOrderRouter Contract`);
  const MarketOrderRouter = await ethers.getContractFactory(
    "MarketOrderRouter",
    deployer
  );

  const orderbook = await upgrades.deployProxy(MarketOrderRouter, [
    config.Pools.ALP.poolDiamond, // _pool
    config.Pools.ALP.oracle, // _poolOracle
    config.WNativeRelayer, // _wnativeRelayer
    config.Tokens.WBNB, // _wnative
    depositFeeBps, // _depositFeeBps
    minExecutionFee, // _minExecutionFee
  ]);
  console.log(`> ⛓ Tx submitted: ${orderbook.deployTransaction.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await orderbook.deployTransaction.wait();
  console.log(`> Tx mined!`);
  console.log(`> Deployed at: ${orderbook.address}`);

  config.Pools.ALP.marketOrderRouter = orderbook.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly...`);
  const implAddress = await getImplementationAddress(
    ethers.provider,
    orderbook.address
  );
  await tenderly.verify({
    address: implAddress,
    name: "MarketOrderRouter",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["MarketOrderRouter"];
