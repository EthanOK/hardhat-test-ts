import { BytesLike, getBytes } from "ethers";
import { LibZipWrapper } from "./LibZipWrapper";

const DECIMALS = 6n;

// https://docs.optimism.io/stack/transactions/fees?utm_source=chatgpt.com#l1-data-fee
export class GasPriceOracle {
  private isFjord: boolean;
  // private isEcotone: boolean;
  private baseFee: bigint;
  private blobBaseFee: bigint;
  private baseFeeScalar: bigint;
  private blobBaseFeeScalar: bigint;

  constructor(l1FeeConfig: {
    baseFee: bigint;
    blobBaseFee: bigint;
    baseFeeScalar: bigint;
    blobBaseFeeScalar: bigint;
  }) {
    this.isFjord = true;
    // this.isEcotone = true;
    this.baseFee = l1FeeConfig.baseFee;
    this.blobBaseFee = l1FeeConfig.blobBaseFee;
    this.baseFeeScalar = l1FeeConfig.baseFeeScalar;
    this.blobBaseFeeScalar = l1FeeConfig.blobBaseFeeScalar;
  }

  /**
   *
   * @param data unsigned Encode RLP
   * @returns L1GasUsed
   */
  getL1GasUsed(data: BytesLike): bigint {
    if (this.isFjord) {
      return this._getL1GasUsed(data);
    }
  }
  /**
   *
   * @param data unsigned Encode RLP
   * @returns L1Fee
   */
  getL1Fee(data: BytesLike): bigint {
    if (this.isFjord) {
      return this.getL1FeeFjord(data);
    }
  }

  private _getL1GasUsed(unsignedEncodeRLP: BytesLike) {
    const _data = getBytes(unsignedEncodeRLP);
    const fastLzSize =
      LibZipWrapper.flzCompressSync(Buffer.from(_data)).byteLength + 68;
    return (_fjordLinearRegression(BigInt(fastLzSize)) * 16n) / BigInt(1e6);
  }

  private getL1FeeFjord(unsignedEncodeRLP: BytesLike) {
    const _data = getBytes(unsignedEncodeRLP);
    const fastLzSize =
      LibZipWrapper.flzCompressSync(Buffer.from(_data)).byteLength + 68;

    return this._fjordL1Cost(BigInt(fastLzSize));
  }

  private _fjordL1Cost(fastLzSize: bigint) {
    const estimatedSizeScaled = _fjordLinearRegression(fastLzSize);

    const feeScaled =
      this.baseFeeScalar * this.baseFee * 16n +
      this.blobBaseFeeScalar * this.blobBaseFee;
    return (estimatedSizeScaled * feeScaled) / 10n ** (DECIMALS * 2n);
  }
}

const COST_INTERCEPT = -42585600n;
const COST_FASTLZ_COEF = 836500n;
const MIN_TRANSACTION_SIZE = 100n;

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
