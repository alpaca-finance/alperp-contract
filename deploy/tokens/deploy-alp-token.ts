import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly, network } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();
const LIQUIDITY_COOLDOWN = 60 * 15; // 15 minutes

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const ALP = await ethers.getContractFactory("ALP", deployer);
  const alp = await upgrades.deployProxy(ALP, [LIQUIDITY_COOLDOWN]);
  await alp.deployed();
  console.log(`Deploying ALP Token Contract`);
  console.log(`Deployed at: ${alp.address}`);

  config.Tokens.ALP = alp.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    network.provider,
    alp.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "ALP",
  });
};

export default func;
func.tags = ["ALPToken"];
