// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Time.java (Apache-2.0)
import { Doubles } from '../../../utils/Doubles';
import { NumberFormatException } from '../../../utils/Exceptions';
import { javaDigit } from '../../../utils/JavaMath';
import { Strings } from '../../../utils/Strings';

const SECOND = 1000;
const MINUTE = 60 * SECOND;
const HOUR = 60 * MINUTE;
const LONG_MAX = BigInt('9223372036854775807');
const LONG_MIN = BigInt('-9223372036854775808');

// String.split(":"): trailing empty parts are dropped when the input contains a separator.
function splitColons(value: string): string[] {
  const parts = value.split(':');
  if (parts.length > 1) {
    while (parts.length > 0 && parts[parts.length - 1] === '') {
      parts.pop();
    }
  }
  return parts;
}

// Double.parseDouble, with its error messages.
function parseDouble(s: string): number {
  const parsed = Doubles.parse(s);
  if (parsed !== null) {
    return parsed;
  }
  const trimmed = Strings.trimToEmpty(s);
  if (trimmed.length === 0) {
    throw new NumberFormatException('empty String');
  }
  throw new NumberFormatException(
    /^[+-]?\d*\.\d*\./.test(trimmed) ? 'multiple points' : `For input string: "${trimmed}"`);
}

// Java's (long) cast: NaN becomes 0, out-of-range values saturate.
function doubleToLong(d: number): bigint {
  if (Number.isNaN(d)) {
    return BigInt(0);
  }
  if (d >= 2 ** 63) {
    return LONG_MAX;
  }
  return d <= -(2 ** 63) ? LONG_MIN : BigInt(Math.trunc(d));
}

function parseLong(s: string): bigint {
  let i = 0;
  let negative = false;
  if (s.length > 0 && (s.charAt(0) === '-' || s.charAt(0) === '+')) {
    negative = s.charAt(0) === '-';
    i++;
  }
  if (i === s.length) {
    throw new NumberFormatException(`For input string: "${s}"`);
  }
  let result = BigInt(0);
  for (; i < s.length; i++) {
    const digit = javaDigit(s.charCodeAt(i));
    result = result * BigInt(10) + BigInt(digit);
    if (digit < 0 || result > (negative ? -LONG_MIN : LONG_MAX)) {
      throw new NumberFormatException(`For input string: "${s}"`);
    }
  }
  return negative ? -result : result;
}

// en-US NumberFormat with at least two integer digits.
function formatNumber(n: number): string {
  const digits = Math.abs(n).toString().padStart(2, '0').replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  return n < 0 ? '-' + digits : digits;
}

export class Time {
  readonly value: number;

  constructor(milliseconds: number) {
    this.value = milliseconds;
  }

  static parse(value: string): Time {
    const values = splitColons(value);
    let count = values.length - 1;
    if (count < 0) {
      throw new Error('Index -1 out of bounds for length 0');
    }
    let milliseconds = doubleToLong(parseDouble(values[count]) * SECOND);
    count--;
    if (count >= 0) {
      milliseconds += parseLong(values[count]) * BigInt(MINUTE);
      count--;
    }
    if (count >= 0) {
      milliseconds += parseLong(values[count]) * BigInt(HOUR);
    }
    return new Time(Number(BigInt.asIntN(64, milliseconds)));
  }

  toString(): string {
    let value = this.value;
    const hours = Math.trunc(value / HOUR);
    value -= hours * HOUR;
    const minutes = Math.trunc(value / MINUTE);
    value -= minutes * MINUTE;
    const seconds = value / SECOND;
    // Double.toString: whole numbers end in ".0".
    return formatNumber(hours) + ':' + formatNumber(minutes) + ':' +
      (Number.isInteger(seconds) ? seconds + '.0' : String(seconds));
  }
}
