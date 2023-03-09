import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const FastPriceFeed = await ethers.getContractFactory(
    "FastPriceFeed",
    deployer
  );
  const newFastPriceFeedImp = await upgrades.prepareUpgrade(
    config.Pools.ALP.fastPriceFeed,
    FastPriceFeed
  );
  console.log(
    `> New FastPriceFeed Implementation address: ${newFastPriceFeedImp}`
  );
  const tx = await upgrades.upgradeProxy(
    config.Pools.ALP.fastPriceFeed,
    FastPriceFeed
  );
  await tx.deployed();

  await tenderly.verify({
    address: newFastPriceFeedImp.toString(),
    name: "FastPriceFeed",
  });
};

export default func;
func.tags = ["UpgradeFastPriceFeed"];
