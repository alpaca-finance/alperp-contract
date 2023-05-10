import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, tenderly, upgrades } from "hardhat";
import { getConfig, writeConfigFile } from "../../../utils/config";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import {
  MarketOrderRouter__factory,
  PythPriceFeed__factory,
  TradeMiningManager__factory,
} from "../../../../typechain";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const MarketOrderExecutor = await ethers.getContractFactory(
    "MarketOrderExecutor",
    deployer
  );

  console.log(`> Deploying MarketOrderExecutor Contract`);
  const marketOrderExecutor = await upgrades.deployProxy(MarketOrderExecutor, [
    config.Pools.ALP.pythPriceFeed,
    config.MarketOrderRouter,
  ]);
  console.log(
    `> Tx is submitted: ${marketOrderExecutor.deployTransaction.hash}`
  );
  console.log(`> Waiting for confirmation...`);
  await marketOrderExecutor.deployTransaction.wait(3);
  console.log(`> 🟢 Deployed at: ${marketOrderExecutor.address}`);

  config.MarketOrderExecutor = marketOrderExecutor.address;
  writeConfigFile(config);

  const implAddress = await getImplementationAddress(
    ethers.provider,
    marketOrderExecutor.address
  );

  await tenderly.verify({
    address: implAddress,
    name: "MarketOrderExecutor",
  });

  console.log(`> Authorizing MarketOrderExecutor as a PositionKeeper`);
  const marketOrderRouter = MarketOrderRouter__factory.connect(
    config.MarketOrderRouter,
    deployer
  );
  let tx = await marketOrderRouter.setPositionKeeper(
    marketOrderExecutor.address,
    true
  );
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for confirmation...`);
  await tx.wait(3);
  console.log(`> 🟢 Done!`);

  console.log(`> Authorizing MarketOrderExecutor on TradeMiningManager`);
  const tradeMiningManager = TradeMiningManager__factory.connect(
    config.TradeMining.tradeMiningManager,
    deployer
  );
  tx = await tradeMiningManager.setAuth(marketOrderRouter.address, true);
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for confirmation...`);
  await tx.wait(3);
  console.log(`> 🟢 Done!`);

  console.log(
    `> Authorizing MarketOrderExecutor as a PriceUpdater on PythPriceFeed`
  );
  const pythPriceFeed = PythPriceFeed__factory.connect(
    config.Pools.ALP.pythPriceFeed,
    deployer
  );
  tx = await pythPriceFeed.setUpdater(marketOrderExecutor.address, true);
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for confirmation...`);
  await tx.wait(3);
  console.log(`> 🟢 Done!`);

  console.log(`> Authorizing protocol keeper as a executor`);
  tx = await marketOrderExecutor.setExecutor(
    "0xF62Bf3b5608FC5ED119735aDfc3DC3A4814AC884",
    true
  );
  console.log(`> Tx is submitted: ${tx.hash}`);
  console.log(`> Waiting for confirmation...`);
  await tx.wait(3);
  console.log(`> 🟢 Done!`);
};

export default func;
func.tags = ["MarketOrderExecutor_Deploy"];
