import { WebSocket } from "ws";

/**
 * Binance Spot Public WebSocket
 * - 组合流（无需再发 subscribe）：/stream?streams=btcusdt@ticker/ethusdt@ticker
 * - 单连接订阅（需要发 subscribe）：wss://stream.binance.com:9443/ws
 */
const DEFAULT_PUBLIC_URLS = [
//   "wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/ethusdt@ticker",
  "wss://data-stream.binance.vision/stream?streams=btcusdt@ticker/ethusdt@ticker",
] as const;

const publicUrls = process.env.BINANCE_WS_PUBLIC_URL
  ? [process.env.BINANCE_WS_PUBLIC_URL]
  : DEFAULT_PUBLIC_URLS;

type BinanceCombinedStreamMsg<TData> = {
  stream: string;
  data: TData;
};

/** `@ticker` = 24hr ticker 的事件结构（只取常用字段） */
type BinanceTickerEvent = {
  e: "24hrTicker";
  E: number; // event time (ms)
  s: string; // symbol, e.g. BTCUSDT
  c: string; // last price
  o: string; // open price
  h: string; // high price
  l: string; // low price
  v: string; // total traded base asset volume
  q: string; // total traded quote asset volume
  b: string; // best bid price
  B: string; // best bid qty
  a: string; // best ask price
  A: string; // best ask qty
};

function isCombinedStreamMsg(x: unknown): x is BinanceCombinedStreamMsg<unknown> {
  return (
    !!x &&
    typeof x === "object" &&
    typeof (x as { stream?: unknown }).stream === "string" &&
    "data" in (x as { data?: unknown })
  );
}

function isTickerEvent(x: unknown): x is BinanceTickerEvent {
  return (
    !!x &&
    typeof x === "object" &&
    (x as { e?: unknown }).e === "24hrTicker" &&
    typeof (x as { s?: unknown }).s === "string" &&
    typeof (x as { c?: unknown }).c === "string"
  );
}

function parseSubscribeStreams(): string[] {
  // 支持两种写法：
  // - BINANCE_STREAMS=btcusdt@ticker,ethusdt@ticker
  // - BINANCE_STREAMS=btcusdt@ticker/ethusdt@ticker
  const raw = process.env.BINANCE_STREAMS?.trim();
  if (!raw) return ["btcusdt@ticker", "ethusdt@ticker"];
  return raw
    .split(/[,\s/]+/g)
    .map((s) => s.trim())
    .filter(Boolean);
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

  // 组合流：{ stream, data }
  if (isCombinedStreamMsg(msg)) {
    const { stream, data } = msg;
    if (isTickerEvent(data)) {
      const t = data;
      console.log(
        `📈 ${t.s}  stream=${stream}  t=${new Date(t.E).toISOString()}`,
        `\n  last ${t.c}`,
        `\n  bid ${t.b} × ${t.B}  |  ask ${t.a} × ${t.A}`,
        `\n  24h open/low/high ${t.o} / ${t.l} / ${t.h}  volBase=${t.v}  volQuote=${t.q}`,
      );
      return;
    }
    console.log("📩", msg);
    return;
  }

  // 单连接订阅：直接就是事件体（或订阅确认）
  if (isTickerEvent(msg)) {
    const t = msg;
    console.log(
      `📈 ${t.s}  t=${new Date(t.E).toISOString()}`,
      `\n  last ${t.c}`,
      `\n  bid ${t.b} × ${t.B}  |  ask ${t.a} × ${t.A}`,
      `\n  24h open/low/high ${t.o} / ${t.l} / ${t.h}  volBase=${t.v}  volQuote=${t.q}`,
    );
    return;
  }

  console.log("📩", msg);
}

function shouldSendSubscribe(url: string): boolean {
  // 组合流 URL（带 /stream?streams=）通常无需再发 subscribe
  return !/\/stream\?streams=/i.test(url);
}

function connect(urls: readonly string[], index: number): void {
  if (index >= urls.length) {
    console.error(
      "无法在任一地址完成 TLS/WebSocket。多为网络问题：地区限制、DNS/防火墙拦截、需代理/VPN。可设置 BINANCE_WS_PUBLIC_URL 指定端点。",
    );
    return;
  }

  const url = urls[index];
  console.log(`正在连接 ${url} …`);
  const ws = new WebSocket(url);

  ws.once("open", () => {
    console.log("✅ WebSocket connected");

    if (shouldSendSubscribe(url)) {
      const streams = parseSubscribeStreams();
      const payload = {
        method: "SUBSCRIBE",
        params: streams,
        id: 1,
      } as const;
      ws.send(JSON.stringify(payload));
    }

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

// npx ts-node utils/webSocket/binanceTicker.ts
// BINANCE_WS_PUBLIC_URL=wss://... npx ts-node utils/webSocket/binanceTicker.ts
// BINANCE_STREAMS=btcusdt@ticker,ethusdt@ticker npx ts-node utils/webSocket/binanceTicker.ts