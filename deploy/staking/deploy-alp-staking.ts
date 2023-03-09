import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying ALPStaking Contract`);
  const alpStakingContractFactory = await ethers.getContractFactory(
    "ALPStaking",
    deployer
  );
  const alpStakingContract = await upgrades.deployProxy(
    alpStakingContractFactory,
    []
  );

  console.log(`> ⛓ Tx submitted: ${alpStakingContract.deployTransaction.hash}`);
  await alpStakingContract.deployTransaction.wait();
  console.log(`> Deployed at: ${alpStakingContract.address}`);

  config.Staking.ALPStaking.address = alpStakingContract.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    alpStakingContract.address
  );

  console.log(`> Verifying contract on Tenderly...`);
  await tenderly.verify({
    address: implAddress,
    name: "ALPStaking",
  });
  console.log(`> ✅ Verified!`);
};

export default func;
func.tags = ["ALPStaking"];
