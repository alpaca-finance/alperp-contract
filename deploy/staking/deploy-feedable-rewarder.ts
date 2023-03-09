import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../utils/config";

const config = getConfig();

// NOTE: NAMES should be matched with config.Staking.ALPStaking.rewarders[].name in `contracts.*.json` file
const NAMES = ["ALP Staking Protocol Revenue"];
const STAKING_CONTRACT_ADDRESS = config.Staking.ALPStaking.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const Rewarder = await ethers.getContractFactory(
    "FeedableRewarder",
    deployer
  );

  for (const name of NAMES) {
    const rewardTokenAddress = getRewardTokenAddress(name);
    console.log(`> Deploying ${name} FeedableRewarder Contract`);
    const feedableRewarderContract = await upgrades.deployProxy(Rewarder, [
      name,
      rewardTokenAddress,
      STAKING_CONTRACT_ADDRESS,
    ]);
    console.log(
      `> ⛓ Tx submitted: ${feedableRewarderContract.deployTransaction.hash}`
    );
    console.log(`> Waiting for tx to be mined...`);
    await feedableRewarderContract.deployTransaction.wait();
    console.log(`> Tx mined!`);
    console.log(`> Deployed at: ${feedableRewarderContract.address}`);

    if (name.includes("ALP")) {
      config.Staking.ALPStaking.rewarders =
        config.Staking.ALPStaking.rewarders.map((each: any) => {
          if (each.name === name) {
            return {
              ...each,
              address: feedableRewarderContract.address,
              rewardToken: rewardTokenAddress,
            };
          } else return each;
        });
    }
    writeConfigFile(config);

    const implAddress = await getImplementationAddress(
      ethers.provider,
      feedableRewarderContract.address
    );

    console.log(`> Verifying contract on Tenderly...`);
    await tenderly.verify({
      address: implAddress,
      name: "FeedableRewarder",
    });
    console.log(`> ✅ Verified!`);
  }
};

function getRewardTokenAddress(rewarderName: string): string {
  if (rewarderName.includes("Protocol Revenue")) {
    return config.Tokens.BUSD;
  } else {
    return config.Tokens.ALPACA;
  }
}

export default func;
func.tags = ["FeedableRewarder"];
