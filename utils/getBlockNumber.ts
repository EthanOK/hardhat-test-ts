import { ethers } from "ethers";

async function getBlockNumber(): Promise<number> {
  const provider = new ethers.JsonRpcProvider("https://rpc.ankr.com/eth");

  const blockNumber: number = await provider.getBlockNumber();

  return blockNumber;
}

getBlockNumber().then((value) => {
  console.log(value);
});
