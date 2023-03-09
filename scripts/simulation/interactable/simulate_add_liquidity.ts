import { task } from "hardhat/config";

import { getConfig } from "../utils";

task("invoke:simulate_add_liquidity", "Simulate Add Liquidity")
  .addParam("alpPoolAddress", "Alperp Pool Address")
  .addParam("tokenAddress", "Input Token Address")
  .addParam("tokenAmount", "Input Token Amount")
  .addParam("receiver", "Receiver For ALP Token")
  .addParam("minLiquidity", "Accepted Output Liquidity")
  .addParam("isNative", "Is Token A Native")
  .setAction(
    async (
      {
        alpPoolAddress,
        tokenAddress,
        tokenAmount,
        receiver,
        minLiquidity,
        isNative,
      }: {
        alpPoolAddress: string;
        tokenAddress: string;
        tokenAmount: string;
        receiver: string;
        minLiquidity: string;
        isNative: number;
      },
      hre
    ) => {
      const ethers = hre.ethers;
      const config = getConfig(hre);
      const deployer = (await ethers.getSigners())[0];
      const poolRouterAddress = config.PoolRouter;
      const poolRouter = (
        await hre.ethers.getContractFactory("PoolRouter", deployer)
      ).attach(poolRouterAddress);
      const _isNative = !!Number(isNative);

      console.log(">> Execute: Add Liquidity");
      console.table({
        "Pool Address": alpPoolAddress,
        "Token Address": tokenAddress,
        "Token Amount": tokenAmount.toString(),
        Receiver: receiver,
        "Min Liquidity": minLiquidity.toString(),
        "Is Native": _isNative,
      });

      if (_isNative) {
        console.log(">> Execute: Add Liquidity With Native");
        const tx = await poolRouter.addLiquidityNative(
          tokenAddress,
          receiver,
          minLiquidity,
          { value: tokenAmount }
        );
        await tx.wait();
        console.log(`>> ✅ DONE with tx hash: ${tx.hash}`);
        return;
      }

      console.log(">> Execute: Add Liquidity Without Native");
      const token = (
        await hre.ethers.getContractFactory("ERC20", deployer)
      ).attach(tokenAddress);
      const approvalTx = await token.approve(poolRouterAddress, tokenAmount);
      await approvalTx.wait();
      const tx = await poolRouter.addLiquidity(
        tokenAddress,
        tokenAmount,
        receiver,
        minLiquidity
      );
      await tx.wait();
      console.log(`>> ✅ DONE with tx hash: ${tx.hash}`);
    }
  );
