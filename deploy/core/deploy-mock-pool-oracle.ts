import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const MockPoolOracle = await ethers.getContractFactory(
    "MockPoolOracle",
    deployer
  );
  const mockPoolOracle = await MockPoolOracle.deploy();
  await mockPoolOracle.deployed();
  console.log(`Deploying MockPoolOracle Contract`);
  console.log(`Deployed at: ${mockPoolOracle.address}`);

  config.Pools.ALP.oracle = mockPoolOracle.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: mockPoolOracle.address,
    name: "MockPoolOracle",
  });
};

export default func;
func.tags = ["MockPoolOracle"];
