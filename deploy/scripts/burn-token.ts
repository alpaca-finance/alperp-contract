import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MintableTokenInterface__factory } from "../../typechain";

const TOKEN_ADDRESS = "";
const MINT_TO = "";
const AMOUNT = "";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const token = MintableTokenInterface__factory.connect(
    TOKEN_ADDRESS,
    deployer
  );
  const tx = await token.burn(MINT_TO, ethers.utils.parseEther(AMOUNT));
  const txReceipt = await tx.wait();
  console.log(`Execute burn`);
  console.log(`Token: ${TOKEN_ADDRESS}`);
  console.log(`Burn from: ${MINT_TO}`);
};

export default func;
func.tags = ["BurnToken"];
