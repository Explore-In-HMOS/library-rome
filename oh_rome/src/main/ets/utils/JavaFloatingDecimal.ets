// Replicates the correctly rounded results of JDK 17 FloatingDecimal (Double.parseDouble, Float.parseFloat).
// Number(string) cannot be used for this: the ArkTS runtime misrounds some decimal strings, e.g.
// Number('0.9999999999999999e0') is 1 there. BigInt arithmetic and Number(bigint) below 2^53 are exact.
// BigInt division is quadratic in the ArkTS runtime, so inputs are first cut to a bounded number of
// significant digits plus a sticky digit, as FloatingDecimal does; no rounding boundary lies in what is cut.

export class BinaryFormat {
  readonly precision: number;
  readonly minExponent: number;
  readonly maxExponent: number;
  // Decimal exponents (value = 0.d1d2... * 10^e) beyond which the result is infinite or zero.
  readonly maxDecimalExponent: number;
  readonly minDecimalExponent: number;
  // FloatingDecimal's MAX_NDIGITS / SINGLE_MAX_NDIGITS.
  readonly maxDigits: number;

  constructor(precision: number, minExponent: number, maxExponent: number, maxDecimalExponent: number,
    minDecimalExponent: number, maxDigits: number) {
    this.precision = precision;
    this.minExponent = minExponent;
    this.maxExponent = maxExponent;
    this.maxDecimalExponent = maxDecimalExponent;
    this.minDecimalExponent = minDecimalExponent;
    this.maxDigits = maxDigits;
  }
}

// Exponents are those of the least significant significand bit.
export const DOUBLE_FORMAT: BinaryFormat = new BinaryFormat(53, -1074, 971, 309, -325, 1100);
export const FLOAT_FORMAT: BinaryFormat = new BinaryFormat(24, -149, 104, 39, -46, 200);

// Significant hex digits kept by roundHex (128 bits, well above any precision), plus a sticky digit.
const MAX_HEX_DIGITS: number = 32;

// s without trailing '0's. A loop, not replace(/0+$/, ''): that regex backtracks quadratically over zero runs.
export function stripTrailingZeros(s: string): string {
  let end = s.length;
  while (end > 0 && s.charCodeAt(end - 1) === 48) {
    end--;
  }
  return s.substring(0, end);
}

function bitLength(value: bigint): number {
  return value.toString(2).length;
}

// The value nearest to numerator * 2^shift / denominator (both positive), ties to even. log2Estimate is
// log2 of that value, give or take a few units.
function roundToBinary(numerator: bigint, denominator: bigint, shift: number, log2Estimate: number,
  format: BinaryFormat): number {
  const top = BigInt(2) ** BigInt(format.precision);
  const half = BigInt(2) ** BigInt(format.precision - 1);
  let exponent = Math.max(Math.floor(log2Estimate) + 1 - format.precision, format.minExponent);
  while (true) {
    const k = shift - exponent;
    const n = k >= 0 ? numerator << BigInt(k) : numerator;
    const d = k >= 0 ? denominator : denominator << BigInt(-k);
    let q = n / d;
    if (q >= top) {
      exponent += bitLength(q) - format.precision;
      continue;
    }
    if (q < half && exponent > format.minExponent) {
      exponent = Math.max(exponent - (q === BigInt(0) ? format.precision : format.precision - bitLength(q)),
        format.minExponent);
      continue;
    }
    const twice = (n % d) * BigInt(2);
    if (twice > d || (twice === d && q % BigInt(2) === BigInt(1))) {
      q += BigInt(1);
    }
    if (q === top) {
      q = half;
      exponent++;
    }
    return exponent > format.maxExponent ? Infinity : Number(q) * Math.pow(2, exponent);
  }
}

// The positive value 0.<digits> * 10^decExponent rounded to the format; digits has no leading zeros.
export function decimalToBinary(digits: string, decExponent: number, format: BinaryFormat): number {
  let significant = stripTrailingZeros(digits);
  if (significant.length === 0 || decExponent < format.minDecimalExponent) {
    return 0;
  }
  if (decExponent > format.maxDecimalExponent) {
    return Infinity;
  }
  if (significant.length > format.maxDigits) {
    significant = significant.substring(0, format.maxDigits) + '1';
  }
  const scale = decExponent - significant.length;
  const mantissa = BigInt(significant);
  const leading = significant.substring(0, 15);
  const log2Estimate = Math.log2(Number(BigInt(leading))) + (decExponent - leading.length) * Math.log2(10);
  return scale >= 0 ? roundToBinary(mantissa * BigInt(10) ** BigInt(scale), BigInt(1), 0, log2Estimate, format) :
    roundToBinary(mantissa, BigInt(10) ** BigInt(-scale), 0, log2Estimate, format);
}

// The positive value 0x<hexDigits> * 2^shift rounded to the format; hexDigits has no leading zeros.
// Infinity and 0 for values far outside the format's range.
export function hexToBinary(hexDigits: string, shift: number, format: BinaryFormat): number {
  let significant = stripTrailingZeros(hexDigits);
  let binaryShift = shift + 4 * (hexDigits.length - significant.length);
  if (significant.length === 0) {
    return 0;
  }
  if (significant.length > MAX_HEX_DIGITS + 1) {
    binaryShift += 4 * (significant.length - MAX_HEX_DIGITS - 1);
    significant = significant.substring(0, MAX_HEX_DIGITS) + '1';
  }
  const bits = 4 * significant.length - (4 - parseInt(significant.charAt(0), 16).toString(2).length) + binaryShift;
  if (bits > format.maxExponent + format.precision + 1) {
    return Infinity;
  }
  if (bits < format.minExponent - 1) {
    return 0;
  }
  return roundToBinary(BigInt('0x' + significant), BigInt(1), binaryShift, bits - 1, format);
}
