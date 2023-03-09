import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FeedableRewarder__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const FEEDER: string = "";
const REWARDERS: string[] = [
  (
    config.Staking.ALPStaking.rewarders.find(
      (o) => o.name === "ALP Staking Protocol Revenue"
    ) as any
  ).address,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  for (const [index, REWARDER] of Object.entries(REWARDERS)) {
    const rewarder = FeedableRewarder__factory.connect(REWARDER, deployer);
    console.log(
      `> [${index + 1}/${
        REWARDERS.length
      }] Setting feeder on ${REWARDER} to ${FEEDER}`
    );
    const tx = await rewarder.setFeeder(FEEDER);
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await tx.wait();
    console.log(`> Tx is mined`);
  }
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetFeedableRewarderFeeder"];
