import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AccessControlFacet__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();
const role = ethers.utils.id("FARM_KEEPER_ROLE");
const grantee = "0xe7385155167882AeC5D4D9273aa5fe7533212B3F";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const accessControlFacet = AccessControlFacet__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  const tx = await accessControlFacet.grantRole(role, grantee);
  const txReceipt = await tx.wait();
  console.log(`Execute grant role ${role} with tx: ${tx.hash}`);
};

export default func;
func.tags = ["AccessControlGrantRole"];
