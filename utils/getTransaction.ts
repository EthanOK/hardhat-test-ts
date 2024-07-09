import { createPublicClient, hexToString, http } from "viem";
import { mainnet, sepolia } from "viem/chains";

export const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
});
async function main() {
  const transaction = await publicClient.getTransaction({
    hash: "0x1771559f836c4a20fb3d80a8a8c4ada7146bdbf154b5f5c43e6ba555b577ecae",
  });

  console.log(transaction);
  if (transaction.blobVersionedHashes.length > 0) {
    // http get请求
    let response = await fetch(
      `https://api.blobscan.com/blobs/${transaction.blobVersionedHashes[0]}`
    );
    if (response.ok) {
      let data = await response.json();
      console.log(hexToString(data.data));
    } else {
      console.log("HTTP-Error: " + response.status);
    }
  }
}

main().catch((error) => {
  console.error(error);
});
