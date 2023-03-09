import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../utils/config";
import { MockPoolOracle__factory } from "../../typechain";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const oracle = MockPoolOracle__factory.connect(
    config.Pools.ALP.oracle,
    deployer
  );
  await oracle.feedMinPrice(
    config.Tokens.WBNB,
    ethers.utils.parseUnits("0.82", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.WBNB,
    ethers.utils.parseUnits("0.82", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.BTCB,
    ethers.utils.parseUnits("21899", 30)
  );

  await oracle.feedMaxPrice(
    config.Tokens.BTCB,
    ethers.utils.parseUnits("21899", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.WETH,
    ethers.utils.parseUnits("1360", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.WETH,
    ethers.utils.parseUnits("1360", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.DAI,
    ethers.utils.parseUnits("1", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.DAI,
    ethers.utils.parseUnits("1", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.USDT,
    ethers.utils.parseUnits("1", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.USDT,
    ethers.utils.parseUnits("1", 30)
  );

  await oracle.feedMinPrice(
    config.Tokens.USDC,
    ethers.utils.parseUnits("1", 30)
  );
  await oracle.feedMaxPrice(
    config.Tokens.USDC,
    ethers.utils.parseUnits("1", 30)
  );
  console.log("Done");
};

export default func;
func.tags = ["FeedPrice"];
