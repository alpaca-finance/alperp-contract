import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../../../utils/config";
import { LiquidationRouter01__factory } from "../../../../typechain";

interface SetLiquidatorArgs {
  liquidatorAddress: string;
  isAllowed: boolean;
}

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();

  const args: Array<SetLiquidatorArgs> = [
    {
      liquidatorAddress: "0xFef9d28767de30F4239B9b40Bc915919b0bcACe8",
      isAllowed: true,
    },
  ];

  const deployer = (await ethers.getSigners())[0];

  console.log(`> Setting liquidators on LiquidationRouter01`);
  const liquidationRouter01 = LiquidationRouter01__factory.connect(
    config.LiquidationRouter,
    deployer
  );

  for (const arg of args) {
    console.log(
      `> Setting liquidator ${arg.liquidatorAddress} to ${arg.isAllowed}...`
    );
    const tx = await liquidationRouter01.setLiquidator(
      arg.liquidatorAddress,
      arg.isAllowed
    );
    console.log(`> ⛓ Tx submitted: ${tx.hash}`);
    console.log(`> Waiting for tx to be mined...`);
    await tx.wait(3);
    console.log(`> Tx mined!`);
  }
};

export default func;
func.tags = ["LiquidationRouter01SetLiquidator"];
