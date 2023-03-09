import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { RewardDistributor__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import * as readlineSync from "readline-sync";

interface RewardDistributorSetParamsArgs {
  rewardToken?: string;
  pool?: string;
  poolRouter?: string;
  alpStakingProtocolRevenue?: string;
  alpStakingBps?: string;
  devFundAddress?: string;
  devFundBps?: string;
  govFeederAddress?: string;
  govBps?: string;
  burner?: string;
  merkleAirdrop?: string;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const rewardDistributor = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );

  const args: RewardDistributorSetParamsArgs = {
    alpStakingProtocolRevenue: (
      config.Staking.ALPStaking.rewarders.find(
        (o) => o.name === "ALP Staking Protocol Revenue"
      ) as any
    ).address,
  };

  const [
    prevRewardToken,
    prevPool,
    prevPoolRouter,
    prevAlpStakingProtocolRevenue,
    prevAlpStakingBps,
    prevDevFundAddress,
    prevDevFundBps,
    prevGovFeederAddress,
    prevGovBps,
    prevBurner,
    prevMerkleAirdrop,
  ] = await Promise.all([
    await rewardDistributor.rewardToken(),
    await rewardDistributor.pool(),
    await rewardDistributor.poolRouter(),
    await rewardDistributor.alpStakingProtocolRevenueRewarder(),
    await rewardDistributor.alpStakingBps(),
    await rewardDistributor.devFundAddress(),
    await rewardDistributor.devFundBps(),
    await rewardDistributor.govFeeder(),
    await rewardDistributor.govBps(),
    await rewardDistributor.burner(),
    await rewardDistributor.merkleAirdrop(),
  ]);

  console.log(`> Setting reward distributor params`);
  console.table({
    prevRewardToken: (args.rewardToken || prevRewardToken).toString(),
    prevPool: (args.pool || prevPool).toString(),
    prevPoolRouter: (args.poolRouter || prevPoolRouter).toString(),
    prevAlpStakingProtocolRevenue: (
      args.alpStakingProtocolRevenue || prevAlpStakingProtocolRevenue
    ).toString(),
    prevAlpStakingBps: (args.alpStakingBps || prevAlpStakingBps).toString(),
    prevDevFundAddress: (args.devFundAddress || prevDevFundAddress).toString(),
    prevDevFundBps: (args.devFundBps || prevDevFundBps).toString(),
    prevGovFeederAddress: (
      args.govFeederAddress || prevGovFeederAddress
    ).toString(),
    prevGovBps: (args.govBps || prevGovBps).toString(),
    prevBurner: (args.burner || prevBurner).toString(),
    prevMerkleAirdrop: (args.merkleAirdrop || prevMerkleAirdrop).toString(),
  });
  const confirm = readlineSync.question("Confirm? (y/n): ");
  switch (confirm.toLowerCase()) {
    case "y":
      break;
    case "n":
      console.log("Aborting");
      return;
    default:
      console.log("Invalid input");
      return;
  }
  const tx = await rewardDistributor.setParams(
    args.rewardToken || prevRewardToken,
    args.pool || prevPool,
    args.poolRouter || prevPoolRouter,
    args.alpStakingProtocolRevenue || prevAlpStakingProtocolRevenue,
    args.alpStakingBps || prevAlpStakingBps,
    args.devFundAddress || prevDevFundAddress,
    args.devFundBps || prevDevFundBps,
    args.govFeederAddress || prevGovFeederAddress,
    args.govBps || prevGovBps,
    args.burner || prevBurner,
    args.merkleAirdrop || prevMerkleAirdrop
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> Tx is mined`);
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetRewardDistributorParams"];
