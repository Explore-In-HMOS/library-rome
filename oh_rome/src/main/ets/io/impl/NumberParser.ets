// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/NumberParser.java (Apache-2.0)
import { decimalToBinary, FLOAT_FORMAT, hexToBinary, stripTrailingZeros } from '../../utils/JavaFloatingDecimal';
import { javaDigit } from '../../utils/JavaMath';
import { Strings } from '../../utils/Strings';

const DECIMAL_FLOAT_PATTERN: RegExp = /^([+-]?)(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?[fFdD]?$/;
const HEX_FLOAT_PATTERN: RegExp =
  /^([+-]?)0[xX](?:([0-9a-fA-F]+)\.?|([0-9a-fA-F]*)\.([0-9a-fA-F]+))[pP]([+-]?)(\d+)[fFdD]?$/;
const SPECIAL_FLOAT_PATTERN: RegExp = /^([+-]?)(NaN|Infinity)$/;

// Long.parseLong/Integer.parseInt: optional sign, then Character.digit digits; null when out of range.
function parseInteger(s: string, maxDigits: string, minDigits: string): number | null {
  let i = 0;
  const negative = s.charAt(0) === '-';
  if (negative || s.charAt(0) === '+') {
    i++;
  }
  if (i === s.length) {
    return null;
  }
  const chars: string[] = [];
  for (; i < s.length; i++) {
    const c = s.charCodeAt(i);
    const digit = c >= 48 && c <= 57 ? c - 48 : javaDigit(c);
    if (digit < 0) {
      return null;
    }
    if (digit > 0 || chars.length > 0) {
      chars.push(String.fromCharCode(48 + digit));
    }
  }
  const digits = chars.join('');
  const limit = negative ? minDigits : maxDigits;
  if (digits.length > limit.length || (digits.length === limit.length && digits > limit)) {
    return null;
  }
  const value = digits.length === 0 ? 0 : Number(BigInt(digits));
  return negative ? -value || 0 : value;
}

function signed(negative: boolean, value: number): number {
  return negative ? -value : value;
}

// The decimal branch of FloatingDecimal.readJavaFormatString and floatValue().
function parseDecimalFloat(match: RegExpExecArray): number | null {
  const intPart = match[2];
  const fracPart = match[3] ?? '';
  if (intPart.length + fracPart.length === 0) {
    return null;
  }
  const negative = match[1] === '-';
  const all = (intPart + fracPart).replace(/^0+/, '');
  const digits = stripTrailingZeros(all);
  if (digits.length === 0) {
    return signed(negative, 0);
  }
  // FloatingDecimal reads the exponent digit by digit and only treats it as huge once it has 10 significant
  // digits, so leading zeros never overflow it.
  const exponentText = match[4] ?? '0';
  const exponentDigits = exponentText.replace(/^[+-]/, '').replace(/^0+(?=\d)/, '');
  const exponentMagnitude = exponentDigits.length > 10 ? 1e10 : Number(BigInt(exponentDigits));
  const exponent = exponentText.charAt(0) === '-' ? -exponentMagnitude : exponentMagnitude;
  return signed(negative, decimalToBinary(all, all.length - fracPart.length + exponent, FLOAT_FORMAT));
}

// FloatingDecimal.parseHexString, rounded to float.
function parseHexFloat(match: RegExpExecArray): number {
  const negative = match[1] === '-';
  const intPart = match[2] ?? (match[3] ?? '');
  const fracPart = match[2] !== undefined ? '' : match[4];
  const significant = (intPart + fracPart).replace(/^0+/, '');
  if (significant.length === 0) {
    return signed(negative, 0);
  }
  const positiveExponent = match[5] !== '-';
  const exponentDigits = match[6].replace(/^0+(?=\d)/, '');
  if (exponentDigits.length > 10 || Number(BigInt(exponentDigits)) > 2147483647) {
    return signed(negative, positiveExponent ? Infinity : 0);
  }
  const shift = (positiveExponent ? 1 : -1) * Number(BigInt(exponentDigits)) - 4 * fracPart.length;
  return signed(negative, hexToBinary(significant, shift, FLOAT_FORMAT));
}

// Float.parseFloat on an already trimmed string; null where Java throws NumberFormatException.
function parseJavaFloat(s: string): number | null {
  const special = SPECIAL_FLOAT_PATTERN.exec(s);
  if (special !== null) {
    return special[2] === 'NaN' ? NaN : signed(special[1] === '-', Infinity);
  }
  const hex = HEX_FLOAT_PATTERN.exec(s);
  if (hex !== null) {
    return parseHexFloat(hex);
  }
  const decimal = DECIMAL_FLOAT_PATTERN.exec(s);
  return decimal === null ? null : parseDecimalFloat(decimal);
}

export class NumberParser {
  static parseLong(str: string | null): number | null {
    return str === null ? null : parseInteger(Strings.trim(str)!, '9223372036854775807', '9223372036854775808');
  }

  static parseInt(str: string | null): number | null {
    return str === null ? null : parseInteger(Strings.trim(str)!, '2147483647', '2147483648');
  }

  static parseFloat(str: string | null): number | null {
    return str === null ? null : parseJavaFloat(Strings.trim(str)!);
  }

  // Java's parseFloat(String, float).
  static parseFloatWithDefault(str: string | null, def: number): number {
    const result = NumberParser.parseFloat(str);
    return result === null ? def : result;
  }

  // Java's parseLong(String, long).
  static parseLongWithDefault(str: string | null, def: number): number {
    const result = NumberParser.parseLong(str);
    return result === null ? def : result;
  }
}
