import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../utils/config";
import { FastPriceFeed__factory, PoolOracle__factory } from "../../typechain";

const BigNumber = ethers.BigNumber;

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const fastPriceFeed = FastPriceFeed__factory.connect(
    config.Pools.ALP.fastPriceFeed,
    deployer
  );
  const poolOracle = PoolOracle__factory.connect(
    config.Pools.ALP.oracle,
    deployer
  );
  const timestamp = (new Date().valueOf() / 1000).toFixed();
  const tx = await fastPriceFeed.setPricesWithBits(
    getPriceBits(["16686750", "1000", "326351", "1000"]),
    timestamp,
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    { gasLimit: 10000000 }
  );
  console.log(tx.hash);
  await tx.wait();

  // BTCB
  console.log(
    "BTCB fast price: ",
    await fastPriceFeed.getPrice(
      config.Tokens.BTCB,
      await poolOracle.getLatestPrimaryPrice(config.Tokens.BTCB),
      true
    )
  );
  console.log(
    "BTCB pool oracle price: ",
    await poolOracle.getPrice(config.Tokens.BTCB, true),
    await poolOracle.getPrice(config.Tokens.BTCB, false)
  );
  console.log(await fastPriceFeed.favorFastPrice(config.Tokens.BTCB));
  console.log(
    "BTCB getPriceData",
    await fastPriceFeed.getPriceData(config.Tokens.BTCB)
  );

  // DAI
  console.log(
    "DAI fast price: ",
    await fastPriceFeed.getPrice(
      config.Tokens.DAI,
      await poolOracle.getLatestPrimaryPrice(config.Tokens.DAI),
      true
    )
  );
  console.log(
    "DAI pool oracle price: ",
    await poolOracle.getPrice(config.Tokens.DAI, true),
    await poolOracle.getPrice(config.Tokens.DAI, false)
  );
  console.log(await fastPriceFeed.favorFastPrice(config.Tokens.DAI));

  // WBNB
  console.log(
    "WBNB fast price: ",
    await fastPriceFeed.getPrice(
      config.Tokens.WBNB,
      await poolOracle.getLatestPrimaryPrice(config.Tokens.WBNB),
      true
    )
  );
  console.log(
    "WBNB pool oracle price: ",
    await poolOracle.getPrice(config.Tokens.WBNB, true),
    await poolOracle.getPrice(config.Tokens.WBNB, false)
  );
  console.log(await fastPriceFeed.favorFastPrice(config.Tokens.WBNB));
  console.log("Done");

  // BUSD
  console.log(
    "BUSD fast price: ",
    await fastPriceFeed.getPrice(
      config.Tokens.BUSD,
      await poolOracle.getLatestPrimaryPrice(config.Tokens.BUSD),
      true
    )
  );
  console.log(
    "BUSD pool oracle price: ",
    await poolOracle.getPrice(config.Tokens.BUSD, true),
    await poolOracle.getPrice(config.Tokens.BUSD, false)
  );
  console.log(await fastPriceFeed.favorFastPrice(config.Tokens.BUSD));
  console.log("Done");
};

function getPriceBits(prices: string[]) {
  if (prices.length > 8) {
    throw new Error("max prices.length exceeded");
  }

  let priceBits = BigNumber.from(0);

  for (let j = 0; j < 8; j++) {
    let index = j;
    if (index >= prices.length) {
      break;
    }

    const price = BigNumber.from(prices[index]);
    if (price.gt(BigNumber.from("2147483648"))) {
      // 2^31
      throw new Error(`price exceeds bit limit ${price.toString()}`);
    }

    priceBits = priceBits.or(price.shl(j * 32));
  }

  return priceBits.toString();
}

export default func;
func.tags = ["FeedFastPrice"];
