import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { IMineable__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const MINEABLE_ADDRESSES = [config.PoolRouter, config.Pools.ALP.orderbook];

  const deployer = (await ethers.getSigners())[0];

  for (let i = 0; i < MINEABLE_ADDRESSES.length; i++) {
    const tradeMiningManager = IMineable__factory.connect(
      MINEABLE_ADDRESSES[i],
      deployer
    );
    console.log(
      `> [${i + 1}/${
        MINEABLE_ADDRESSES.length
      }] Set trade mining manager for ${MINEABLE_ADDRESSES}`
    );
    const tx = await tradeMiningManager.setTradeMiningManager(
      config.TradeMining.tradeMiningManager
    );
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await tx.wait();
    console.log(`> Tx mined!`);
  }

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetMiningManagerMinable"];
