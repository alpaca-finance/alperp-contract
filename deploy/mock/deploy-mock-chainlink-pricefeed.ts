import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { MockChainlinkPriceFeed__factory } from "../../typechain";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const PriceFeedFactory = new MockChainlinkPriceFeed__factory(deployer);
  const priceFeed = await PriceFeedFactory.deploy();
  await priceFeed.deployed();
  console.log(`Deploying a mock Chainlink price feed at ${priceFeed.address}`);

  await tenderly.verify({
    address: priceFeed.address,
    name: "MockChainlinkPriceFeed",
  });
};

export default func;
func.tags = ["MockChainlinkPriceFeed"];
