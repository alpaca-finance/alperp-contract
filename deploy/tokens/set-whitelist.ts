import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ALP__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const WHITELIST_ADDRESSES = [
  config.Staking.ALPStaking.address,
  config.PoolRouter,
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = ALP__factory.connect(config.Tokens.ALP, deployer);
  for (let i = 0; i < WHITELIST_ADDRESSES.length; i++) {
    console.log(
      `> Adding ${WHITELIST_ADDRESSES[i]} [${i + 1}/${
        WHITELIST_ADDRESSES.length
      }] to ALP's whitelist`
    );
    const tx = await token.setWhitelist(WHITELIST_ADDRESSES[i], true);
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await tx.wait();
    console.log(`> Tx is mined`);
  }
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["SetALPWhitelist"];
