import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, FeedableRewarder__factory } from "../../typechain";
import { BigNumber } from "ethers";
import { getConfig } from "../utils/config";

const config = getConfig();

const REWARDER = config.Staking.ALPStaking.rewarders.find(
  (each: any) => each.name === "ALP Staking ALPACA Emission"
);
const AMOUNT = "69000";
const DURATION = "1209600"; // 2 weeks in seconds

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  if (!REWARDER) {
    console.error(`Not found reward config`);
    return;
  }
  const deployer = (await ethers.getSigners())[0];
  const rewarder = FeedableRewarder__factory.connect(
    REWARDER.address,
    deployer
  );
  const token = ERC20__factory.connect(REWARDER.rewardToken, deployer);
  const decimals = await token.decimals();
  await (
    await token.approve(REWARDER.address, ethers.constants.MaxUint256)
  ).wait();
  const tx = await rewarder.feed(
    ethers.utils.parseUnits(AMOUNT, decimals),
    BigNumber.from(DURATION),
    { gasLimit: 10000000 }
  );
  const txReceipt = await tx.wait();
  console.log(`Fed Rewarder: ${REWARDER.address}`);
  console.log(`> Executed at: ${txReceipt.transactionHash}`);
  console.log(`> ✅ Executed FeedALPACAEmissionRewarder`);
};

export default func;
func.tags = ["FeedALPACAEmissionRewarder"];
