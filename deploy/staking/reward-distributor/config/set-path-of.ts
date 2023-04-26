import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { getConfig } from "../../../utils/config";
import { RewardDistributor__factory } from "../../../../typechain";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig();
  const t0s = [
    config.Tokens.BTCB,
    config.Tokens.WBNB,
    config.Tokens.ETH,
    config.Tokens.USDC,
  ];
  const t1s = [
    config.Tokens.USDT,
    config.Tokens.USDT,
    config.Tokens.USDT,
    config.Tokens.USDT,
  ];
  const paths = [
    ethers.utils.solidityPack(
      ["address", "uint24", "address"],
      [config.Tokens.BTCB, 500, config.Tokens.USDT]
    ),
    ethers.utils.solidityPack(
      ["address", "uint24", "address"],
      [config.Tokens.WBNB, 500, config.Tokens.USDT]
    ),
    ethers.utils.solidityPack(
      ["address", "uint24", "address", "uint24", "address"],
      [config.Tokens.ETH, 2500, config.Tokens.BTCB, 500, config.Tokens.USDT]
    ),
    ethers.utils.solidityPack(
      ["address", "uint24", "address"],
      [config.Tokens.USDC, 100, config.Tokens.USDT]
    ),
  ];

  const deployer = (await ethers.getSigners())[0];
  const rewardDistributor = RewardDistributor__factory.connect(
    config.Staking.RewardDistributor.address,
    deployer
  );
  console.log(`> Set path of`);
  const tx = await rewardDistributor.setPathOf(t0s, t1s, paths);
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> 🟢 Done`);
};

export default func;
func.tags = ["RewardDistributor_SetPathOf"];
