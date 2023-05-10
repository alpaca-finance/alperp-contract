import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../../../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import {
  AccessControlFacetInterface__factory,
  AdminFacetInterface__factory,
} from "../../../../typechain";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const MarketOrderRouter = await ethers.getContractFactory(
    "MarketOrderRouter",
    deployer
  );

  console.log(`> Deploying MarketOrderRouter Contract`);
  const marketOrderRouter = await upgrades.deployProxy(MarketOrderRouter, [
    config.Pools.ALP.poolDiamond,
    config.Pools.ALP.oracle,
    config.WNativeRelayer,
    config.TradeMining.tradeMiningManager,
    config.Tokens.WBNB,
    30,
    0,
  ]);
  await marketOrderRouter.deployed();
  console.log(`> 🟢 Deployed at: ${marketOrderRouter.address}`);

  config.MarketOrderRouter = marketOrderRouter.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    marketOrderRouter.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "MarketOrderRouter",
  });

  console.log(`> Set deployer as a admin`);
  let tx = await marketOrderRouter.setAdmin(deployer.address);
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for confirmation...`);
  await tx.wait(3);
  console.log(`> 🟢 Done`);

  console.log(`> Approve market order router as a plugin`);
  const accessControlFacet = AccessControlFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  tx = await accessControlFacet.allowPlugin(marketOrderRouter.address);
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for confirmation...`);
  await tx.wait(3);
  console.log(`> 🟢 Done`);
};

export default func;
func.tags = ["MarketOrderRouter_Deploy"];
