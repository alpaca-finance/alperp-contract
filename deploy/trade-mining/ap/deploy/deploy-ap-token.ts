import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly, network } from "hardhat";
import { getConfig, writeConfigFile } from "../../../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const deployer = (await ethers.getSigners())[0];
  const AP = await ethers.getContractFactory("AP", deployer);
  const ap = await upgrades.deployProxy(AP);

  console.log(`> ⛓ Tx submitted: ${ap.deployTransaction.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await ap.deployed();
  console.log(`Deploying AP Token Contract`);
  console.log(`Deployed at: ${ap.address}`);

  config.TradeMining.AP = ap.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    network.provider,
    ap.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "AP",
  });
};

export default func;
func.tags = ["APToken"];
