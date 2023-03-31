import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import { ethers } from "hardhat"
import { IMineable__factory } from "../../typechain"
import { getConfig } from "../utils/config"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const config = getConfig()

  const MINEABLE_ADDRESSES = [config.PoolRouter, config.Pools.ALP.orderbook]
  const MINER_ADDRESS = config.Pools.ALP.miner

  const deployer = (await ethers.getSigners())[0]

  for (let i = 0; i < MINEABLE_ADDRESSES.length; i++) {
    const miner = IMineable__factory.connect(MINEABLE_ADDRESSES[i], deployer)
    console.log(
      `> Setting miner [${i + 1}/${
        MINEABLE_ADDRESSES.length
      }] for mineable: ${MINER_ADDRESS}`
    )
    const tx = await miner.setMiner(MINER_ADDRESS)
    console.log(`> ⛓ Tx submitted: ${tx.hash}`)
    console.log(`> Waiting for tx to be mined...`)
    await tx.wait()
    console.log(`> Tx mined!`)
  }

  console.log(`> ✅ Done!`)
}

export default func
func.tags = ["SetMineable"]
