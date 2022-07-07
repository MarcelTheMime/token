# Simple Setup

# Install

To install the dependencies: 

```
yarn install
```

This should be inside the folder

This setup use testnet for bsc. That mean you need a bsc account with bnb inside the testnet. Please go to the `.env` file inside the root folder and change the `PRIVATE_KEY` variable to your private key. The same applies to your wallet address. This private key can be imported to metamask if you want to.

If you want to create a full new random wallet run this line by line:

```javascript
node
const { ethers } = require("ethers");
let x = ethers.Wallet.createRandom()
x.privateKey
x.address
```

Then you will need test bnb for running the contracts. You should be able to get test bnb [HERE](https://testnet.binance.org/faucet-smart)

### BSCSCANN

Moreover go to [HERE](https://bscscan.com/login) and create an account. Then creat an api key inside the dashboard and save this api key. Then go to the `.env` file and replace the `BSC_SCANN` variable with the api key you created.

### Simple Contract

to deploy the simple contract please do this inside the root folder:

```
npx hardhat deploy --network bsctestnet --deploy-scripts .\deploy\bsctestnet\simple-token\
```

### Comple contract

to deploy the complex contract please do this inside the root folder:

```
npx hardhat deploy --network bsctestnet --deploy-scripts .\deploy\bsctestnet\complex-token\
```

at the end with both contracts you are going to see the address on the console. If you make updates to the contract you just need to run the deploy again.