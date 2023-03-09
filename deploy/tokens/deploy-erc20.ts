import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, network } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const name = "Binance-Peg Dai Token";
const symbol = "DAI";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const ERC20 = await ethers.getContractFactory("MockErc20", deployer);
  const erc20 = await ERC20.deploy(name, symbol, 18);
  await erc20.deployed();
  console.log(`Deploying ERC20 ${name} Token (${symbol}) Contract`);
  console.log(`Deployed at: ${erc20.address}`);

  config.Tokens[symbol] = erc20.address;
  writeConfigFile(config);

  await tenderly.verify({
    address: erc20.address,
    name: "MockERC20",
  });
};

export default func;
func.tags = ["ERC20"];
