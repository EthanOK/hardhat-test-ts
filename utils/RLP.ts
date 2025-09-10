// Unsigned fully RLP-encoded transaction_ to get the L1 gas for.

import { BigNumberish, encodeRlp, getBytes, Transaction } from "ethers";
export class RLP {
  static encodeTransaction(transaction: {
    to: string;
    value: BigNumberish;
    data: string;
    type: number;
    gasLimit: BigNumberish;
    gasPrice?: BigNumberish;
    nonce: BigNumberish;
    chainId: BigNumberish;
  }) {
    const transaction_ = new Transaction();

    transaction_.nonce = transaction.nonce;
    transaction_.type = transaction.type;
    transaction_.to = transaction.to;
    transaction_.data = transaction.data;
    transaction_.chainId = transaction.chainId;
    transaction_.value = transaction.value;
    transaction_.gasLimit = transaction.gasLimit;
    transaction_.gasPrice = transaction.gasPrice;

    const unsignedSerialized = transaction_.unsignedSerialized;
    const unsignedEncodeRLP = encodeRlp(unsignedSerialized);
    return unsignedEncodeRLP;
  }
}
