import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../../../utils/config";
import { upgrade } from "../../../utils/upgradeable";
import { RewardDistributor__factory } from "../../../../typechain";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const rewardDistributor = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );
  console.log(`> Set pyth price feed`);
  const tx = await rewardDistributor.setPythPriceFeed(
    config.Pools.ALP.pythPriceFeed
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> 🟢 Done`);
};

export default func;
func.tags = ["RewardDistributor_SetPythPriceFeed"];
