import { BytesLike, getBytes } from "ethers";
import { LibZip } from "./LibZip";
import { LibZipWrapper } from "./LibZipWrapper";

export class GasPriceOracle {
  private isFjord: boolean;
  private isEcotone: boolean;

  constructor() {
    this.isFjord = true;
    this.isEcotone = true;
  }

  /**
   *
   * @param data unsigned Encode RLP
   * @returns L1GasUsed
   */
  getL1GasUsed(data: BytesLike) {
    if (this.isFjord) {
      return getL1GasUsed(data);
    }
  }
}

const COST_INTERCEPT = -42585600n;
const COST_FASTLZ_COEF = 836500n;
const MIN_TRANSACTION_SIZE = 100n;

function getL1GasUsed(unsignedEncodeRLP: BytesLike) {
  const _data = getBytes(unsignedEncodeRLP);
  const fastLzSize =
    LibZipWrapper.flzCompressSync(Buffer.from(_data)).byteLength + 68;
  return (_fjordLinearRegression(BigInt(fastLzSize)) * 16n) / BigInt(1e6);
}

/**
 * Fjord线性回归函数 - 用于估算Brotli压缩后的交易大小
 * @param fastLzSize FastLZ压缩后的交易大小
 * @returns 估算的Brotli压缩后交易大小
 */
function _fjordLinearRegression(fastLzSize: bigint): bigint {
  let estimatedSize = COST_INTERCEPT + COST_FASTLZ_COEF * fastLzSize;

  const minSize = MIN_TRANSACTION_SIZE * 1000000n;
  if (estimatedSize < minSize) {
    estimatedSize = minSize;
  }

  return estimatedSize;
}
