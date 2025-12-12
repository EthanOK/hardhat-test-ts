import { TronWeb } from "tronweb";
import "dotenv/config";
import { usdtAbi } from "./abi";

const TRONGRID_API_KEY = "6bc2b2e1-19e7-4ed4-b029-251c2f65867c";

async function main() {
  const tronWeb = new TronWeb({
    // https://api.trongrid.io https://nile.trongrid.io
    fullHost: "https://nile.trongrid.io",
    headers: { "TRON-PRO-API-KEY": TRONGRID_API_KEY },
    privateKey: process.env.PrivateKey.slice(2),
  });

  const owner = tronWeb.defaultAddress.base58;

  const reciever = "TBhnvEYTnu9ENfcUu7WmmhiV9m258xwkVk";

  let balance = await tronWeb.trx.getBalance(owner);

  console.log(`${owner}: ${tronWeb.fromSun(balance)} TRX`);

  // let balance_reciever = await tronWeb.trx.getBalance(reciever);

  // console.log(`${reciever}: ${tronWeb.fromSun(balance_reciever)} TRX`);

  // const transaction = await tronWeb.trx.sendTrx(
  //   reciever,
  //   Number(tronWeb.toSun(1))
  // );

  // const info = await waitForTronConfirmation(tronWeb, transaction.txid);

  // console.log(`After Transfer TRX`);
  // const balance_reciever_ = await tronWeb.trx.getBalance(reciever);
  // console.log(`${reciever}: ${tronWeb.fromSun(balance_reciever_)} TRX`);

 
  // TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf
  const USDT = "TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf";
  const usdt = tronWeb.contract(usdtAbi, USDT);

  const symbol = await usdt.symbol().call({
    isConstant: true,
  });
  const decimals = (await usdt.decimals().call({
    isConstant: true,
  })) as bigint;
  const balance_usdt =
    ((await usdt.balanceOf(owner).call()) as bigint) / 10n ** decimals;

  console.log(`${owner}: ${balance_usdt} ${symbol}`);

  // transfer USDT

  let balance_usdt_reciever =
    ((await usdt.balanceOf(reciever).call()) as bigint) / 10n ** decimals;

  console.log(`${reciever}: ${balance_usdt_reciever} ${symbol}`);

  const amount = 1n * 10n ** decimals;

  const txId = await usdt.transfer(reciever, amount).send();

  const info_ = await waitForTronConfirmation(tronWeb, txId, false);

  console.log(info_);

  balance_usdt_reciever =
    ((await usdt.balanceOf(reciever).call()) as bigint) / 10n ** decimals;

  console.log("After Transfer USDT");
  console.log(`${reciever}: ${balance_usdt_reciever} ${symbol}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

interface WaitForConfirmationOptions {
  timeoutMs?: number;
  pollIntervalMs?: number;
}

async function waitForTronConfirmation(
  tronWeb: TronWeb,
  txID: string,
  wait20BlocksConfirmed = true,
  options: WaitForConfirmationOptions = {
    timeoutMs: 120000,
    pollIntervalMs: 3000,
  }
) {
  const waitBlock = wait20BlocksConfirmed ? 20 : 1;
  console.log(
    `Waiting for transaction confirmation ${waitBlock} blocks: ${txID}`
  );
  const startTime = Date.now();

  while (true) {
    try {
      const info = wait20BlocksConfirmed
        ? await tronWeb.trx.getTransactionInfo(txID)
        : await tronWeb.trx.getUnconfirmedTransactionInfo(txID);
      // 有数据后跳出 while 循环
      if (info) {
        return {
          id: info.id,
          blockNumber: info.blockNumber,
          blockTime: info.blockTimeStamp,
          result: info.receipt.result,
          status: wait20BlocksConfirmed ? "CONFIRMED" : "UNCONFIRMED",
        };
      }
    } catch (error) {
      // 交易还未确认，继续等待
    }

    // 检查是否超时
    if (Date.now() - startTime > options.timeoutMs) {
      throw new Error(`交易确认超时: ${txID}`);
    }

    await new Promise((resolve) => setTimeout(resolve, options.pollIntervalMs));
  }
}
