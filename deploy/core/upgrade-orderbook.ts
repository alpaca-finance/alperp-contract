import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { ethers, upgrades, tenderly } from "hardhat"
import { getConfig } from "../utils/config"
import { getImplementationAddress } from "@openzeppelin/upgrades-core"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig()

  const TARGET_ADDRESS = config.Pools.ALP.orderbook

  const deployer = (await ethers.getSigners())[0]
  const Orderbook02 = await ethers.getContractFactory("Orderbook02", deployer)

  console.log(`> Preparing to upgrade Orderbook02`)
  const newOrderbook02 = await upgrades.prepareUpgrade(
    TARGET_ADDRESS,
    Orderbook02
  )
  console.log(`> Done`)

  console.log(`> New Orderbook02 Implementation address: ${newOrderbook02}`)
  const upgradeTx = await upgrades.upgradeProxy(TARGET_ADDRESS, Orderbook02)
  console.log(`> ⛓ Tx is submitted: ${upgradeTx.deployTransaction.hash}`)
  console.log(`> Waiting for tx to be mined...`)
  await upgradeTx.deployTransaction.wait()
  console.log(`> Tx is mined!`)

  const implAddress = await getImplementationAddress(
    ethers.provider,
    TARGET_ADDRESS
  )

  console.log(`> Verify contract on Tenderly`)
  await tenderly.verify({
    address: implAddress,
    name: "Orderbook02",
  })
  console.log(`> ✅ Done`)
}

export default func
func.tags = ["UpgradeOrderBook"]
