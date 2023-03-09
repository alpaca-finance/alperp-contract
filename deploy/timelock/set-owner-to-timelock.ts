import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { Ownable__factory } from "../../typechain";

const config = getConfig();
const contracts: string[] = [
  config.Tokens.ALP,
  config.Pools.ALP.oracle,
  config.Pools.ALP.orderbook,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  for (let i = 0; i < contracts.length; i++) {
    const contract = Ownable__factory.connect(contracts[i], deployer);
    await (await contract.transferOwnership(config.TimelockController)).wait();
    console.log(`Transfer ownership of ${contracts[i]} to TimelockController`);
  }
};

export default func;
func.tags = ["SetOwnerToTimelock"];
