import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PythPriceFeed__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";

const config = getConfig();

const PYTH_PRICE_FEED = config.Pools.ALP.pythPriceFeed;

const MAX_AGE = 25; // 10 seconds

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pythPriceFeed = PythPriceFeed__factory.connect(
    PYTH_PRICE_FEED,
    deployer
  );

  console.log("> Setting pyth price feed max age");
  const tx = await pythPriceFeed.setMaxPriceAge(MAX_AGE);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();

  console.log(`> ✅ Done setting pyth price feed max age`);
};

export default func;
func.tags = ["PythPriceFeed_SetPythPriceFeedMaxAge"];
