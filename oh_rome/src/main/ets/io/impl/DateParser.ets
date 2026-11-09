// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/DateParser.java (Apache-2.0)
import { IllegalArgumentException } from '../../utils/Exceptions';
import { decimalToBinary, DOUBLE_FORMAT, stripTrailingZeros } from '../../utils/JavaFloatingDecimal';
import { javaDigit } from '../../utils/JavaMath';
import { Strings } from '../../utils/Strings';
import { ZONE_NAMES } from './DateParserZoneNames';

// ROME parses with lenient java.text.SimpleDateFormat (Locale.US, Temurin 17.0.17+10 CLDR data). This file
// emulates the parts of it that ROME's masks and datetime.extra.masks can reach: the pattern compiler, the
// field parsers, DecimalFormat's number parsing and GregorianCalendar's lenient field resolution, including
// the Julian calendar before 1582-10-15.

const RFC822_MASKS: string[] = ['EEE, dd MMM yy HH:mm:ss z', 'EEE, dd MMM yy HH:mm z', 'dd MMM yy HH:mm:ss z',
  'dd MMM yy HH:mm z'];

const W3CDATETIME_MASKS: string[] = ['yyyy-MM-dd\'T\'HH:mm:ss.SSSz', 'yyyy-MM-dd\'t\'HH:mm:ss.SSSz',
  'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'', 'yyyy-MM-dd\'t\'HH:mm:ss.SSS\'z\'', 'yyyy-MM-dd\'T\'HH:mm:ssz',
  'yyyy-MM-dd\'t\'HH:mm:ssz', 'yyyy-MM-dd\'T\'HH:mm:ssZ', 'yyyy-MM-dd\'t\'HH:mm:ssZ', 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'',
  'yyyy-MM-dd\'t\'HH:mm:ss\'z\'', 'yyyy-MM-dd\'T\'HH:mmz', 'yyyy-MM\'T\'HH:mmz', 'yyyy\'T\'HH:mmz',
  'yyyy-MM-dd\'t\'HH:mmz', 'yyyy-MM-dd\'T\'HH:mm\'Z\'', 'yyyy-MM-dd\'t\'HH:mm\'z\'', 'yyyy-MM-dd', 'yyyy-MM', 'yyyy'];

const MONTHS: string[] = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
  'October', 'November', 'December'];
const SHORT_MONTHS: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
// Index 0 is unused: Calendar.SUNDAY is 1.
const WEEKDAYS: string[] = ['', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const SHORT_WEEKDAYS: string[] = ['', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const AM_PM_NAMES: string[] = ['AM', 'PM'];

const PATTERN_CHARS: string = 'GyMdkHmsSEDFwWahKzZYuXL';
const SUPPORTED_PATTERN_CHARS: string = 'yMLdkHmsSEDahKzZ';
const OBEY_COUNT_CHARS: string = 'ydkHmsSDFwWhKYu';

const YEAR: number = 0;
const MONTH: number = 1;
const DAY_OF_MONTH: number = 2;
const DAY_OF_YEAR: number = 3;
const DAY_OF_WEEK: number = 4;
const AM_PM: number = 5;
const HOUR: number = 6;
const HOUR_OF_DAY: number = 7;
const MINUTE: number = 8;
const SECOND: number = 9;
const MILLISECOND: number = 10;
const ZONE_OFFSET: number = 11;
const DST_OFFSET: number = 12;
const FIELD_COUNT: number = 13;

const ONE_DAY: number = 86400000;
const EPOCH_OFFSET: number = 719163;
const GREGORIAN_CUTOVER_FIXED_DATE: number = 577736;
const GREGORIAN_CUTOVER_MILLIS: number = -12219292800000;
const MAX_DATE_MILLIS: number = 8640000000000000;
const INT_MAX: number = 2147483647;
const INT_MIN: number = -2147483648;

class ZoneName {
  readonly name: string;
  readonly rawOffset: number;
  readonly dstOffset: number | null;

  constructor(name: string, rawOffset: number, dstOffset: number | null) {
    this.name = name;
    this.rawOffset = rawOffset;
    this.dstOffset = dstOffset;
  }
}

class MaskToken {
  // '' for a literal character.
  readonly letter: string;
  readonly count: number;
  readonly literal: string;

  constructor(letter: string, count: number, literal: string) {
    this.letter = letter;
    this.count = count;
    this.literal = literal;
  }
}

class ParsedNumber {
  readonly value: number;
  readonly end: number;

  constructor(value: number, end: number) {
    this.value = value;
    this.end = end;
  }
}

class CalendarFields {
  readonly values: number[] = new Array<number>(FIELD_COUNT).fill(0);
  readonly stamps: number[] = new Array<number>(FIELD_COUNT).fill(0);
  private nextStamp: number = 1;
  // Raw offset of a zone matched by name, in ms; null means the default zone.
  zoneRaw: number | null = null;
  ambiguousYear: boolean = false;

  set(field: number, value: number): void {
    this.values[field] = value;
    this.stamps[field] = this.nextStamp++;
  }

  clear(field: number): void {
    this.values[field] = 0;
    this.stamps[field] = 0;
  }

  isSet(field: number): boolean {
    return this.stamps[field] > 0;
  }
}

class CenturyStart {
  readonly year: number;
  readonly millis: number;

  constructor(year: number, millis: number) {
    this.year = year;
    this.millis = millis;
  }
}

class CalendarDate {
  readonly year: number;
  readonly month: number;
  readonly day: number;

  constructor(year: number, month: number, day: number) {
    this.year = year;
    this.month = month;
    this.day = day;
  }
}

let zoneNames: ZoneName[] | null = null;
const compiledMasks: Map<string, MaskToken[]> = new Map<string, MaskToken[]>();

function getZoneNames(): ZoneName[] {
  if (zoneNames === null) {
    const names: ZoneName[] = [];
    for (const entry of ZONE_NAMES.split(';')) {
      const parts = entry.split(',');
      names.push(new ZoneName(parts[0], Number(parts[1]) * 60000, parts[2] === '*' ? null : Number(parts[2]) * 60000));
    }
    zoneNames = names;
  }
  return zoneNames;
}

function floorDiv(a: number, b: number): number {
  return Math.floor(a / b);
}

function mod(a: number, b: number): number {
  return a - Math.floor(a / b) * b;
}

function isAsciiDigit(c: string): boolean {
  return c >= '0' && c <= '9';
}

function charsEqualIgnoreCase(a: string, b: string): boolean {
  return a === b || a.toUpperCase() === b.toUpperCase() || a.toLowerCase() === b.toLowerCase();
}

// Java String.regionMatches(true, offset, other, 0, other.length()).
function regionMatchesIgnoreCase(text: string, offset: number, other: string): boolean {
  if (offset < 0 || offset + other.length > text.length) {
    return false;
  }
  for (let i = 0; i < other.length; i++) {
    if (!charsEqualIgnoreCase(text.charAt(offset + i), other.charAt(i))) {
      return false;
    }
  }
  return true;
}

// Java (int) cast of a double.
function doubleToInt(value: number): number {
  if (Number.isNaN(value)) {
    return 0;
  }
  if (value >= INT_MAX) {
    return INT_MAX;
  }
  if (value <= INT_MIN) {
    return INT_MIN;
  }
  return Math.trunc(value);
}

const LONG_MIN_DIGITS: string = '9223372036854775808';

// DigitList.fitsIntoLong(isPositive, true) for significant digits (no leading or trailing zeros).
function fitsIntoLong(digits: string, decimalAt: number, negative: boolean): boolean {
  if (digits.length === 0) {
    return true;
  }
  if (decimalAt < digits.length || decimalAt > 19) {
    return false;
  }
  if (decimalAt < 19) {
    return true;
  }
  for (let i = 0; i < digits.length; i++) {
    if (digits.charAt(i) > LONG_MIN_DIGITS.charAt(i)) {
      return false;
    }
    if (digits.charAt(i) < LONG_MIN_DIGITS.charAt(i)) {
      return true;
    }
  }
  return digits.length < decimalAt || negative;
}

// DigitList.getLong(), signed, as a BigInt.
function digitsToLong(digits: string, decimalAt: number, negative: boolean): bigint {
  const value = digits.length === 0 ? BigInt(0) : BigInt(digits) * BigInt(10) ** BigInt(decimalAt - digits.length);
  return negative ? -value : value;
}

// Number.intValue() of what DecimalFormat.parse returns: a Long when DigitList.fitsIntoLong, else the Double
// DigitList.getDouble parses from ".<digits>E<decimalAt>".
function decimalToInt(significant: string, decimalAt: number, negative: boolean): number {
  const digits = stripTrailingZeros(significant);
  if (fitsIntoLong(digits, decimalAt, negative)) {
    return Number(BigInt.asIntN(32, digitsToLong(digits, decimalAt, negative)));
  }
  if (decimalAt > 10) {
    return negative ? INT_MIN : INT_MAX;
  }
  const value = decimalToBinary(digits, decimalAt, DOUBLE_FORMAT);
  return doubleToInt(negative ? -value : value);
}

class ParsedDigits {
  readonly digits: string;
  readonly digitCount: number;
  readonly sawDigit: boolean;
  readonly end: number;

  constructor(digits: string, digitCount: number, sawDigit: boolean, end: number) {
    this.digits = digits;
    this.digitCount = digitCount;
    this.sawDigit = sawDigit;
    this.end = end;
  }
}

// The digit loop of DecimalFormat.subparseNumber: Character.digit digits, leading zeros dropped.
function scanDigits(text: string, start: number, limit: number): ParsedDigits {
  let i = start;
  let first = -1;
  while (i < limit) {
    const c = text.charCodeAt(i);
    if (c < 48 || c > 57) {
      break;
    }
    if (first < 0 && c !== 48) {
      first = i;
    }
    i++;
  }
  if (i >= limit || javaDigit(text.charCodeAt(i)) < 0) {
    const digits = first < 0 ? '' : text.substring(first, i);
    return new ParsedDigits(digits, digits.length, i > start, i);
  }
  const chars: string[] = [];
  let sawDigit = false;
  i = start;
  while (i < limit) {
    const digit = javaDigit(text.charCodeAt(i));
    if (digit < 0) {
      break;
    }
    sawDigit = true;
    if (digit > 0 || chars.length > 0) {
      chars.push(String.fromCharCode(48 + digit));
    }
    i++;
  }
  return new ParsedDigits(chars.join(''), chars.length, sawDigit, i);
}

// DecimalFormat.parse for the US locale with parseIntegerOnly and no grouping, then intValue(). The
// exponent is read as a long, cast to int and added to decimalAt with int overflow, as in subparseNumber.
function parseNumber(text: string, start: number, limit: number): ParsedNumber | null {
  let i = start;
  if (start + 3 <= limit && text.startsWith('NaN', start)) {
    return new ParsedNumber(0, start + 3);
  }
  let negative = false;
  if (i < limit && text.charAt(i) === '-') {
    negative = true;
    i++;
  }
  if (i < limit && text.charAt(i) === '\u221e') {
    return new ParsedNumber(negative ? INT_MIN : INT_MAX, i + 1);
  }
  const mantissa = scanDigits(text, i, limit);
  i = mantissa.end;
  let exponent = 0;
  if (i < limit && text.charAt(i) === 'E') {
    let j = i + 1;
    const exponentNegative = j < limit && text.charAt(j) === '-';
    if (exponentNegative) {
      j++;
    }
    const e = scanDigits(text, j, limit);
    const significant = stripTrailingZeros(e.digits);
    if (e.sawDigit && fitsIntoLong(significant, e.digitCount, exponentNegative)) {
      exponent = Number(BigInt.asIntN(32, digitsToLong(significant, e.digitCount, false)));
      if (exponentNegative) {
        exponent = -exponent | 0;
      }
      i = e.end;
    }
  }
  if (!mantissa.sawDigit && mantissa.digitCount === 0) {
    return null;
  }
  return new ParsedNumber(decimalToInt(mantissa.digits, (mantissa.digitCount + exponent) | 0, negative), i);
}

// Fixed dates count days from 0001-01-01 (proleptic Gregorian) = 1, years are astronomical (0 = 1 BCE).
function gregorianFixedDate(year: number, month: number, day: number): number {
  const prev = year - 1;
  let days = 365 * prev + floorDiv(prev, 4) - floorDiv(prev, 100) + floorDiv(prev, 400) +
    floorDiv(367 * month - 362, 12) + day;
  if (month > 2) {
    const leap = mod(year, 4) === 0 && (mod(year, 100) !== 0 || mod(year, 400) === 0);
    days -= leap ? 1 : 2;
  }
  return days;
}

function julianFixedDate(year: number, month: number, day: number): number {
  let days = -2 + 365 * (year - 1) + floorDiv(year - 1, 4) + floorDiv(367 * month - 362, 12) + day;
  if (month > 2) {
    days -= mod(year, 4) === 0 ? 1 : 2;
  }
  return days;
}

function julianDateFromFixed(fixedDate: number): CalendarDate {
  const year = floorDiv(4 * (fixedDate + 1) + 1464, 1461);
  const priorDays = fixedDate - julianFixedDate(year, 1, 1);
  const correction = fixedDate < julianFixedDate(year, 3, 1) ? 0 : (mod(year, 4) === 0 ? 1 : 2);
  const month = floorDiv(12 * (priorDays + correction) + 373, 367);
  return new CalendarDate(year, month, fixedDate - julianFixedDate(year, month, 1) + 1);
}

// GregorianCalendar fields as Java's computeFields gives them in GMT: Julian before the cutover, era years.
function dateInGmt(date: Date): CalendarDate {
  const millis = date.getTime();
  let year: number;
  let month: number;
  let day: number;
  if (millis >= GREGORIAN_CUTOVER_MILLIS) {
    year = date.getUTCFullYear();
    month = date.getUTCMonth() + 1;
    day = date.getUTCDate();
  } else {
    const julian = julianDateFromFixed(floorDiv(millis, ONE_DAY) + EPOCH_OFFSET);
    year = julian.year;
    month = julian.month;
    day = julian.day;
  }
  return new CalendarDate(year > 0 ? year : 1 - year, month, day);
}

function pad(value: number, width: number): string {
  const s = String(value);
  return s.length >= width ? s : '0'.repeat(width - s.length) + s;
}

export class DateParser {
  private static additionalMasks: string[] = [];
  private static defaultTimeZone: string = 'local';

  // Java's TimeZone.getDefault() for masks without a zone: 'UTC' or 'local' (the device zone, the default).
  static setDefaultTimeZone(zone: string): void {
    if (zone !== 'UTC' && zone !== 'local') {
      throw new Error('Unsupported default time zone [' + zone + ']');
    }
    DateParser.defaultTimeZone = zone;
  }

  static getDefaultTimeZone(): string {
    return DateParser.defaultTimeZone;
  }

  // ROME's datetime.extra.masks property (tokens separated by '|'), tried first by parseDate.
  static setExtraMasks(masks: string[]): void {
    for (const mask of masks) {
      DateParser.compile(Strings.trim(mask)!);
    }
    DateParser.additionalMasks = masks.slice();
  }

  static getExtraMasks(): string[] {
    return DateParser.additionalMasks.slice();
  }

  static parseRFC822(sDate: string): Date | null {
    return DateParser.parseUsingMask(RFC822_MASKS, DateParser.convertUnsupportedTimeZones(sDate));
  }

  static parseW3CDateTime(sDate: string): Date | null {
    let s = sDate;
    const tIndex = s.indexOf('T');
    if (tIndex > -1) {
      if (s.endsWith('Z')) {
        s = s.substring(0, s.length - 1) + '+00:00';
      }
      let tzdIndex = s.indexOf('+', tIndex);
      if (tzdIndex === -1) {
        tzdIndex = s.indexOf('-', tIndex);
      }
      if (tzdIndex > -1) {
        let pre = s.substring(0, tzdIndex);
        const secFraction = pre.indexOf(',');
        if (secFraction > -1) {
          pre = pre.substring(0, secFraction);
        }
        s = pre + 'GMT' + s.substring(tzdIndex);
      }
    } else {
      s += 'T00:00GMT';
    }
    return DateParser.parseUsingMask(W3CDATETIME_MASKS, s);
  }

  static parseDate(sDate: string): Date | null {
    if (DateParser.additionalMasks.length > 0) {
      const date = DateParser.parseUsingMask(DateParser.additionalMasks, sDate);
      if (date !== null) {
        return date;
      }
    }
    const date = DateParser.parseW3CDateTime(sDate);
    return date !== null ? date : DateParser.parseRFC822(sDate);
  }

  static formatRFC822(date: Date): string {
    const d = dateInGmt(date);
    return SHORT_WEEKDAYS[date.getUTCDay() + 1] + ', ' + pad(d.day, 2) + ' ' + SHORT_MONTHS[d.month - 1] + ' ' +
      pad(d.year, 4) + ' ' + DateParser.formatTime(date) + ' GMT';
  }

  static formatW3CDateTime(date: Date): string {
    const d = dateInGmt(date);
    return pad(d.year, 4) + '-' + pad(d.month, 2) + '-' + pad(d.day, 2) + 'T' + DateParser.formatTime(date) + 'Z';
  }

  private static formatTime(date: Date): string {
    return pad(date.getUTCHours(), 2) + ':' + pad(date.getUTCMinutes(), 2) + ':' + pad(date.getUTCSeconds(), 2);
  }

  private static convertUnsupportedTimeZones(sDate: string): string {
    const splitted = sDate.split(' ');
    for (const timeZone of ['UT', 'Z']) {
      if (splitted.includes(timeZone)) {
        const last = sDate.lastIndexOf(timeZone);
        return sDate.substring(0, last) + 'UTC' + sDate.substring(last + timeZone.length);
      }
    }
    return sDate;
  }

  private static parseUsingMask(masks: string[], sDate: string): Date | null {
    const s = Strings.trim(sDate)!;
    for (const mask of masks) {
      const date = DateParser.parseWithTokens(DateParser.compile(Strings.trim(mask)!), s);
      if (date !== null) {
        return date;
      }
    }
    return null;
  }

  // SimpleDateFormat.compile, with Java's exception messages.
  private static compile(mask: string): MaskToken[] {
    const cached = compiledMasks.get(mask);
    if (cached !== undefined) {
      return cached;
    }
    const tokens: MaskToken[] = [];
    let inQuote = false;
    let i = 0;
    while (i < mask.length) {
      const c = mask.charAt(i);
      if (c === '\'') {
        if (i + 1 < mask.length && mask.charAt(i + 1) === '\'') {
          tokens.push(new MaskToken('', 1, '\''));
          i += 2;
        } else {
          inQuote = !inQuote;
          i++;
        }
      } else if (inQuote || !/[a-zA-Z]/.test(c)) {
        tokens.push(new MaskToken('', 1, c));
        i++;
      } else {
        if (PATTERN_CHARS.indexOf(c) === -1) {
          throw new IllegalArgumentException('Illegal pattern character \'' + c + '\'');
        }
        if (SUPPORTED_PATTERN_CHARS.indexOf(c) === -1) {
          throw new Error('Unsupported pattern character \'' + c + '\'');
        }
        let count = 1;
        while (i + count < mask.length && mask.charAt(i + count) === c) {
          count++;
        }
        tokens.push(new MaskToken(c, count, ''));
        i += count;
      }
    }
    if (inQuote) {
      throw new IllegalArgumentException('Unterminated quote');
    }
    compiledMasks.set(mask, tokens);
    return tokens;
  }

  // SimpleDateFormat.parse(text, new ParsePosition(0)); null unless the whole text is consumed.
  private static parseWithTokens(tokens: MaskToken[], text: string): Date | null {
    const fields = new CalendarFields();
    const century = DateParser.centuryStart();
    let index = 0;
    for (let t = 0; t < tokens.length; t++) {
      const token = tokens[t];
      if (token.letter === '') {
        if (index >= text.length || text.charAt(index) !== token.literal) {
          return null;
        }
        index++;
      } else {
        const next = t + 1 < tokens.length ? tokens[t + 1] : null;
        const obeyCount = next !== null && DateParser.shouldObeyCount(next);
        index = DateParser.subParse(text, index, token, obeyCount, fields, century);
        if (index < 0) {
          return null;
        }
      }
    }
    if (index !== text.length) {
      return null;
    }
    let millis = DateParser.establish(fields);
    if (fields.ambiguousYear && millis < century.millis) {
      fields.values[YEAR] += 100;
      millis = DateParser.establish(fields);
    }
    if (Number.isNaN(millis) || Math.abs(millis) > MAX_DATE_MILLIS) {
      return null;
    }
    return new Date(millis);
  }

  private static shouldObeyCount(token: MaskToken): boolean {
    if (token.letter === 'M' || token.letter === 'L') {
      return token.count <= 2;
    }
    return token.letter !== '' && OBEY_COUNT_CHARS.indexOf(token.letter) !== -1;
  }

  // The start of SimpleDateFormat's two-digit year window: now minus 80 years, in the default zone.
  private static centuryStart(): CenturyStart {
    const date = new Date(Date.now());
    const utc = DateParser.defaultTimeZone === 'UTC';
    const month = utc ? date.getUTCMonth() : date.getMonth();
    if (utc) {
      date.setUTCFullYear(date.getUTCFullYear() - 80);
      if (date.getUTCMonth() !== month) {
        date.setUTCDate(0);
      }
    } else {
      date.setFullYear(date.getFullYear() - 80);
      if (date.getMonth() !== month) {
        date.setDate(0);
      }
    }
    return new CenturyStart(utc ? date.getUTCFullYear() : date.getFullYear(), date.getTime());
  }

  // SimpleDateFormat.subParse: returns the index after the field, or -1.
  private static subParse(text: string, start: number, token: MaskToken, obeyCount: boolean,
    fields: CalendarFields, century: CenturyStart): number {
    let index = start;
    while (true) {
      if (index >= text.length) {
        return -1;
      }
      const c = text.charAt(index);
      if (c !== ' ' && c !== '\t') {
        break;
      }
      index++;
    }
    const actualStart = index;
    const letter = token.letter;
    const count = token.count;
    const limit = obeyCount ? start + count : text.length;
    let value = 0;
    if (letter === 'k' || letter === 'h' || letter === 'y' || ((letter === 'M' || letter === 'L') && count <= 2)) {
      if (obeyCount && limit > text.length) {
        return -1;
      }
      const number = parseNumber(text, index, limit);
      if (number === null) {
        return -1;
      }
      value = number.value;
      index = number.end;
    }
    switch (letter) {
      case 'y':
        if (count <= 2 && index - actualStart === 2 && javaDigit(text.charCodeAt(actualStart)) >= 0 &&
          javaDigit(text.charCodeAt(actualStart + 1)) >= 0) {
          const ambiguousTwoDigitYear = century.year % 100;
          fields.ambiguousYear = value === ambiguousTwoDigitYear;
          value += Math.floor(century.year / 100) * 100 + (value < ambiguousTwoDigitYear ? 100 : 0);
        }
        fields.set(YEAR, value);
        return index;
      case 'M':
      case 'L':
        if (count <= 2) {
          fields.set(MONTH, (value - 1) | 0);
          return index;
        }
        return DateParser.matchNames(text, start, MONTH, MONTHS, SHORT_MONTHS, 0, fields);
      case 'k':
        fields.set(HOUR_OF_DAY, value === 24 ? 0 : value);
        return index;
      case 'h':
        fields.set(HOUR, value === 12 ? 0 : value);
        return index;
      case 'E':
        return DateParser.matchNames(text, start, DAY_OF_WEEK, WEEKDAYS, SHORT_WEEKDAYS, 1, fields);
      case 'a':
        return DateParser.matchNames(text, start, AM_PM, AM_PM_NAMES, [], 0, fields);
      case 'z':
      case 'Z':
        return DateParser.subParseZone(text, start, index, fields);
      default: {
        if (obeyCount && limit > text.length) {
          return -1;
        }
        const number = parseNumber(text, index, limit);
        if (number === null) {
          return -1;
        }
        fields.set(DateParser.fieldOf(letter), number.value);
        return number.end;
      }
    }
  }

  private static fieldOf(letter: string): number {
    switch (letter) {
      case 'd':
        return DAY_OF_MONTH;
      case 'D':
        return DAY_OF_YEAR;
      case 'H':
        return HOUR_OF_DAY;
      case 'K':
        return HOUR;
      case 'm':
        return MINUTE;
      case 's':
        return SECOND;
      default:
        return MILLISECOND;
    }
  }

  // SimpleDateFormat.matchString over the long names, then the short ones: longest case-insensitive match.
  private static matchNames(text: string, start: number, field: number, longNames: string[], shortNames: string[],
    first: number, fields: CalendarFields): number {
    for (const names of [longNames, shortNames]) {
      let bestLength = 0;
      let best = -1;
      for (let i = first; i < names.length; i++) {
        const length = names[i].length;
        if (length > bestLength && regionMatchesIgnoreCase(text, start, names[i])) {
          best = i;
          bestLength = length;
        }
      }
      if (best >= 0) {
        fields.set(field, best);
        return start + bestLength;
      }
    }
    return -1;
  }

  private static subParseZone(text: string, start: number, index: number, fields: CalendarFields): number {
    const c = text.charAt(index);
    let sign = c === '+' ? 1 : (c === '-' ? -1 : 0);
    if (sign !== 0) {
      return DateParser.subParseNumericZone(text, index + 1, sign, false, fields);
    }
    if ((c === 'G' || c === 'g') && text.length - start >= 3 && regionMatchesIgnoreCase(text, start, 'GMT')) {
      const afterGmt = start + 3;
      if (afterGmt < text.length) {
        const s = text.charAt(afterGmt);
        sign = s === '+' ? 1 : (s === '-' ? -1 : 0);
      }
      if (sign === 0) {
        fields.set(ZONE_OFFSET, 0);
        fields.set(DST_OFFSET, 0);
        return afterGmt;
      }
      return DateParser.subParseNumericZone(text, afterGmt + 1, sign, true, fields);
    }
    for (const zone of getZoneNames()) {
      if (regionMatchesIgnoreCase(text, index, zone.name)) {
        fields.zoneRaw = zone.rawOffset;
        if (zone.dstOffset !== null) {
          fields.clear(ZONE_OFFSET);
          fields.set(DST_OFFSET, zone.dstOffset);
        }
        return index + zone.name.length;
      }
    }
    return -1;
  }

  // "hh:mm" or "h:mm" after "GMT+", "hhmm" after a bare sign.
  private static subParseNumericZone(text: string, start: number, sign: number, colon: boolean,
    fields: CalendarFields): number {
    let index = start;
    if (index >= text.length || !isAsciiDigit(text.charAt(index))) {
      return -1;
    }
    let hours = text.charCodeAt(index++) - 48;
    if (index >= text.length) {
      return -1;
    }
    if (isAsciiDigit(text.charAt(index))) {
      hours = hours * 10 + text.charCodeAt(index++) - 48;
    } else if (!colon) {
      return -1;
    }
    if (hours > 23) {
      return -1;
    }
    if (colon) {
      if (index >= text.length || text.charAt(index) !== ':') {
        return -1;
      }
      index++;
    }
    if (index + 1 >= text.length || !isAsciiDigit(text.charAt(index)) || !isAsciiDigit(text.charAt(index + 1))) {
      return -1;
    }
    const minutes = (text.charCodeAt(index) - 48) * 10 + text.charCodeAt(index + 1) - 48;
    if (minutes > 59) {
      return -1;
    }
    fields.set(ZONE_OFFSET, (hours * 60 + minutes) * 60000 * sign);
    fields.set(DST_OFFSET, 0);
    return index + 2;
  }

  // CalendarBuilder.establish + lenient GregorianCalendar.computeTime.
  private static establish(fields: CalendarFields): number {
    const values = fields.values;
    const stamps = fields.stamps;
    let year = fields.isSet(YEAR) ? values[YEAR] : 1970;

    let domStamp = stamps[DAY_OF_MONTH];
    const doyStamp = stamps[DAY_OF_YEAR];
    let dowimStamp = 0;
    let bestStamp = Math.max(domStamp, doyStamp);
    if (bestStamp === 0) {
      dowimStamp = stamps[DAY_OF_WEEK];
      bestStamp = dowimStamp;
      if (bestStamp === 0) {
        domStamp = stamps[MONTH];
        bestStamp = domStamp;
      }
    }
    const monthBased = bestStamp === domStamp || bestStamp === dowimStamp;

    const hourOfDayStamp = stamps[HOUR_OF_DAY];
    const hourStamp = stamps[HOUR] === 0 || stamps[AM_PM] === 0 ? 0 : Math.max(stamps[HOUR], stamps[AM_PM]);
    let bestHourStamp = Math.max(hourStamp, hourOfDayStamp);
    if (bestHourStamp === 0) {
      bestHourStamp = Math.max(stamps[HOUR], stamps[AM_PM]);
    }
    let timeOfDay = 0;
    if (bestHourStamp !== 0 && bestHourStamp === hourOfDayStamp) {
      timeOfDay += values[HOUR_OF_DAY];
    } else {
      timeOfDay += values[HOUR];
      if (bestHourStamp !== 0 && stamps[AM_PM] !== 0) {
        timeOfDay += 12 * values[AM_PM];
      }
    }
    timeOfDay = ((timeOfDay * 60 + values[MINUTE]) * 60 + values[SECOND]) * 1000 + values[MILLISECOND];
    let fixedDate = Math.trunc(timeOfDay / ONE_DAY);
    timeOfDay = timeOfDay % ONE_DAY;
    while (timeOfDay < 0) {
      timeOfDay += ONE_DAY;
      --fixedDate;
    }

    const fieldYear = year;
    let month = 0;
    if (monthBased) {
      month = values[MONTH];
      if (month > 11) {
        year += Math.trunc(month / 12);
        month %= 12;
      } else if (month < 0) {
        year += floorDiv(month, 12);
        month = mod(month, 12);
      }
    }
    // GregorianCalendar picks the calendar by the YEAR field before MONTH overflow is applied.
    let gfd = fixedDate + DateParser.fixedDateOf(gregorianFixedDate(year, month + 1, 1), monthBased, fields);
    const jfd = fixedDate + DateParser.fixedDateOf(julianFixedDate(year, month + 1, 1), monthBased, fields);
    if (fieldYear > 1582 && gfd >= GREGORIAN_CUTOVER_FIXED_DATE) {
      fixedDate = gfd;
    } else if (fieldYear < 1582 && jfd < GREGORIAN_CUTOVER_FIXED_DATE) {
      fixedDate = jfd;
    } else {
      if (fieldYear < 1582) {
        gfd = jfd;
      }
      fixedDate = monthBased && gfd >= GREGORIAN_CUTOVER_FIXED_DATE ? gfd : jfd;
    }

    const wallMillis = (fixedDate - EPOCH_OFFSET) * ONE_DAY + timeOfDay;
    return wallMillis - DateParser.zoneOffset(fields, wallMillis);
  }

  private static fixedDateOf(firstOfMonth: number, monthBased: boolean, fields: CalendarFields): number {
    if (!monthBased) {
      return firstOfMonth + fields.values[DAY_OF_YEAR] - 1;
    }
    if (fields.stamps[DAY_OF_MONTH] !== 0) {
      return firstOfMonth + fields.values[DAY_OF_MONTH] - 1;
    }
    if (fields.stamps[DAY_OF_WEEK] !== 0) {
      const fixedDate = firstOfMonth + 6;
      const fd = fixedDate - (fields.values[DAY_OF_WEEK] - 1);
      return fixedDate - mod(fd, 7);
    }
    return firstOfMonth;
  }

  private static zoneOffset(fields: CalendarFields, wallMillis: number): number {
    const zoneSet = fields.isSet(ZONE_OFFSET);
    const dstSet = fields.isSet(DST_OFFSET);
    if (zoneSet && dstSet) {
      return fields.values[ZONE_OFFSET] + fields.values[DST_OFFSET];
    }
    const dst = dstSet ? fields.values[DST_OFFSET] : 0;
    if (fields.zoneRaw !== null) {
      return (zoneSet ? fields.values[ZONE_OFFSET] : fields.zoneRaw) + dst;
    }
    if (DateParser.defaultTimeZone === 'UTC' || Math.abs(wallMillis) > MAX_DATE_MILLIS) {
      return (zoneSet ? fields.values[ZONE_OFFSET] : 0) + dst;
    }
    const firstGuess = -new Date(wallMillis).getTimezoneOffset() * 60000;
    return -new Date(wallMillis - firstGuess).getTimezoneOffset() * 60000;
  }
}
