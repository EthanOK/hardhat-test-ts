# Hardhat Integrate Foundry Project

```
git clone -b hardhat-foundry-demo https://github.com/EthanOK/hardhat-test-ts.git
```

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

## install

```shell
npm install && forge install
```

## 获取 standard-json-input,验证合约

`forge verify-contract --show-standard-json-input 0x0000000000000000000000000000000000000000 Lock > cache/temp.json`
