import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { ethers, upgrades, tenderly } from "hardhat"
import { getConfig, writeConfigFile } from "../utils/config"
import { getImplementationAddress } from "@openzeppelin/upgrades-core"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig()

  const deployer = (await ethers.getSigners())[0]

  console.log(`> Deploying Miner Contract`)
  const Miner = await ethers.getContractFactory("Miner", deployer)
  const miner = await upgrades.deployProxy(Miner)
  console.log(`> ⛓ Tx submitted: ${miner.deployTransaction.hash}`)
  console.log(`> Waiting tx to be mined...`)
  await miner.deployed()
  console.log(`> Tx mined!`)
  console.log(`> Deployed at: ${miner.address}`)

  config.Pools.ALP.miner = miner.address
  writeConfigFile(config)

  console.log(`> Verifying contract on Tenderly...`)
  const implAddress = await getImplementationAddress(
    ethers.provider,
    miner.address
  )
  await tenderly.verify({
    address: implAddress,
    name: "Miner",
  })
  console.log(`> ✅ Done!`)
}

export default func
func.tags = ["Miner"]
