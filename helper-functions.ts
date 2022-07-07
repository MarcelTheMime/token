import { ethers, network, run } from "hardhat"

export const verify = async (contractAddress: string, args: any[], nameContract?: string) => {
  console.log("Verifying contract...")
  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
      ...(nameContract !== undefined && {contract:nameContract})
    })
  } catch (e: any) {
    if (e.message.toLowerCase().includes("already verified")) {
      console.log("Already verified!")
    } else {
      console.log(e)
    }
  }
}
