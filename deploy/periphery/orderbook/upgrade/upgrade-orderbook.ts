import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";
import { getConfig } from "../../../utils/config";
import { MaybeMultisigTimelock } from "../../../utils/maybe-multisig";
import { ProxyAdmin__factory } from "../../../../typechain";
import { compareAddress } from "../../../utils/address";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const networkInfo = await ethers.provider.getNetwork();

  const TARGET_ADDRESS = config.Pools.ALP.orderbook;

  const EXACT_ETA = 0;

  const deployer = (await ethers.getSigners())[0];

  const Orderbook02 = await ethers.getContractFactory("Orderbook02", deployer);

  console.log(`> Preparing to upgrade Orderbook02`);
  const newOrderbook02 = await upgrades.prepareUpgrade(
    TARGET_ADDRESS,
    Orderbook02
  );

  console.log(`> New Orderbook02 Implementation address: ${newOrderbook02}`);
  const proxyAdmin = ProxyAdmin__factory.connect(config.ProxyAdmin, deployer);

  if (!compareAddress(await proxyAdmin.owner(), config.Timelock)) {
    const upgradeTx = await upgrades.upgradeProxy(TARGET_ADDRESS, Orderbook02);
    console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await upgradeTx.deployTransaction.wait();

    console.log(`> Tx is mined!`);
  } else {
    const timelock = new MaybeMultisigTimelock(networkInfo.chainId, deployer);

    console.log(`> Queue tx on Timelock to upgrade the implementation`);
    await timelock.queueTransaction(
      `Upgrade Orderbook02`,
      config.ProxyAdmin,
      "0",
      "upgrade(address,address)",
      ["address", "address"],
      [TARGET_ADDRESS, newOrderbook02],
      EXACT_ETA
    );
  }

  console.log("> ✅ Done");
};

export default func;
func.tags = ["UpgradeOrderBook"];
