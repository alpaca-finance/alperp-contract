import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig, writeConfigFile } from "../../../utils/config";

const config = getConfig();

const PYTH = config.ThirdParty.Oracle.Pyth.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying PythPriceFeed Contract`);
  const PythPriceFeed = await ethers.getContractFactory(
    "PythPriceFeed",
    deployer
  );
  const pythPriceFeed = await upgrades.deployProxy(PythPriceFeed, [PYTH]);
  console.log(`> ⛓ Tx submitted: ${pythPriceFeed.deployTransaction.hash}`);
  await pythPriceFeed.deployTransaction.wait();
  console.log(`> Deployed at: ${pythPriceFeed.address}`);

  config.Pools.ALP.pythPriceFeed = pythPriceFeed.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    pythPriceFeed.address
  );

  console.log(`> Verifying contract on Tenderly...`);
  await tenderly.verify({
    address: implAddress,
    name: "PythPriceFeed",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["PythPriceFeed"];
