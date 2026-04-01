import { WebSocket } from "ws";

/** 与 OKX 文档一致：主域与 wsaws 互为备用 */
const DEFAULT_PUBLIC_URLS = ["wss://ws.okx.com/ws/v5/public"] as const;

const publicUrls = process.env.OKX_WS_PUBLIC_URL
  ? [process.env.OKX_WS_PUBLIC_URL]
  : DEFAULT_PUBLIC_URLS;

/** 连接成功后发送的 subscribe，只改这里即可增删频道/交易对 */
const okxPublicSubscribePayload = {
  id: "1512",
  op: "subscribe",
  args: [
    { channel: "tickers", instId: "BTC-USD" },
    { channel: "tickers", instId: "BTC-USDT" },
  ],
} as const;

function onMessage(data: WebSocket.RawData) {
  const raw = data.toString();
  let msg: {
    arg?: { channel?: string };
    data?: { last?: string; bidPx?: string; askPx?: string }[];
  };
  try {
    msg = JSON.parse(raw);
  } catch {
    console.error("❌ invalid JSON:", raw.slice(0, 200));
    return;
  }

  const arg = msg.arg;
  const rows = msg.data;
  if (arg?.channel === "tickers" && Array.isArray(rows) && rows.length > 0) {
    console.log("📈 length:", rows.length);
    for (const ticker of rows) {
      console.log(JSON.stringify(ticker));
    }
  } else {
    console.log("📩", msg);
  }
}

function connect(urls: readonly string[], index: number): void {
  if (index >= urls.length) {
    console.error(
      "无法在任一地址完成 TLS/WebSocket。多为网络问题：防火墙拦截 8443、地区限制、需代理/VPN。可设置 OKX_WS_PUBLIC_URL 指定端点。",
    );
    return;
  }

  const url = urls[index];
  console.log(`正在连接 ${url} …`);
  const ws = new WebSocket(url);

  ws.once("open", () => {
    console.log("✅ WebSocket connected");
    ws.send(JSON.stringify(okxPublicSubscribePayload));
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

// npx ts-node utils/webSocket/okxTicker.ts
// OKX_WS_PUBLIC_URL=wss://... npx ts-node utils/webSocket/okxTicker.ts
