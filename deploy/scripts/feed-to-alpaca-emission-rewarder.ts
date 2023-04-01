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
const AMOUNT = "10000";
const EXPIRED_AT = "1680775200";

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
  const symbol = await token.symbol();
  const decimals = await token.decimals();
  const allowance = await token.allowance(deployer.address, REWARDER.address);

  console.log(
    `> Feeding ${AMOUNT} to ${
      REWARDER.address
    } ${await token.symbol()} which will be expired at ${EXPIRED_AT}`
  );

  console.log(`> Checking allowance...`);
  if (allowance.eq(0)) {
    console.log(`> Allowance not set`);
    console.log(`> Approving ${REWARDER.address} to spend ${symbol}`);
    await (
      await token.approve(REWARDER.address, ethers.constants.MaxUint256)
    ).wait();
  }
  console.log(`> ✅ Done`);

  const tx = await rewarder.feedWithExpiredAt(
    ethers.utils.parseUnits(AMOUNT, decimals),
    EXPIRED_AT,
    { gasLimit: 10000000 }
  );
  console.log(`> Tx is submitted: ${tx.hash}`);

  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["FeedALPACAEmissionRewarder"];
