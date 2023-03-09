import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, ALPStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const STAKING_CONTRACT_ADDRESS = config.Staking.ALPStaking.address;
const STAKING_TOKEN_ADDRESS = config.Tokens.ALP;
const REWARDERS = ["0xBB376385c8Fc91BAAe141ceaadd725bc81d09a7B"];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const alpStakingContract = ALPStaking__factory.connect(
    STAKING_CONTRACT_ADDRESS,
    deployer
  );
  const newStakingToken = ERC20__factory.connect(
    STAKING_TOKEN_ADDRESS,
    deployer
  );
  const newStakingTokenSymbol = await newStakingToken.symbol();

  console.log(`> Adding ${newStakingTokenSymbol} to staking contract`);
  const tx = await alpStakingContract.addStakingToken(
    STAKING_TOKEN_ADDRESS,
    REWARDERS
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["AddStakingToken"];
