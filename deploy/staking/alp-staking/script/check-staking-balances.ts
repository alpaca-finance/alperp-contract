import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades, tenderly } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";
import { getConfig } from "../../../utils/config";
import { ALPStaking__factory } from "../../../../typechain";

const config = getConfig();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const blockAddresses = [
    "0x015fa91eeb7f0e4ea3520b9b75b778e70edc0aa3",
    "0x6c41ee8da1ea27e2b20dc6e8b8aa7a7423c971dc",
    "0x84592d7993116373eddbe9aae16c8047e02b9928",
    "0xb16a53fefbb6952db80859e9583a0162baf5870c",
    "0xa1fbe77b1eac5e620f1eb8f9792895a98baf3b3e",
    "0xead758797bae1319307977bd7080660f5401758a",
    "0x5fc4cad40a2c44364c74d600e58a97aafe5b756a",
    "0x866b12632ac2e8eafbd6d3a9d8be5a501ebc9e2d",
    "0xf437ffc12e334383d4fedb232c67568866060171",
    "0x0052d0928016e391240af18c5143f04a5d7a8ff4",
    "0xb2d3689836a584b3a892c393cad02ca285de0de5",
    "0x7f3a42fe83f88ab401fb802e19b2cb5607c792d5",
    "0x7ebce6b96efe2ac9a531c31e276bef5d747a342c",
    "0x91b77478f874cbe35ce78b8e7ead8ed7f37443e8",
    "0x1616d4b048c580ad17430ed71054404d0c4da134",
    "0x003975997496496465a3bc1d5c8c2128c8ce998f",
    "0x7f35f5c60c02ead4ad64db2abf8806af11c9339a",
    "0x99f01f704b6f0dbec3437b73b360a8b0a6cab58d",
  ];

  const deployer = (await ethers.getSigners())[0];
  const alpStaking = ALPStaking__factory.connect(
    config.Staking.ALPStaking.address,
    deployer
  );
  const promises = [];
  for (const blockAddress of blockAddresses) {
    promises.push(
      alpStaking.userTokenAmount(
        "0x86a0384836Bd6fD6ad7Da9EBbA0F330300a6b2A8",
        "0xb4b020134a441500a4c0fda28abe0b3b83aab9ed"
      )
    );
  }
  const balances = await Promise.all(promises);

  console.table(
    balances.map((balance) => ethers.utils.formatUnits(balance, 18))
  );
};

export default func;
func.tags = ["ALPStakingCheckBalances"];
