import { Address, encodePacked, Hex, hexToBigInt } from "viem";

export function getUniqueId(account: Address, nonce: number): string {
  // abi.encodePacked(account, nonce)
  const data = encodePacked(["address", "uint96"], [account, BigInt(nonce)]);
  // bytes => uint256
  const id = hexToBigInt(data).toString();

  console.log(id);

  return id;
}

getUniqueId("0x5b38da6a701c568545dcfcb03fcb875f56beddc4", 10000);
