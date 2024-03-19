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

  const TARGET_ADDRESS = config.MarketOrderRouter;

  const EXACT_ETA = 0;

  const deployer = (await ethers.getSigners())[0];

  const marketOrderRouter = await ethers.getContractFactory(
    "MarketOrderRouter",
    deployer
  );

  console.log(`> Preparing to upgrade MarketOrderRouter`);
  const newMarketOrderRouter = await upgrades.prepareUpgrade(
    TARGET_ADDRESS,
    marketOrderRouter
  );

  console.log(
    `> New MarketOrderRouter Implementation address: ${newMarketOrderRouter}`
  );
  const proxyAdmin = ProxyAdmin__factory.connect(config.ProxyAdmin, deployer);

  if (!compareAddress(await proxyAdmin.owner(), config.Timelock)) {
    const upgradeTx = await upgrades.upgradeProxy(
      TARGET_ADDRESS,
      marketOrderRouter
    );
    console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await upgradeTx.deployTransaction.wait();

    console.log(`> Tx is mined!`);
  } else {
    const timelock = new MaybeMultisigTimelock(networkInfo.chainId, deployer);

    console.log(`> Queue tx on Timelock to upgrade the implementation`);
    await timelock.queueTransaction(
      `Upgrade MarketOrderRouter`,
      config.ProxyAdmin,
      "0",
      "upgrade(address,address)",
      ["address", "address"],
      [TARGET_ADDRESS, newMarketOrderRouter],
      EXACT_ETA
    );
  }

  console.log("> ✅ Done");
};

export default func;
func.tags = ["UpgradeMarketOrderRouter"];
