import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../../../typechain";
import { getConfig } from "../../../utils/config";
import {
  FundingRateFacet__factory,
  GetterFacetInterface__factory,
} from "../../../../typechain";
import * as readlineSync from "readline-sync";
import { BigNumberish } from "ethers";

interface SetFundingRateArgs {
  fundingInterval?: BigNumberish;
  fundingRateFactor?: BigNumberish;
  stableBorrowingRateFactor?: BigNumberish;
  borrowingRateFactor?: BigNumberish;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const args: SetFundingRateArgs = {
    stableBorrowingRateFactor: 70, // 0.007% / 1 hour
    fundingRateFactor: 20,
  };

  const config = getConfig();
  const deployer = (await ethers.getSigners())[0];
  const adminFacet = AdminFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  const getterFacet = GetterFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  const fundingFacet = FundingRateFacet__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );
  const prevArgs: SetFundingRateArgs = {};
  [
    prevArgs.fundingInterval,
    prevArgs.borrowingRateFactor,
    prevArgs.stableBorrowingRateFactor,
    prevArgs.fundingRateFactor,
  ] = await Promise.all([
    getterFacet.fundingInterval(),
    getterFacet.borrowingRateFactor(),
    getterFacet.stableBorrowingRateFactor(),
    getterFacet.fundingRateFactor(),
  ]);
  const confirmTable = [];
  for (const key in prevArgs) {
    let tmp = {};
    if (args[key as keyof SetFundingRateArgs] === undefined) {
      tmp = {
        key: key,
        prev: prevArgs[key as keyof SetFundingRateArgs],
        new: undefined,
      };
    } else {
      tmp = {
        key: key,
        prev: prevArgs[key as keyof SetFundingRateArgs],
        new: args[key as keyof SetFundingRateArgs],
      };
    }
    confirmTable.push(tmp);
  }
  console.table(confirmTable);
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

  let nonce = await deployer.getTransactionCount();
  console.log(`> Updating funding for every pools`);
  const markets = [
    {
      collateral: config.Tokens.BTCB,
      index: config.Tokens.BTCB,
    },
    {
      collateral: config.Tokens.ETH,
      index: config.Tokens.ETH,
    },
    {
      collateral: config.Tokens.WBNB,
      index: config.Tokens.WBNB,
    },
    {
      collateral: config.Tokens.USDC,
      index: config.Tokens.BTCB,
    },
    {
      collateral: config.Tokens.USDC,
      index: config.Tokens.ETH,
    },
    {
      collateral: config.Tokens.USDC,
      index: config.Tokens.WBNB,
    },
    {
      collateral: config.Tokens.USDT,
      index: config.Tokens.BTCB,
    },
    {
      collateral: config.Tokens.USDT,
      index: config.Tokens.ETH,
    },
    {
      collateral: config.Tokens.USDT,
      index: config.Tokens.WBNB,
    },
  ];
  const promises = [];
  for (const market of markets) {
    promises.push(
      fundingFacet.updateFundingRate(market.collateral, market.index, {
        nonce: nonce++,
      })
    );
  }
  const txs = await Promise.all(promises);
  console.log(`> ⛓ Txs are submitted`);
  console.log(`> Waiting tx to be mined...`);
  txs[txs.length - 1].wait(3);
  console.log(`> 🟢 Done updating funding for every pools`);

  // console.log(`> Setting Pool's funding params`);
  // const tx = await adminFacet.setFundingRate(
  //   args.fundingInterval || prevArgs.fundingInterval,
  //   args.borrowingRateFactor || prevArgs.borrowingRateFactor,
  //   args.stableBorrowingRateFactor || prevArgs.stableBorrowingRateFactor,
  //   args.fundingRateFactor || prevArgs.fundingRateFactor,
  //   { nonce: nonce++ }
  // );
  // console.log(`> ⛓ Tx is submitted: ${tx.hash}`);
  // await tx.wait(3);
  // console.log(`> 🟢 Done setting Pool's funding params`);
};

export default func;
func.tags = ["Pool_SetFundingRate"];
