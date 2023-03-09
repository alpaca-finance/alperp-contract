import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ERC20__factory, ALPStaking__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_ADDRESS = config.Tokens.ALP;
const STAKING_CONTRACT = config.Staking.ALPStaking.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = ERC20__factory.connect(TOKEN_ADDRESS, deployer);
  await (
    await token.approve(STAKING_CONTRACT, ethers.constants.MaxUint256)
  ).wait();
  const stakingContract = ALPStaking__factory.connect(
    STAKING_CONTRACT,
    deployer
  );
  await (
    await stakingContract.deposit(
      deployer.address,
      TOKEN_ADDRESS,
      ethers.utils.parseEther("1")
    )
  ).wait();
  console.log(`Execute deposit`);
};

export default func;
func.tags = ["DepositToken"];
