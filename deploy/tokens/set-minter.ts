import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  MintableTokenInterface__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.ALP;
const MINTER_ADDRESSES = [config.Pools.ALP.poolDiamond];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const mintableToken = MintableTokenInterface__factory.connect(
    TOKEN_ADDRESS,
    deployer
  );
  const erc20 = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  const tokenSymbol = await erc20.symbol();

  for (let i = 0; i < MINTER_ADDRESSES.length; i++) {
    console.log(
      `> Setting minter [${i + 1}/${
        MINTER_ADDRESSES.length
      }] for ${tokenSymbol}: ${MINTER_ADDRESSES[i]}`
    );
    const tx = await mintableToken.setMinter(MINTER_ADDRESSES[i], true);
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await tx.wait();
    console.log(`> Tx mined!`);
  }

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetMinter"];
