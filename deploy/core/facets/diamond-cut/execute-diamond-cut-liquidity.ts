import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  DiamondCutFacet__factory,
  LiquidityFacetInterface__factory,
} from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

enum FacetCutAction {
  Add,
  Replace,
  Remove,
}

const methods = [
  "addLiquidity(address,address,address)",
  "flashLoan(address,address[],address[],uint256[],bytes)",
  "removeLiquidity(address,address,address)",
  "swap(address,address,address,uint256,address)",
];

const facetCuts = [
  {
    facetAddress: config.Pools.ALP.facets.liquidity,
    action: FacetCutAction.Add,
    functionSelectors: methods.map((each) => {
      return LiquidityFacetInterface__factory.createInterface().getSighash(
        each
      );
    }),
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];

  const poolDiamond = DiamondCutFacet__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );

  console.log(`> Diamond cutting liquidity facet`);
  const tx = await poolDiamond.diamondCut(
    facetCuts,
    ethers.constants.AddressZero,
    "0x"
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Diamond cut liquidity facet`);
};

export default func;
func.tags = ["ExecuteDiamondCut-Liquidity"];
