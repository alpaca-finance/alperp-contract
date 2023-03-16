import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { AdminFacetInterface__factory } from "../../typechain";
import { getConfig } from "../utils/config";

const config = getConfig();

const TOKEN_CONFIGS = [
  {
    token: config.Tokens.USDC,
    accept: true,
    isStable: true,
    isShortable: false,
    decimals: 18,
    weight: 2500,
    minProfitBps: 0,
    usdDebtCeiling: ethers.utils.parseEther("2000000"),
    shortCeiling: 0,
    bufferLiquidity: ethers.utils.parseUnits("0", 18),
    openInterestLongCeiling: 0,
  },
];

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const deployer = (await ethers.getSigners())[0];
  const pool = AdminFacetInterface__factory.connect(
    config.Pools.ALP.poolDiamond,
    deployer
  );

  console.log("> Setting token configs");
  const tx = await pool.setTokenConfigs(
    TOKEN_CONFIGS.map((each) => each.token),
    TOKEN_CONFIGS
  );
  console.log(`> ⛓ Tx submitted: ${tx.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await tx.wait();
  console.log(`> ✅ Token configs set`);
};

export default func;
func.tags = ["SetTokenConfigs"];
