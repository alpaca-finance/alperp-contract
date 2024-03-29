import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../../../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const minExecutionFee = ethers.utils.parseEther("0.01");
const minPurchaseTokenAmountUsd = ethers.utils.parseUnits("10", 30);
const PRICE_UPDATER = config.Pools.ALP.pythPriceFeed;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying Orderbook02 Contract`);
  const Orderbook = await ethers.getContractFactory("Orderbook02", deployer);
  const orderbook = await upgrades.deployProxy(Orderbook, [
    config.Pools.ALP.poolDiamond,
    config.Pools.ALP.oracle,
    config.WNativeRelayer, // _wnativeRelayer
    config.Tokens.WBNB,
    minExecutionFee,
    minPurchaseTokenAmountUsd,
    PRICE_UPDATER,
  ]);
  console.log(`> ⛓ Tx submitted: ${orderbook.deployTransaction.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await orderbook.deployed();
  console.log(`> Tx mined!`);
  console.log(`> Deployed at: ${orderbook.address}`);

  config.Pools.ALP.orderbook = orderbook.address;
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly...`);
  const implAddress = await getImplementationAddress(
    ethers.provider,
    orderbook.address
  );
  await tenderly.verify({
    address: implAddress,
    name: "Orderbook02",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["Orderbook02"];
