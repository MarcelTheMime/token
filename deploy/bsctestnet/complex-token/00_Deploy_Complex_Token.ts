import { DeployFunction } from "hardhat-deploy/types"
import { network } from "hardhat"
import { verify } from "../../../helper-functions"

const deployFunction: DeployFunction = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments

  const { deployer } = await getNamedAccounts()
  const chainId: number | undefined = network.config.chainId
  if (!chainId) return

  const walletAddress = process.env.WALLET_ADDRESS;

  const nameOfToken = "TestToken";
  const ticker = "TST";
  const decimals = "18";
  const supply = "1000";
  const pancakeTestRouter = "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3";

  log(`----------------------------------------------------`)
  const simpleToken = await deploy("ComplexToken", {
    from: deployer,
    args: [
      nameOfToken,
      ticker,
      decimals,
      supply,
      [walletAddress, walletAddress, pancakeTestRouter],
      false,
      ["0", "0", "0", "0", "0", "0", "0", "0", "0"],
      ["500", "500", "500"]
    ],
    log: true,
    waitConfirmations: 6
  })



  log("Address:")
  log(simpleToken.address)

  log("Verifying...")
  await verify(simpleToken.address, [
    nameOfToken,
    ticker,
    decimals,
    supply,
    [walletAddress, walletAddress, pancakeTestRouter],
    false,
    ["0", "0", "0", "0", "0", "0", "0", "0", "0"],
    ["500", "500", "500"]
  ])

}

export default deployFunction
deployFunction.tags = [`all`, `feed`, `main`]