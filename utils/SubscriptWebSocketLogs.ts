import { Log, WebSocketProvider } from "ethers";

async function main() {
  const wssUrl = "wss://0xrpc.io/eth";

  const provider = new WebSocketProvider(wssUrl);

  const USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";

  const filter = {
    address: [USDT],
  };

  provider.on(filter, (event) => {
    const eventLog = event as Log;
    setImmediate(async () => {
      console.log(
        eventLog.blockNumber,
        eventLog.address,
        eventLog.transactionHash
      );
    });
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
