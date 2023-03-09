import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { PythPriceFeed__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const PYTH_PRICE_FEED = config.Pools.ALP.pythPriceFeed;

const FEED_INFOS = Object.entries<string>(
  config.ThirdParty.Oracle.Pyth.priceIDs
).map(([token, priceId]) => ({
  token: config.Tokens[token as keyof typeof config.Tokens],
  priceId,
}));

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pythPriceFeed = PythPriceFeed__factory.connect(
    PYTH_PRICE_FEED,
    deployer
  );

  console.log("> Setting price feeds using:");
  console.table(FEED_INFOS);
  const [tokens, priceIds] = FEED_INFOS.reduce<[Array<string>, Array<string>]>(
    (accum, feedInfo) => {
      if (accum[0].length == 0) {
        return [[feedInfo.token], [feedInfo.priceId]];
      }
      return [
        [...accum[0], feedInfo.token],
        [...accum[1], feedInfo.priceId],
      ];
    },
    [[], []]
  );
  console.log(tokens);
  console.log(priceIds);
  const tx = await pythPriceFeed.setTokenPriceIds(tokens, priceIds);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Done setting price feeds`);
};

export default func;
func.tags = ["SetPythPriceFeedTokenPriceIds"];
