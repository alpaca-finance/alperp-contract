import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  DiamondInitializer__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

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
      config.Pools.ALP.facets.diamondInitializer,
      ethers.utils.defaultAbiCoder.encode(
        ["bytes4"],
        [
          DiamondInitializer__factory.createInterface().getSighash(
            "initialize()"
          ),
        ]
      )
    )
  ).wait();

  console.log(`Execute diamondCut for InitializeDiamond`);
};

export default func;
func.tags = ["ExecuteDiamondCut-InitializeDiamond"];
