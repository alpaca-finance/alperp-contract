import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { FeedableRewarder__factory } from "../../typechain";

const FEEDER: string = "0x091f7A0a84F12d188EC92C070464D387714B6a92";
const REWARDERS: string[] = ["0x2D4DdBb76CBb2aFf2553A5B4017318fd87586fA4"];

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
