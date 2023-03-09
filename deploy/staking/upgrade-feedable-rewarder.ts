import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getConfig } from "../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

const config = getConfig();

const TARGET_ADDRESS = ""; // TODO: target address

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const FeedableRewarder = await ethers.getContractFactory(
    "FeedableRewarder",
    deployer
  );

  console.log(`> Preparing to upgrade FeedableRewarder`);
  const newFeedableRewarder = await upgrades.prepareUpgrade(
    config.Staking.ALPStaking.rewarders[0].address,
    FeedableRewarder
  );
  console.log(`> Done`);

  console.log(
    `> New FeedableRewarder Implementation address: ${newFeedableRewarder}`
  );
  const upgradeTx = await upgrades.upgradeProxy(
    TARGET_ADDRESS,
    FeedableRewarder
  );
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait();
  console.log(`> Tx is mined!`);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    config.Staking.RewardDistributor.address
  );

  console.log(`> Verify contract on Tenderly`);
  await tenderly.verify({
    address: implAddress,
    name: "FeedableRewarder",
  });
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["UpgradeFeedableRewarder"];
