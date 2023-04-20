import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../../../utils/config";
import { Orderbook02__factory } from "../../../../typechain";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const newPoolOracle = config.Pools.ALP.oracle02;
  const deployer = (await ethers.getSigners())[0];

  console.log(`> Setting pool oracle on Orderbook02`);
  const orderBook = Orderbook02__factory.connect(
    config.Pools.ALP.orderbook,
    deployer
  );

  const tx = await orderBook.setPoolOracle(newPoolOracle);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait(3);
  console.log(`> 🟢 Tx mined!`);
};

export default func;
func.tags = ["OrderBookSetPoolOracle"];
