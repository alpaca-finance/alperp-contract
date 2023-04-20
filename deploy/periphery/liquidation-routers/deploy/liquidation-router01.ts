import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig, writeConfigFile } from "../../../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig()

  const POOL = config.Pools.ALP.poolDiamond;
  const PYTH_PRICE_ID = config.Pools.ALP.pythPriceFeed;

  const deployer = (await ethers.getSigners())[0];

  console.log(`> Deploying LiquidationRouter01 Contract`);
  const LiquidationRouter01 = await ethers.getContractFactory(
    "LiquidationRouter01",
    deployer
  );
  const liquidationRouter01 = await upgrades.deployProxy(LiquidationRouter01, [
    POOL,
    PYTH_PRICE_ID
  ]);
  console.log(`> ⛓ Tx submitted: ${liquidationRouter01.deployTransaction.hash}`);
  await liquidationRouter01.deployTransaction.wait(3);
  console.log(`> Deployed at: ${liquidationRouter01.address}`);

  config.LiquidationRouter = liquidationRouter01.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    liquidationRouter01.address
  );

  console.log(`> Verifying contract on Tenderly...`);
  await tenderly.verify({
    address: implAddress,
    name: "LiquidationRouter01",
  });
  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["DeployLiquidationRouter01"];
