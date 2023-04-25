import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AP__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const TOKEN_ADDRESS = config.Tokens.AP;
  const REWARD_TOKEN_ADDRESSES = [config.Tokens.USDT];

  const deployer = (await ethers.getSigners())[0];
  const ap = AP__factory.connect(TOKEN_ADDRESS, deployer);
  const tokenSymbol = await ap.symbol();

  for (let i = 0; i < REWARD_TOKEN_ADDRESSES.length; i++) {
    console.log(
      `> Setting reward token [${i + 1}/${
        REWARD_TOKEN_ADDRESSES.length
      }] for ${tokenSymbol}: ${REWARD_TOKEN_ADDRESSES[i]}`
    );
    const tx = await ap.setRewardToken(REWARD_TOKEN_ADDRESSES[i], true);
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await tx.wait();
    console.log(`> Tx mined!`);
  }

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetAPRewardToken"];
