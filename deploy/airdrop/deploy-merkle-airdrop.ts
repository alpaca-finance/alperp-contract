import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const MerkleAirdrop = await ethers.getContractFactory(
    "MerkleAirdrop",
    deployer
  );
  console.log(`> Deploying MerkleAirdrop Contract`);
  const merkleAirdrop = await MerkleAirdrop.deploy(
    config.Tokens.USDC,
    deployer.address // TODO: change feeder here
  );
  console.log(`> ⛓ Tx submitted: ${merkleAirdrop.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await merkleAirdrop.deployTransaction.wait();
  console.log(`> Deployed at: ${merkleAirdrop.address}`);

  config.MerkleAirdrop.address = merkleAirdrop.address;
  config.MerkleAirdrop.deployedAtBlock = String(
    await ethers.provider.getBlockNumber()
  );
  writeConfigFile(config);

  console.log(`> Verifying contract on Tenderly`);
  await tenderly.verify({
    address: merkleAirdrop.address,
    name: "MerkleAirdrop",
  });
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["MerkleAirdrop"];
