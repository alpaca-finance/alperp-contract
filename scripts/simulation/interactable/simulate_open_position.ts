import { task } from "hardhat/config";
import { getConfig } from "../utils";

task("invoke:simulate_open_position", "Simulate Open Position")
  .addParam("alpPoolAddress", "Alperp Pool Address")
  .addParam("poolOracleAddress", "Pool Oracle Address")
  .addParam("tokenIn", "Input Token Address")
  .addParam("collateralToken", "Token To Be Used As Collateral")
  .addParam("indexToken", "Token to Be used as an Index Token")
  .addParam("amountIn", "Input Amount")
  .addParam("isNative", "Is TokenIn a Native")
  .addParam("isLong", "Is Long Position")
  .addParam(
    "leverageX",
    "How much you want to Leverage (2x?, 4x?,...  100x?????)"
  )
  .setAction(
    async (
      {
        alpPoolAddress,
        poolOracleAddress,
        tokenIn,
        collateralToken,
        indexToken,
        amountIn,
        isNative,
        isLong,
        leverageX,
      }: {
        alpPoolAddress: string;
        poolOracleAddress: string;
        tokenIn: string;
        collateralToken: string;
        indexToken: string;
        amountIn: string;
        isNative: number;
        isLong: number;
        leverageX: string;
      },
      hre
    ) => {
      const _isLong = !!Number(isLong);
      const _isNative = !!Number(isNative);
      const ethers = hre.ethers;
      const config = getConfig(hre);
      const deployer = (await ethers.getSigners())[0];
      const poolRouterAddress = config.PoolRouter;
      const poolRouter = (
        await hre.ethers.getContractFactory("PoolRouter", deployer)
      ).attach(poolRouterAddress);
      const poolOracle = (
        await hre.ethers.getContractFactory("PoolOracle", deployer)
      ).attach(poolOracleAddress);

      const tokenPrice = _isLong
        ? await poolOracle.getMaxPrice(tokenIn)
        : await poolOracle.getMinPrice(tokenIn);
      const maxPrice = await poolOracle.getMaxPrice(tokenIn);
      const minPrice = await poolOracle.getMinPrice(tokenIn);
      const leverage = ethers.utils.parseEther(leverageX);
      const sizeDelta = tokenPrice
        .mul(amountIn)
        .mul(leverage)
        .div(ethers.constants.WeiPerEther)
        .div(ethers.constants.WeiPerEther)
        .toString();

      if (_isNative) {
        console.log(">> Execute: Increase Position With Native");
        console.table({
          "Pool Address": alpPoolAddress,
          "Token In": tokenIn.toString(),
          "Collateral Token": collateralToken.toString(),
          "Amount In": amountIn.toString(),
          "Min Amount Out": tokenPrice.mul(amountIn).toString(),
          "Index Token": indexToken.toString(),
          "Size Delta": sizeDelta.toString(),
          "Is Long": _isLong,
          "Acceptable Price": tokenPrice.toString(),
          "Max Price": maxPrice.toString(),
          "Min Price": minPrice.toString(),
        });
        const tx = await poolRouter.increasePositionNative(
          0,
          tokenIn,
          collateralToken,
          0,
          indexToken,
          sizeDelta,
          _isLong,
          tokenPrice,
          {
            value: amountIn,
            gasLimit: 10000000,
          }
        );
        await tx.wait();
        console.log(">> ✅ DONE");
        return;
      }

      console.log(">> Execute: Increase Position Without Native");
      console.table({
        "Pool Address": alpPoolAddress,
        "Token In": tokenIn.toString(),
        "Collateral Token": collateralToken.toString(),
        "Amount In": amountIn.toString(),
        "Min Amount Out": tokenPrice.mul(amountIn).toString(),
        "Index Token": indexToken.toString(),
        "Size Delta": sizeDelta.toString(),
        "Is Long": isNative,
        "Acceptable Price": tokenPrice.toString(),
        "Max Price": maxPrice.toString(),
        "Min Price": minPrice.toString(),
      });
      const token = (
        await hre.ethers.getContractFactory("ERC20", deployer)
      ).attach(tokenIn);
      const approvalTx = await token.approve(poolRouterAddress, amountIn);
      await approvalTx.wait();
      const tx = await poolRouter.increasePosition(
        0,
        tokenIn,
        collateralToken,
        amountIn,
        0,
        indexToken,
        sizeDelta,
        _isLong,
        tokenPrice
      );
      await tx.wait();
      console.log(`>> ✅ DONE with tx hash: ${tx.hash}`);
    }
  );
