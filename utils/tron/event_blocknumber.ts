import { TronWeb } from "tronweb";
import "dotenv/config";

const TRONGRID_API_KEY = process.env.TRONGRID_API_KEY;

async function main() {
  // https://api.trongrid.io https://nile.trongrid.io
  const tronWeb = new TronWeb({
    fullHost: "https://api.trongrid.io",
    headers: { "TRON-PRO-API-KEY": TRONGRID_API_KEY },
  });
  // TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf
  const USDT = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";

  const currentBlock = await tronWeb.trx.getBlock("latest");

  let startBlockNumber = currentBlock.block_header.raw_data.number - 1;

  const sleep = (ms: number) =>
    new Promise((resolve) => setTimeout(resolve, ms));
  const BLOCK_SAFETY_MARGIN = 1; // 保留1个区块的安全间隔

  let fingerprint = undefined;

  while (true) {
    try {
      // 获取最新区块号
      const latestBlock = await tronWeb.trx.getBlock("latest");
      const latestBlockNumber = latestBlock.block_header.raw_data.number;
      const safeBlockNumber = latestBlockNumber - BLOCK_SAFETY_MARGIN;

      // 如果当前要查询的区块超过了安全区块号，等待新区块产生
      if (startBlockNumber > safeBlockNumber) {
        // console.log(`等待新区块... 当前: ${startBlockNumber}, 安全区块: ${safeBlockNumber}`);
        await sleep(2000);
        continue;
      }

      const events = await tronWeb.event.getEventsByContractAddress(USDT, {
        eventName: "Transfer",
        blockNumber: startBlockNumber,
        limit: 200,
        fingerprint: fingerprint,
      });

      console.log(`Block: ${startBlockNumber}`);

      const fingerprint_new = events?.meta?.fingerprint;

      events.data?.forEach((event) => {
        const txId = event.transaction_id;
        const from = event.result.from;
        const to = event.result.to;
        const value = event.result.value;

        const from_tron = tronWeb.address.fromHex(from);
        const to_tron = tronWeb.address.fromHex(to);

        console.log(
          `${from_tron} -> ${to_tron}: ${tronWeb.fromSun(
            Number(value)
          )} USDT ${txId}`
        );
      });
      console.log("````````````````````````````````````````");

      if (fingerprint_new) {
        fingerprint = fingerprint_new;
        console.log(`fingerprint: ${fingerprint}`);
        await sleep(500);
      } else {
        fingerprint = undefined;

        startBlockNumber++;
      }
    } catch (error) {
      // 404 或其它暂时性错误：等待后重试
      console.error("查询出错:", error);
      await sleep(2000);
      continue;
    }

    await sleep(2000);
  }
}

main().catch(console.error);
