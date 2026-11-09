// Ported from ROME rome-utils/src/main/java/com/rometools/utils/Doubles.java (Apache-2.0)
import { Strings } from './Strings';

const DECIMAL_PATTERN: RegExp = /^([+-]?)(?:(NaN)|(Infinity)|(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?[fFdD]?)$/;
const HEX_PATTERN: RegExp = /^([+-]?)0[xX]([0-9a-fA-F]*)(?:\.([0-9a-fA-F]*))?[pP]([+-]?\d+)[fFdD]?$/;
// FloatingDecimal.MAX_NDIGITS: Java keeps this many significant digits and replaces the rest with one '1'.
const MAX_DIGITS = 1100;
// 15 hex digits hold at least 57 significant bits; the digits after them only matter as a sticky bit.
const MAX_HEX_DIGITS = 15;

// BigInt(string) and toString are slow in the ArkTS runtime (1100 digits: ~20 ms; toString(2) of 4700 bits:
// ~100 ms), so bit lengths come from shifts and digits are read 16 at a time.
function bitLength(n: bigint): number {
  let high = 64;
  while (n >> BigInt(high) !== BigInt(0)) {
    high *= 2;
  }
  let low = 0;
  while (high - low > 1) {
    const mid = Math.floor((low + high) / 2);
    if (n >> BigInt(mid) === BigInt(0)) {
      high = mid;
    } else {
      low = mid;
    }
  }
  return high;
}

function parseDigits(digits: string): bigint {
  let n = BigInt(0);
  for (let i = 0; i < digits.length; i += 16) {
    const chunk = digits.substring(i, i + 16);
    n = n * BigInt(10) ** BigInt(chunk.length) + BigInt(chunk);
  }
  return n;
}

function leadingZeros(s: string): number {
  let i = 0;
  while (i < s.length && s.charCodeAt(i) === 48) {
    i++;
  }
  return i;
}

function trailingZeros(s: string): number {
  let i = s.length;
  while (i > 0 && s.charCodeAt(i - 1) === 48) {
    i--;
  }
  return s.length - i;
}

// Signed decimal exponent, clamped to +-1e10: past that every input is already 0 or Infinity.
function exponentOf(s: string): number {
  const digits = s.replace(/^[+-]?0*/, '');
  const value = digits.length > 10 ? 1e10 : Number('0' + digits);
  return s.charAt(0) === '-' ? -value : value;
}

// mantissa * 2^exponent rounded half-even to a double, subnormals included. mantissa > 0.
function scaleToDouble(mantissa: bigint, exponent: number): number {
  const top = bitLength(mantissa) - 1 + exponent;
  if (top > 1023) {
    return Infinity;
  }
  if (top < -1075) {
    return 0;
  }
  const lsb = Math.max(top - 52, -1074);
  const shift = lsb - exponent;
  if (shift <= 0) {
    return Number(mantissa) * Math.pow(2, exponent);
  }
  let kept = mantissa >> BigInt(shift);
  const rest = mantissa - (kept << BigInt(shift));
  const half = BigInt(1) << BigInt(shift - 1);
  if (rest > half || (rest === half && (kept & BigInt(1)) === BigInt(1))) {
    kept += BigInt(1);
  }
  return Number(kept) * Math.pow(2, lsb);
}

// digits * 10^exponent rounded half-even; digits has no leading zero. Number() is not used: the ArkTS runtime
// rounds some inputs wrongly. Negative exponents divide to a quotient of 56+ bits plus a sticky bit, enough for
// scaleToDouble to round once.
function decimalToDouble(digits: string, exponent: number): number {
  const magnitude = digits.length + exponent;
  if (magnitude > 310) {
    return Infinity;
  }
  if (magnitude < -324) {
    return 0;
  }
  const mantissa = parseDigits(digits);
  if (exponent >= 0) {
    return scaleToDouble(mantissa * BigInt(10) ** BigInt(exponent), 0);
  }
  const divisor = BigInt(10) ** BigInt(-exponent);
  const shift = Math.max(0, 56 + bitLength(divisor) - bitLength(mantissa));
  const scaled = mantissa << BigInt(shift);
  const quotient = scaled / divisor;
  const sticky = quotient * divisor === scaled ? BigInt(0) : BigInt(1);
  return scaleToDouble(quotient * BigInt(2) + sticky, -shift - 1);
}

// Java's hex form: 0x<hex digits with one optional point>p<signed decimal exponent>.
function parseHex(match: RegExpExecArray): number | null {
  const fracDigits = match[3] ?? '';
  const all = match[2] + fracDigits;
  if (all.length === 0) {
    return null;
  }
  const start = leadingZeros(all);
  const exponent = exponentOf(match[4]);
  let value: number;
  if (start === all.length) {
    value = 0;
  } else if (Math.abs(exponent) > 2147483647) {
    value = exponent > 0 ? Infinity : 0;
  } else {
    const end = Math.min(all.length, start + MAX_HEX_DIGITS);
    const sticky = /[1-9a-fA-F]/.test(all.substring(end)) ? BigInt(1) : BigInt(0);
    const mantissa = BigInt('0x' + all.substring(start, end)) * BigInt(2) + sticky;
    value = scaleToDouble(mantissa, exponent - 4 * fracDigits.length + 4 * (all.length - end) - 1);
  }
  return match[1] === '-' ? -value : value;
}

function parseDecimal(match: RegExpExecArray): number | null {
  if (match[2] !== undefined) {
    return NaN;
  }
  let value: number;
  if (match[3] !== undefined) {
    value = Infinity;
  } else {
    const fracDigits = match[5] ?? '';
    const all = match[4] + fracDigits;
    if (all.length === 0) {
      return null;
    }
    const start = leadingZeros(all);
    if (start === all.length) {
      value = 0;
    } else {
      const trailing = trailingZeros(all);
      let digits = all.substring(start, all.length - trailing);
      let exponent = (match[6] === undefined ? 0 : exponentOf(match[6])) - fracDigits.length + trailing;
      if (digits.length > MAX_DIGITS) {
        exponent += digits.length - MAX_DIGITS - 1;
        digits = digits.substring(0, MAX_DIGITS) + '1';
      }
      value = decimalToDouble(digits, exponent);
    }
  }
  return match[1] === '-' ? -value : value;
}

export class Doubles {
  // Java Double.parseDouble: Java trim(), ASCII digits only, NaN, Infinity, hex floats, a trailing f/F/d/D.
  static parse(s: string | null): number | null {
    const trimmed = Strings.trim(s);
    if (trimmed === null) {
      return null;
    }
    const hex = HEX_PATTERN.exec(trimmed);
    if (hex !== null) {
      return parseHex(hex);
    }
    const decimal = DECIMAL_PATTERN.exec(trimmed);
    return decimal === null ? null : parseDecimal(decimal);
  }
}
