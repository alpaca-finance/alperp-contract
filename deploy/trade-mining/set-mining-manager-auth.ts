import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { TradeMiningManager__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const WHITELIST_ADDRESSES = [config.PoolRouter, config.Pools.ALP.orderbook];

  const deployer = (await ethers.getSigners())[0];
  const tradeMiningManager = TradeMiningManager__factory.connect(
    config.TradeMining.tradeMiningManager,
    deployer
  );

  for (let i = 0; i < WHITELIST_ADDRESSES.length; i++) {
    console.log(
      `> Setting whitelist [${i + 1}/${
        WHITELIST_ADDRESSES.length
      }] for miner: ${WHITELIST_ADDRESSES[i]}`
    );
    const tx = await tradeMiningManager.setAuth(WHITELIST_ADDRESSES[i], true);
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await tx.wait();
    console.log(`> Tx mined!`);
  }

  console.log(`> ✅ Done!`);
};

export default func;
func.tags = ["SetMiningManagerAuth"];
