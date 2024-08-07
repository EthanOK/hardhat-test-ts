import { parseGwei, stringToHex, toBlobs } from "viem";
import * as cKzg from "c-kzg";
import { setupKzg } from "viem";
import { createWalletClient, Hex, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { mainnet, sepolia } from "viem/chains";
import "dotenv/config";

export const account = privateKeyToAccount(process.env.PrivateKey as Hex);

export const client = createWalletClient({
  account,
  chain: sepolia,
  transport: http(),
});

// console.log(mainnetTrustedSetupPath);
export const path =
  process.cwd() + "/node_modules/viem/trusted-setups/mainnet.json";

export const kzg = setupKzg(cKzg, path);

const blobs = toBlobs({ data: stringToHex("Hi, I'm ETH. Who are you?") });

const sendBlobTx = async () => {
  const tx = await client.sendTransaction({
    blobs,
    kzg,
    maxFeePerBlobGas: parseGwei("300"),
    to: account.address,
    account: account,
    chain: sepolia,
  });
  console.log(tx);
};

sendBlobTx();
