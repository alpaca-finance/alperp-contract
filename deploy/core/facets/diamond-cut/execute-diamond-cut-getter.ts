import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  GetterFacet__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const methods = ["convertUsde30ToTokens(address,uint256,bool)"];

const facetCuts = [
  {
    facetAddress: config.Pools.ALP.facets.getter,
    action: FacetCutAction.Add,
    functionSelectors: methods.map((each) => {
      return GetterFacet__factory.createInterface().getSighash(each);
    }),
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );

  console.log(`> Diamond cutting getter facet`);
  const tx = await poolDiamond.diamondCut(
    facetCuts,
    ethers.constants.AddressZero,
    "0x"
  );
  console.log(`> ⛓ Tx hash: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Getter"];
