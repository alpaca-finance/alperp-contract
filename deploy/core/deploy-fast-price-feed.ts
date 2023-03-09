import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const priceDuration = 300;
const maxPriceUpdateDelay = 3600;
const minBlockInterval = 1;
const maxDeviationBasisPoints = 500;
const tokenManager = "0xCc4B77A97eBa4734c6D61c189B2B499F93C9710E"; // DEPLOYER
const positionRouter = config.Pools.ALP.marketOrderRouter;
const orderbook = config.Pools.ALP.orderbook;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying FastPriceFeed Contract`);
  const FastPriceFeed = await ethers.getContractFactory(
    "FastPriceFeed",
    deployer
  );
  const fastPriceFeed = await upgrades.deployProxy(FastPriceFeed, [
    priceDuration,
    maxPriceUpdateDelay,
    minBlockInterval,
    maxDeviationBasisPoints,
    tokenManager,
    positionRouter,
    orderbook,
  ]);
  console.log(`> ⛓ Tx submitted: ${fastPriceFeed.deployTransaction.hash}`);
  await fastPriceFeed.deployTransaction.wait();
  console.log(`> Deployed at: ${fastPriceFeed.address}`);

  config.Pools.ALP.fastPriceFeed = fastPriceFeed.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    fastPriceFeed.address
  );

  console.log(`> Verifying contract on Tenderly...`);
  await tenderly.verify({
    address: implAddress,
    name: "FastPriceFeed",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["FastPriceFeed"];
