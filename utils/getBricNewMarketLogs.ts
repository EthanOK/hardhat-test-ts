import { AlchemyProvider, ethers, JsonRpcProvider } from "ethers";

const provider = new JsonRpcProvider("https://eth-hoodi.g.alchemy.com/v2/9Rw45aN66cOhfEvSSvzueA4q4_68jDeJ");

const CONTRACT = "0xc7e1160fa95543d77bf92489e29898130ef1ca80";

const abi = [
  "event CreateNewMarket(address indexed market, address indexed PT, int256 scalarRoot, int256 initialAnchor, uint256 lnFeeRateRoot)",
];

const iface = new ethers.Interface(abi);

async function run() {
  const event = iface.getEvent("CreateNewMarket");

  const filter = {
    address: CONTRACT,
    topics: [event.topicHash],
    fromBlock: 1786759,
    toBlock: 1786765,
  };

  const logs = await provider.getLogs(filter);

  for (const log of logs) {
    const parsed = iface.parseLog(log);
    // console.log("PT:", parsed.args.PT);
    console.log("market:", parsed.args.market);
  }
}

run();
