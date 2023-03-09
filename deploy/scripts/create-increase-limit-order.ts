import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import {
  ERC20__factory,
  MintableTokenInterface__factory,
  Orderbook__factory,
} from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const ORDERBOOK = config.Pools.ALP.orderbook;
const COLLATERAL_TOKEN = config.Tokens.WBNB;
const INDEX_TOKEN = config.Tokens.WBNB;
const isLong = true;

enum Exposure {
  LONG,
  SHORT,
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const orderbook = Orderbook__factory.connect(ORDERBOOK, deployer);
  const collateralToken = ERC20__factory.connect(COLLATERAL_TOKEN, deployer);
  const decimals = await collateralToken.decimals();

  await (
    await collateralToken.approve(
      orderbook.address,
      ethers.constants.MaxUint256
    )
  ).wait();
  const minExecutionFee = await orderbook.minExecutionFee();
  await (
    await orderbook.createIncreaseOrder(
      0,
      [COLLATERAL_TOKEN],
      ethers.utils.parseUnits("10", decimals),
      INDEX_TOKEN,
      0,
      ethers.utils.parseUnits("32269.18272371", 30),
      COLLATERAL_TOKEN,
      isLong,
      ethers.utils.parseUnits("330.91874550950", 30),
      false,
      minExecutionFee,
      true,
      {
        value: minExecutionFee.add(ethers.utils.parseUnits("10", decimals)),
        gasLimit: 2000000,
        gasPrice: ethers.utils.parseUnits("20", "gwei"),
      }
    )
  ).wait();
  console.log(`Execute createIncreaseOrder`);
};

export default func;
func.tags = ["CreateIncreaseLimitOrder"];
