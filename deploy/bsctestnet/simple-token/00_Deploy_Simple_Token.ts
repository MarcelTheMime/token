import { DeployFunction } from "hardhat-deploy/types"
import { network } from "hardhat"
import { verify } from "../../../helper-functions"

const deployFunction: DeployFunction = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments

  const { deployer } = await getNamedAccounts()
  const chainId: number | undefined = network.config.chainId
  if (!chainId) return


  log(`----------------------------------------------------`)
  const simpleToken = await deploy("SimpleToken", {
    from: deployer,
    args: ["1000000000000000000000"],
    log: true,
    waitConfirmations: 6
  })


  log("Address:")
  log(simpleToken.address)

  log("Verifying...")
  await verify(simpleToken.address, ["1000000000000000000000"], "contracts/SimpleToken.sol:SimpleToken")
}

export default deployFunction
deployFunction.tags = [`all`, `feed`, `main`]