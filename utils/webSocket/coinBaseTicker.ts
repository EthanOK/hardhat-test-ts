import { WebSocket } from "ws";

/** Coinbase Exchange WebSocket（公开行情） */
const DEFAULT_PUBLIC_URLS = [
  "wss://advanced-trade-ws.coinbase.com",
  "wss://ws-feed.exchange.coinbase.com",
] as const;

const publicUrls = process.env.COINBASE_WS_URL
  ? [process.env.COINBASE_WS_URL]
  : DEFAULT_PUBLIC_URLS;

const SUBSCRIBE = {
  "type": "subscribe",
  "product_ids": ["ETH-USD", "BTC-USD"],
  "channel": "ticker"
} as const;

/** Coinbase Exchange `ticker` 频道推送结构（与 ws-feed 实际一致） */
type CoinbaseTickerPayload = {
  type: "ticker";
  sequence: number;
  product_id: string;
  price: string;
  open_24h: string;
  volume_24h: string;
  low_24h: string;
  high_24h: string;
  volume_30d: string;
  best_bid: string;
  best_bid_size: string;
  best_ask: string;
  best_ask_size: string;
  side: string;
  time: string;
  trade_id: number;
  last_size: string;
};

function isTickerPayload(x: unknown): x is CoinbaseTickerPayload {
  return (
    !!x &&
    typeof x === "object" &&
    (x as { type?: unknown }).type === "ticker" &&
    typeof (x as { product_id?: unknown }).product_id === "string"
  );
}

function msgType(msg: unknown): string | undefined {
  if (msg && typeof msg === "object" && "type" in msg) {
    const t = (msg as { type: unknown }).type;
    return typeof t === "string" ? t : undefined;
  }
  return undefined;
}

function onMessage(data: WebSocket.RawData) {
  const raw = data.toString();
  let msg: unknown;
  try {
    msg = JSON.parse(raw);
  } catch {
    console.error("❌ invalid JSON:", raw.slice(0, 200));
    return;
  }

  if (isTickerPayload(msg)) {
    const m = msg;
    console.log(
      `📈 ${m.product_id}  seq=${m.sequence}  ${m.time}`,
      `\n  last ${m.price}  side=${m.side}  size=${m.last_size}  trade_id=${m.trade_id}`,
      `\n  bid ${m.best_bid} × ${m.best_bid_size}  |  ask ${m.best_ask} × ${m.best_ask_size}`,
      `\n  24h open/low/high ${m.open_24h} / ${m.low_24h} / ${m.high_24h}  vol24=${m.volume_24h}  vol30d=${m.volume_30d}`,
    );
    return;
  }

  const t = msgType(msg);
  if (t === "heartbeat") {
    console.log("💓 heartbeat", msg);
  } else if (t === "subscriptions" || t === "error") {
    console.log("📋", msg);
  } else {
    console.log("📩", msg);
  }
}

function connect(urls: readonly string[], index: number): void {
  if (index >= urls.length) {
    console.error(
      "无法在任一地址完成连接。多为网络问题，可设置 COINBASE_WS_URL 指定端点。",
    );
    return;
  }

  const url = urls[index];
  console.log(`正在连接 ${url} …`);
  const ws = new WebSocket(url);

  ws.once("open", () => {
    console.log("✅ WebSocket connected");
    ws.send(JSON.stringify(SUBSCRIBE));
    ws.on("message", onMessage);
    ws.on("error", (err) => {
      console.error("❌ WebSocket error:", err);
    });
    ws.on("close", () => {
      console.log("🔌 WebSocket closed");
    });
  });

  ws.once("error", (err) => {
    console.error(`❌ ${url}`, err);
    connect(urls, index + 1);
  });
}

connect(publicUrls, 0);

// npx ts-node utils/webSocket/coinBaseTicker.ts
// COINBASE_WS_URL=wss://... npx ts-node utils/webSocket/coinBaseTicker.ts
