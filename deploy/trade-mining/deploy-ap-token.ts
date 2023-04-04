import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { ethers, upgrades, tenderly, network } from "hardhat"
import { getConfig, writeConfigFile } from "../utils/config"
import { getImplementationAddress } from "@openzeppelin/upgrades-core"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig()

  const deployer = (await ethers.getSigners())[0]
  const AP = await ethers.getContractFactory("AP", deployer)
  const alp = await upgrades.deployProxy(AP)
  await alp.deployed()
  console.log(`Deploying AP Token Contract`)
  console.log(`Deployed at: ${alp.address}`)

  config.Tokens.AP = alp.address
  config.TradeMining.miningPoint = alp.address
  writeConfigFile(config)

  const implAddress = await getImplementationAddress(
    network.provider,
    alp.address
  )

  await tenderly.verify({
    address: implAddress,
    name: "AP",
  })
}

export default func
func.tags = ["APToken"]
