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

  const currentBlock = await tronWeb.trx.getBlock(78290838);

  let startTimestamp = currentBlock.block_header.raw_data.timestamp;

  let endTimestamp = new Date().getTime();

  const sleep = (ms: number) =>
    new Promise((resolve) => setTimeout(resolve, ms));

  let fingerprint = undefined;
  // 避免接口分页时返回上一页的尾部数据，记录已处理过的事件指纹
  const processed = new Set<string>();

  let nextStartTimestamp;

  while (true) {
    do {
      const events = await tronWeb.event.getEventsByContractAddress(USDT, {
        eventName: "Transfer",
        minBlockTimestamp: startTimestamp,
        maxBlockTimestamp: endTimestamp,
        limit: 200,
        fingerprint: fingerprint,
        orderBy: "block_timestamp,asc",
      });

      fingerprint = events?.meta?.fingerprint;

      let eventCount = events.data?.length;

      if (eventCount > 0) {
        nextStartTimestamp = events.data?.[eventCount - 1].block_timestamp;
      }

      events.data?.forEach((event) => {
        const block_number = event.block_number;
        const txId = event.transaction_id;
        const eventIndex = event.event_index;

        const key = `${block_number}-${txId}-${eventIndex}`;
        if (processed.has(key)) {
          return;
        }
        processed.add(key);

        console.log(`${block_number} -> ${txId} -> ${eventIndex}`);
      });

      console.log(`eventCount: ${eventCount}, fingerprint: ${fingerprint}`);
    } while (fingerprint);

    if (nextStartTimestamp) {
      startTimestamp = nextStartTimestamp + 1;
      endTimestamp = new Date().getTime();
    }

    // 新一轮查询重置分页状态
    fingerprint = undefined;

    await sleep(1000);
  }
}

main().catch(console.error);
