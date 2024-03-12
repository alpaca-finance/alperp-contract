import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../utils/config";
import { BigNumber } from "ethers";
import { Paradeen__factory } from "../../typechain";
import * as readlineSync from "readline-sync";

interface FeedParadeenParams {
  weekTimstamp: BigNumber;
  amount: BigNumber;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const PARADEEN_ADDRESS = "";
  const PARAMS_INPUT: Array<FeedParadeenParams> = [
    {
      weekTimstamp: BigNumber.from(1710349200),
      amount: ethers.utils.parseUnits("20000", 6),
    }
  ];

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

  const WEEK = BigNumber.from(604800);
  const timestamps = PARAMS_INPUT.map((p) =>
    p.weekTimstamp.div(WEEK).mul(WEEK)
  );
  const amounts = PARAMS_INPUT.map((p) => p.amount);
  const signer = (await ethers.getSigners())[0];

  const paradeen = Paradeen__factory.connect(
    PARADEEN_ADDRESS,
    signer
  );

  console.log("> Feeding rewards to Paradeen");
  console.log(`Feeding ${timestamps} , ${amounts}`);
  // const tx = await paradeen.feed(timestamps, amounts);
  // console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting tx to be mined...`);
  // await tx.wait();
  console.log(`> Tx mined!`);
};

export default func;
func.tags = ["FeedParadeen"];
