import { Signer } from "ethers";
import { ethers, tenderly, upgrades } from "hardhat";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

export async function upgrade(
  contractName: string,
  address: string,
  deployer: Signer
) {
  console.log(`> Preparing to upgrade ${contractName}`);
  const contractFactory = await ethers.getContractFactory(
    contractName,
    deployer
  );
  const newImpl = await upgrades.prepareUpgrade(address, contractFactory);
  console.log(`> Done`);

  console.log(`> New ${contractName} Implementation address: ${newImpl}`);
  const upgradeTx = await upgrades.upgradeProxy(address, contractFactory);
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`);
  console.log(`> Waiting for tx to be mined...`);
  await upgradeTx.deployTransaction.wait();
  console.log(`> Tx is mined!`);

  const implAddress = await getImplementationAddress(ethers.provider, address);

  console.log(`> Verify contract on Tenderly`);
  await tenderly.verify({
    address: implAddress,
    name: contractName,
  });
  console.log(`> ✅ Done`);
}
