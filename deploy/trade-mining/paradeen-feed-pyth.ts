import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../utils/config";
import { BigNumber } from "ethers";
import { AP__factory, Paradeen__factory } from "../../typechain";
import * as readlineSync from "readline-sync";
import { getCoinGeckoPriceUSD } from "../utils/price";
import { formatEther } from "ethers/lib/utils";

interface FeedParadeenParams {
  weekTimestamp: BigNumber;
  amount: BigNumber;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const signer = (await ethers.getSigners())[0];
  const pythExponent = BigNumber.from(10).pow(6);

  // contracts
  const ap = AP__factory.connect(config.TradeMining.AP, ethers.provider);
  const paradeen = Paradeen__factory.connect(
    config.TradeMining.pythParadeen,
    signer
  );

  // constants
  const E18 = BigNumber.from(10).pow(18);
  const WEEK = BigNumber.from(604800);
  const MAX_BPS = BigNumber.from(10000);

  // configs
  const tradingFeeBps = 9;
  const weeklyFeeThreshold = BigNumber.from(20000).mul(E18);

  console.log(`> Prepare data...`);

  const currentBlock = await ethers.provider.getBlock("latest");
  const weekCursor = BigNumber.from(currentBlock.timestamp).div(WEEK).mul(WEEK);

  const weeklyTradingVolume = await ap.weeklyTotalSupply(weekCursor);
  const tradingFeeCollected = weeklyTradingVolume
    .mul(tradingFeeBps)
    .mul(2) // account closing volume assure
    .div(MAX_BPS);
  const pythPrice = await getCoinGeckoPriceUSD("pyth-network");

  console.log(`> Weekly trading volume: ${formatEther(weeklyTradingVolume)}`);
  console.log(`> Trading fee collected: ${formatEther(tradingFeeCollected)}`);
  console.log(`> Pyth price: ${formatEther(pythPrice)}\n`);

  let amountToFeed: BigNumber;

  if (tradingFeeCollected.lt(weeklyFeeThreshold)) {
    console.log(
      `> Trading fee collected is < ${formatEther(weeklyFeeThreshold)} USD`
    );
    amountToFeed = tradingFeeCollected.mul(E18).div(pythPrice);
  } else {
    console.log(
      `> Trading fee collected is > ${formatEther(weeklyFeeThreshold)} USD`
    );
    amountToFeed = weeklyFeeThreshold.mul(E18).div(pythPrice);
  }

  console.log(`> Amount to feed: ${formatEther(amountToFeed)} Pyth`);

  const PARAMS_INPUT: Array<FeedParadeenParams> = [
    {
      weekTimestamp: weekCursor,
      amount: amountToFeed.mul(pythExponent).div(E18),
    },
  ];

  // Check feed timestamp
  const weeklyReward = await paradeen.tokensPerWeek(weekCursor);
  if (weeklyReward.gt(0)) {
    console.log(
      `> Weekly reward for ${weekCursor}: ${formatEther(weeklyReward)}`
    );
    console.log(`> Already fed for this week`);
    const goNext = readlineSync.question("Confirm to re-feed? (y/n): ");
    switch (goNext.toLowerCase()) {
      case "y":
        break;
      case "n":
        console.log("Aborting");
        return;
      default:
        console.log("Invalid input");
        return;
    }
  }

  // Ask for confirmation
  console.table(PARAMS_INPUT);
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

  const timestamps = PARAMS_INPUT.map((p) =>
    p.weekTimestamp.div(WEEK).mul(WEEK)
  );
  const amounts = PARAMS_INPUT.map((p) => p.amount);

  console.log("> Feeding rewards to Paradeen");
  const tx = await paradeen.feed(timestamps, amounts);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting tx to be mined...`);
  await tx.wait();
  console.log(`> Tx mined!`);
};

export default func;
func.tags = ["FeedParadeenPyth"];
