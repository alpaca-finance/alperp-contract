import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { IPyth__factory, PythPriceFeed__factory } from "../../typechain";
import { getConfig } from "../utils/config";
import { EvmPriceServiceConnection } from "@pythnetwork/pyth-evm-js";
import * as readlineSync from "readline-sync";

const config = getConfig();

const PYTH = config.ThirdParty.Oracle.Pyth.address;

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pyth = IPyth__factory.connect(PYTH, deployer);

  const connection = new EvmPriceServiceConnection(
    "https://xc-mainnet.pyth.network"
  );

  const priceIds = Object.values<string>(
    config.ThirdParty.Oracle.Pyth.priceIDs
  );

  console.log("> Updating pyth token prices using:");
  console.table(priceIds);

  const priceUpdateData = await connection.getPriceFeedsUpdateData(priceIds);

  const confirm = readlineSync.question("Confirm? (y/n): ");
  switch (confirm.toLowerCase()) {
    case "y":
      break;
    case "n":
      console.log("Aborting");
      return;
    default:
      console.log("Invalid input");
      return;
  }

  const updateFee = await pyth.getUpdateFee(priceUpdateData);
  console.log(`fee: ${ethers.utils.formatEther(updateFee)}`);

  const tx = await pyth.updatePriceFeeds(priceUpdateData, {
    value: updateFee,
  });
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);

  await tx.wait();
  console.log(">✅ Done Updating pyth token Prices");

  for (const priceId of priceIds) {
    console.log(priceId);
    console.log((await pyth.getPrice(priceId)).price.toString());
  }
};

export default func;
func.tags = ["UpdatePythTokenPrices"];
