import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ALPStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import * as readlineSync from "readline-sync";

const config = getConfig();

const STAKING_CONTRACT_ADDRESS = config.Staking.ALPStaking.address;
const STAKING_TOKEN_ADDRESS = config.Tokens.ALP;
const REWARDER_TOKEN_INDEX = 1;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const alpStakingContract = ALPStaking__factory.connect(
    STAKING_CONTRACT_ADDRESS,
    deployer
  );
  const rewarder = await alpStakingContract.stakingTokenRewarders(
    STAKING_TOKEN_ADDRESS,
    REWARDER_TOKEN_INDEX
  );
  console.log(`> REMOVING rewarder ${rewarder} from staking contract`);
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
  const tx = await alpStakingContract.removeRewarderForTokenByIndex(
    REWARDER_TOKEN_INDEX,
    STAKING_TOKEN_ADDRESS
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["RemoveStakingTokenRewarderByIndex"];
