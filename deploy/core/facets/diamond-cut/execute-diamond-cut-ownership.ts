import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  OwnershipFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const facetCuts = [
  {
    facetAddress: config.Pools.ALP.facets.ownership,
    action: FacetCutAction.Add,
    functionSelectors: [
      OwnershipFacet__factory.createInterface().getSighash("owner()"),
      OwnershipFacet__factory.createInterface().getSighash(
        "transferOwnership(address)"
      ),
    ],
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );

  console.log(`> Diamond cutting ownership facet`);
  const tx = await poolDiamond.diamondCut(
    facetCuts,
    ethers.constants.AddressZero,
    "0x"
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Diamond cut ownership facet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Ownership"];
