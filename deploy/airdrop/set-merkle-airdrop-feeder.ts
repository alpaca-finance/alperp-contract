import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MerkleAirdrop__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const FEEDER: string = config.Staking.RewardDistributor.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const rewarder = MerkleAirdrop__factory.connect(
    config.MerkleAirdrop.address,
    deployer
  );
  console.log(`> Setting merkle airdrop feeder to ${FEEDER}`);
  const tx = await rewarder.setFeeder(FEEDER);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> Tx is mined`);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetMerkleAirdropFeeder"];
