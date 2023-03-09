import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { MarketOrderRouter__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const minBlockDelayKeeper = 0;
const minTimeDelayPublic = 180;
const maxTimeDelay = 1800;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = MarketOrderRouter__factory.connect(
    config.Pools.ALP.marketOrderRouter,
    deployer
  );

  console.log(`> Set Delay Values...`);
  const tx = await orderbook.setDelayValues(
    minBlockDelayKeeper, // _minBlockDelayKeeper
    minTimeDelayPublic, // _minTimeDelayPublic
    maxTimeDelay // _maxTimeDelay
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Tx mined!`);
};

export default func;
func.tags = ["SetDelayValues"];
