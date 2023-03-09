import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { RewardDistributor__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const FEEDER: string = "";
  const rewarder = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );
  console.log(`> Setting reward distributor feeder to ${FEEDER}`);
  const tx = await rewarder.setFeeder(FEEDER);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> Tx is mined`);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetRewardDistributorFeeder"];
