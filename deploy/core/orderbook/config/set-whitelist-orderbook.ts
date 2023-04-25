import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { Orderbook__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const WHITELIST_ADDRESS = "";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = Orderbook__factory.connect(
    config.Pools.ALP.orderbook,
    deployer
  );

  console.log(`> Set Orderbook's whitelist...`);
  const tx = await orderbook.setWhitelist(WHITELIST_ADDRESS, true);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Tx mined!`);
};

export default func;
func.tags = ["SetWhitelistOrderbook"];
