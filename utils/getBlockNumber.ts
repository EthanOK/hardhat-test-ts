import { ethers } from "ethers";

async function getBlockNumber(): Promise<number> {
  const provider = new ethers.JsonRpcProvider(
    "https://eth-mainnet.diamondswap.org/rpc"
  );

  const blockNumber: number = await provider.getBlockNumber();

  return blockNumber;
}

getBlockNumber().then((value) => {
  console.log(value);
});
