import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MarketOrderRouter__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = MarketOrderRouter__factory.connect(
    config.Pools.ALP.marketOrderRouter,
    deployer
  );

  console.log(`> Set Market Order Router PoolOracle...`);
  const tx = await orderbook.setPoolOracle(config.Pools.ALP.oracle);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Tx mined!`);
};

export default func;
func.tags = ["SetMarketOrderRouterPoolOracle"];
