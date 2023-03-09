import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Orderbook = await ethers.getContractFactory(
    "MarketOrderRouter",
    deployer
  );
  const newOrderbookImp = await upgrades.prepareUpgrade(
    config.Pools.ALP.marketOrderRouter,
    Orderbook
  );
  console.log(
    `> New MarketOrderRouter Implementation address: ${newOrderbookImp}`
  );
  await upgrades.upgradeProxy(config.Pools.ALP.marketOrderRouter, Orderbook);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    config.Pools.ALP.marketOrderRouter
  );

  await tenderly.verify({
    address: implAddress,
    name: "MarketOrderRouter",
  });
};

export default func;
func.tags = ["UpgradeMarketOrderRouter"];
