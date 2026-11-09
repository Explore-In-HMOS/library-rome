// Replicates JDK 17 Character.digit(c, 10), Integer.parseInt, Double.toString, new BigDecimal(String) and Currency.getInstance(String).
import { IllegalArgumentException, NumberFormatException } from './Exceptions';

// First character of each block of ten Unicode decimal digits in the BMP, from Character.digit on JDK 17.0.17.
const DIGIT_ZEROS: number[] = [0x0030, 0x0660, 0x06F0, 0x07C0, 0x0966, 0x09E6, 0x0A66, 0x0AE6, 0x0B66, 0x0BE6,
  0x0C66, 0x0CE6, 0x0D66, 0x0DE6, 0x0E50, 0x0ED0, 0x0F20, 0x1040, 0x1090, 0x17E0, 0x1810, 0x1946, 0x19D0, 0x1A80,
  0x1A90, 0x1B50, 0x1BB0, 0x1C40, 0x1C50, 0xA620, 0xA8D0, 0xA900, 0xA9D0, 0xA9F0, 0xAA50, 0xABF0, 0xFF10];

// Currency.getAvailableCurrencies() on JDK 17.0.17.
const CURRENCY_CODES: Set<string> = new Set<string>(('ADP AED AFA AFN ALL AMD ANG AOA ARS ATS AUD AWG AYM AZM AZN ' +
  'BAM BBD BDT BEF BGL BGN BHD BIF BMD BND BOB BOV BRL BSD BTN BWP BYB BYN BYR BZD CAD CDF CHE CHF CHW CLF CLP CNY ' +
  'COP COU CRC CSD CUC CUP CVE CYP CZK DEM DJF DKK DOP DZD EEK EGP ERN ESP ETB EUR FIM FJD FKP FRF GBP GEL GHC GHS ' +
  'GIP GMD GNF GRD GTQ GWP GYD HKD HNL HRK HTG HUF IDR IEP ILS INR IQD IRR ISK ITL JMD JOD JPY KES KGS KHR KMF KPW ' +
  'KRW KWD KYD KZT LAK LBP LKR LRD LSL LTL LUF LVL LYD MAD MDL MGA MGF MKD MMK MNT MOP MRO MRU MTL MUR MVR MWK MXN ' +
  'MXV MYR MZM MZN NAD NGN NIO NLG NOK NPR NZD OMR PAB PEN PGK PHP PKR PLN PTE PYG QAR ROL RON RSD RUB RUR RWF SAR ' +
  'SBD SCR SDD SDG SEK SGD SHP SIT SKK SLE SLL SOS SRD SRG SSP STD STN SVC SYP SZL THB TJS TMM TMT TND TOP TPE TRL ' +
  'TRY TTD TWD TZS UAH UGX USD USN USS UYI UYU UZS VEB VED VEF VES VND VUV WST XAD XAF XAG XAU XBA XBB XBC XBD XCD ' +
  'XCG XDR XFO XFU XOF XPD XPF XPT XSU XTS XUA XXX YER YUM ZAR ZMK ZMW ZWD ZWG ZWL ZWN ZWR').split(' '));

export function javaDigit(c: number): number {
  for (const zero of DIGIT_ZEROS) {
    if (c >= zero && c <= zero + 9) {
      return c - zero;
    }
  }
  return -1;
}

export function parseJavaInt(s: string): number {
  let i = 0;
  let negative = false;
  if (s.length > 0 && (s.charAt(0) === '-' || s.charAt(0) === '+')) {
    negative = s.charAt(0) === '-';
    i++;
  }
  if (i === s.length) {
    throw new NumberFormatException(`For input string: "${s}"`);
  }
  let result = 0;
  for (; i < s.length; i++) {
    const digit = javaDigit(s.charCodeAt(i));
    result = result * 10 + digit;
    if (digit < 0 || result > (negative ? 2147483648 : 2147483647)) {
      throw new NumberFormatException(`For input string: "${s}"`);
    }
  }
  return negative ? 0 - result : result;
}

export function currencyInstance(code: string): string {
  if (code.length !== 3) {
    throw new IllegalArgumentException(`The input currency code: "${code}" must have a length of 3 characters`);
  }
  if (!/^[A-Z]{2}/.test(code)) {
    throw new IllegalArgumentException(`The country code: "${code.substring(0, 2)}" is not a valid ISO 3166 code`);
  }
  if (!CURRENCY_CODES.has(code)) {
    throw new IllegalArgumentException(`The input currency code: "${code}" is not a valid ISO 4217 code`);
  }
  return code;
}

// The unscaled value is kept as decimal digits: BigInt(string) and toString() take seconds on long inputs in ArkTS.
export class BigDecimal {
  private readonly negative: boolean;
  private readonly coefficient: string;
  private readonly scale: number;

  private constructor(negative: boolean, coefficient: string, scale: number) {
    this.negative = negative;
    this.coefficient = coefficient;
    this.scale = scale;
  }

  static parse(s: string): BigDecimal {
    let i = 0;
    if (s.length > 0 && (s.charAt(0) === '-' || s.charAt(0) === '+')) {
      i++;
    }
    const digits: string[] = [];
    let scale = 0;
    let dot = false;
    let found = false;
    for (; i < s.length; i++) {
      const c = s.charAt(i);
      const digit = javaDigit(s.charCodeAt(i));
      if (digit >= 0) {
        if (digit > 0 || digits.length > 0) {
          digits.push(String.fromCharCode(48 + digit));
        }
        scale += dot ? 1 : 0;
        found = true;
      } else if (c === '.' && !dot) {
        dot = true;
      } else if (c === 'e' || c === 'E') {
        scale -= BigDecimal.parseExponent(s.substring(i + 1));
        break;
      } else {
        throw new NumberFormatException(
          `Character ${c} is neither a decimal digit number, decimal point, nor "e" notation exponential mark.`);
      }
    }
    if (!found) {
      throw new NumberFormatException('No digits found.');
    }
    if (scale < -2147483648 || scale > 2147483647) {
      throw new NumberFormatException('Scale out of range.');
    }
    const coefficient = digits.length === 0 ? '0' : digits.join('');
    return new BigDecimal(s.charAt(0) === '-' && coefficient !== '0', coefficient, scale);
  }

  private static parseExponent(s: string): number {
    let digits = s.length > 0 && (s.charAt(0) === '-' || s.charAt(0) === '+') ? s.substring(1) : s;
    if (digits.length === 0) {
      throw new NumberFormatException('No exponent digits.');
    }
    let zeros = 0;
    while (digits.length - zeros > 10 && javaDigit(digits.charCodeAt(zeros)) === 0) {
      zeros++;
    }
    digits = digits.substring(zeros);
    if (digits.length > 10) {
      throw new NumberFormatException('Too many nonzero exponent digits.');
    }
    let exp = 0;
    for (let i = 0; i < digits.length; i++) {
      const digit = javaDigit(digits.charCodeAt(i));
      if (digit < 0) {
        throw new NumberFormatException('Not a digit.');
      }
      exp = exp * 10 + digit;
    }
    const signed = s.charAt(0) === '-' ? -exp : exp;
    if (signed < -2147483648 || signed > 2147483647) {
      throw new NumberFormatException('Exponent overflow.');
    }
    return signed;
  }

  multiplyByPowerOfTen(n: number): BigDecimal {
    return new BigDecimal(this.negative, this.coefficient === '0' ? '0' : this.coefficient + '0'.repeat(n), this.scale);
  }

  // Truncated to 64 bits like Java's long, from the last 64 integer digits since 10^64 is a multiple of 2^64;
  // precision is lost beyond 2^53 when converted to number.
  longValue(): number {
    if (this.coefficient === '0' || this.scale <= -64 || this.coefficient.length <= this.scale) {
      return 0;
    }
    const integer = this.scale <= 0 ? this.coefficient + '0'.repeat(-this.scale) :
      this.coefficient.substring(0, this.coefficient.length - this.scale);
    const low = BigInt(integer.substring(Math.max(0, integer.length - 64)));
    return Number(BigInt.asIntN(64, this.negative ? -low : low));
  }

  toString(): string {
    const coeff = this.coefficient;
    if (this.scale === 0) {
      return (this.negative ? '-' : '') + coeff;
    }
    const adjusted = -this.scale + coeff.length - 1;
    let body: string;
    if (this.scale >= 0 && adjusted >= -6) {
      const pad = this.scale - coeff.length;
      body = pad >= 0 ? '0.' + '0'.repeat(pad) + coeff : coeff.substring(0, -pad) + '.' + coeff.substring(-pad);
    } else {
      body = coeff.charAt(0) + (coeff.length > 1 ? '.' + coeff.substring(1) : '') +
        (adjusted !== 0 ? 'E' + (adjusted > 0 ? '+' : '') + adjusted : '');
    }
    return (this.negative ? '-' : '') + body;
  }
}

// Double.toString as JDK 17's FloatingDecimal.BinaryToASCIIBuffer.dtoa computes it, ints and longs wrapping as in
// Java. JDK 17 is not shortest-digit (JDK 19 is): 2.82879384806159E17 prints as 2.82879384806159008E17.
const INSIGNIFICANT_DIGITS_FOR_POW2: number[] = [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6,
  6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 14, 14, 14, 15, 15, 15,
  15, 16, 16, 16, 17, 17, 17, 18, 18, 18, 19];
// About ceil(log2(5^i)).
const N_5_BITS: number[] = [0, 3, 5, 7, 10, 12, 14, 17, 19, 21, 24, 26, 28, 31, 33, 35, 38, 40, 42, 45, 47, 49, 52,
  54, 56, 59, 61];

function asLong(x: bigint): bigint {
  return BigInt.asIntN(64, x);
}

const ZERO: bigint = BigInt(0);
const TWO: bigint = BigInt(2);
const TEN: bigint = BigInt(10);
const LONG_MAX: bigint = BigInt('9223372036854775807');
const POW5: bigint[] = [];
for (let i = 0; i < 30; i++) {
  POW5.push(BigInt(5) ** BigInt(i));
}

function pow5(n: number): bigint {
  return n < POW5.length ? POW5[n] : BigInt(5) ** BigInt(n);
}

function bits5(n: number): number {
  return n < N_5_BITS.length ? N_5_BITS[n] : n * 3;
}

class Digits {
  digits: number[] = [];
  decExponent: number = 0;
}

// developLongDigits: lvalue's digits without trailing zeros, after rounding off `insignificant` low digits.
function longDigits(lvalue: bigint, insignificant: number): Digits {
  const out = new Digits();
  let value = lvalue;
  if (insignificant !== 0) {
    const pow10 = BigInt(10) ** BigInt(insignificant);
    const residue = value % pow10;
    value = value / pow10;
    if (residue >= pow10 / BigInt(2)) {
      value += BigInt(1);
    }
  }
  const s = value.toString();
  let end = s.length;
  while (s.charCodeAt(end - 1) === 48) {
    end--;
  }
  for (let i = 0; i < end; i++) {
    out.digits.push(s.charCodeAt(i) - 48);
  }
  out.decExponent = insignificant + s.length;
  return out;
}

function estimateDecExp(fractBits: bigint, binExp: number): number {
  const d2 = 1 + Number(fractBits & BigInt('0xfffffffffffff')) / 4503599627370496;
  return Math.floor((d2 - 1.5) * 0.289529654 + 0.176091259 + binExp * 0.301029995663981);
}

function roundup(out: Digits): void {
  let i = out.digits.length - 1;
  while (out.digits[i] === 9 && i > 0) {
    out.digits[i] = 0;
    i--;
  }
  if (out.digits[i] === 9) {
    out.decExponent += 1;
    out.digits[0] = 1;
  } else {
    out.digits[i]++;
  }
}

function dtoa(binExp: number, fractBits: bigint, nSignificantBits: number): Digits {
  const low32 = Number(fractBits & BigInt(0xffffffff));
  const tailZeros = low32 !== 0 ? 31 - Math.clz32(low32 & -low32) :
    63 - Math.clz32(Number(fractBits >> BigInt(32)) & -Number(fractBits >> BigInt(32)));
  const nFractBits = 53 - tailZeros;
  const nTinyBits = Math.max(0, nFractBits - binExp - 1);
  if (binExp <= 62 && binExp >= -21 && nTinyBits === 0) {
    const insignificant = binExp > nSignificantBits && binExp - nSignificantBits - 1 > 1 &&
      binExp - nSignificantBits - 1 < INSIGNIFICANT_DIGITS_FOR_POW2.length ?
      INSIGNIFICANT_DIGITS_FOR_POW2[binExp - nSignificantBits - 1] : 0;
    return longDigits(binExp >= 52 ? fractBits << BigInt(binExp - 52) : fractBits >> BigInt(52 - binExp),
      insignificant);
  }
  let decExp = estimateDecExp(fractBits, binExp);
  const B5 = Math.max(0, -decExp);
  let B2 = B5 + nTinyBits + binExp;
  const S5 = Math.max(0, decExp);
  let S2 = S5 + nTinyBits;
  const M5 = B5;
  let M2 = B2 - nSignificantBits;
  const fract = fractBits >> BigInt(tailZeros);
  B2 -= nFractBits - 1;
  const common2factor = Math.min(B2, S2);
  B2 -= common2factor;
  S2 -= common2factor;
  M2 -= common2factor;
  if (nFractBits === 1) {
    M2 -= 1;
  }
  if (M2 < 0) {
    B2 -= M2;
    S2 -= M2;
    M2 = 0;
  }
  const out = new Digits();
  let low: boolean;
  let high: boolean;
  let lowDigitDifference: number;
  let q: number;
  const Bbits = nFractBits + B2 + bits5(B5);
  const tenSbits = S2 + 1 + bits5(S5 + 1);
  if (Bbits < 32 && tenSbits < 32) {
    let b = Math.imul(Number(fract), Number(pow5(B5))) << B2;
    const s = Number(pow5(S5)) << S2;
    let m = Number(pow5(M5)) << M2;
    const tens = Math.imul(s, 10);
    q = Math.trunc(b / s);
    b = Math.imul(10, b % s);
    m = Math.imul(m, 10);
    low = b < m;
    high = ((b + m) | 0) > tens;
    if (q === 0 && !high) {
      decExp--;
    } else {
      out.digits.push(q);
    }
    if (decExp < -3 || decExp >= 8) {
      high = low = false;
    }
    while (!low && !high) {
      q = Math.trunc(b / s);
      b = Math.imul(10, b % s);
      m = Math.imul(m, 10);
      if (m > 0) {
        low = b < m;
        high = ((b + m) | 0) > tens;
      } else {
        low = true;
        high = true;
      }
      out.digits.push(q);
    }
    lowDigitDifference = ((b << 1) - tens) | 0;
  } else if (Bbits < 64 && tenSbits < 64) {
    // b, s and tens stay below 2^63 (Bbits and tenSbits are their exact bit lengths); only m and b + m can wrap.
    let b = (fract * pow5(B5)) << BigInt(B2);
    const s = pow5(S5) << BigInt(S2);
    let m = (pow5(M5) << BigInt(M2)) * TEN;
    const tens = s * TEN;
    q = Number(b / s);
    b = TEN * (b % s);
    low = b < m;
    high = b + m <= LONG_MAX && b + m > tens;
    if (q === 0 && !high) {
      decExp--;
    } else {
      out.digits.push(q);
    }
    if (decExp < -3 || decExp >= 8) {
      high = low = false;
    }
    while (!low && !high) {
      q = Number(b / s);
      b = TEN * (b % s);
      m = m * TEN;
      if (m > LONG_MAX) {
        m = asLong(m);
      }
      if (m > ZERO) {
        low = b < m;
        high = b + m <= LONG_MAX && b + m > tens;
      } else {
        low = true;
        high = true;
      }
      out.digits.push(q);
    }
    const diff = asLong(asLong(b * TWO) - tens);
    lowDigitDifference = diff > ZERO ? 1 : diff < ZERO ? -1 : 0;
  } else {
    const S = pow5(S5) << BigInt(S2);
    let B = (fract * pow5(B5)) << BigInt(B2);
    let M = pow5(M5 + 1) << BigInt(M2 + 1);
    const tenS = pow5(S5 + 1) << BigInt(S2 + 1);
    q = Number(B / S);
    B = (B % S) * BigInt(10);
    low = B < M;
    high = tenS <= B + M;
    if (q === 0 && !high) {
      decExp--;
    } else {
      out.digits.push(q);
    }
    if (decExp < -3 || decExp >= 8) {
      high = low = false;
    }
    while (!low && !high) {
      q = Number(B / S);
      B = (B % S) * BigInt(10);
      M = M * BigInt(10);
      low = B < M;
      high = tenS <= B + M;
      out.digits.push(q);
    }
    lowDigitDifference = 0;
    if (high && low) {
      const twice = B * BigInt(2);
      lowDigitDifference = twice > tenS ? 1 : twice < tenS ? -1 : 0;
    }
  }
  out.decExponent = decExp + 1;
  if (high) {
    if (low) {
      if (lowDigitDifference === 0) {
        if ((out.digits[out.digits.length - 1] & 1) !== 0) {
          roundup(out);
        }
      } else if (lowDigitDifference > 0) {
        roundup(out);
      }
    } else {
      roundup(out);
    }
  }
  return out;
}

// getChars: plain notation for 1e-3 <= |v| < 1e7, else d.dddE[-]n.
function layout(d: Digits): string {
  const digits = d.digits.map((n: number) => String.fromCharCode(48 + n)).join('');
  const e = d.decExponent;
  if (e > 0 && e < 8) {
    return digits.length <= e ? digits + '0'.repeat(e - digits.length) + '.0' :
      digits.substring(0, e) + '.' + digits.substring(e);
  }
  if (e <= 0 && e > -3) {
    return '0.' + '0'.repeat(-e) + digits;
  }
  return digits.charAt(0) + '.' + (digits.length > 1 ? digits.substring(1) : '0') + 'E' + (e - 1);
}

export function javaDoubleString(v: number): string {
  if (Number.isNaN(v)) {
    return 'NaN';
  }
  if (!Number.isFinite(v)) {
    return v > 0 ? 'Infinity' : '-Infinity';
  }
  if (v === 0) {
    return 1 / v < 0 ? '-0.0' : '0.0';
  }
  const view = new DataView(new ArrayBuffer(8));
  view.setFloat64(0, v);
  const high = view.getUint32(0);
  let binExp = (high >>> 20) & 0x7ff;
  let fractBits = (BigInt(high & 0xfffff) << BigInt(32)) | BigInt(view.getUint32(4));
  let nSignificantBits: number;
  if (binExp === 0) {
    const leadingZeros = 64 - fractBits.toString(2).length;
    const shift = leadingZeros - 11;
    fractBits = fractBits << BigInt(shift);
    binExp = 1 - shift;
    nSignificantBits = 64 - leadingZeros;
  } else {
    fractBits = fractBits | (BigInt(1) << BigInt(52));
    nSignificantBits = 53;
  }
  return (v < 0 ? '-' : '') + layout(dtoa(binExp - 1023, fractBits, nSignificantBits));
}
