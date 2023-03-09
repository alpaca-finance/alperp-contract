import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  AccessControlInitializer__factory,
  DiamondCutFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();
const ADMIN = "0xCc4B77A97eBa4734c6D61c189B2B499F93C9710E";

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );

  await (
    await poolDiamond.diamondCut(
      [],
      config.Pools.ALP.facets.accessControlInitializer,
      AccessControlInitializer__factory.createInterface().encodeFunctionData(
        "initialize",
        [ADMIN]
      )
    )
  ).wait();

  console.log(`Execute diamondCut for InitializeAccessControl`);
};

export default func;
func.tags = ["ExecuteDiamondCut-InitializeAccessControl"];
