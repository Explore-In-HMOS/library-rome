// Behavior of JDOM 2.0.6.1 org.jdom2.output.Format and EscapeStrategy, as used by ROME (JDOM license, see LICENSE-JDOM)
import { CHARSET_TABLES } from './FormatCharsets';
import { IllegalDataException } from './Verifier';

export enum TextMode {
  PRESERVE,
  TRIM,
  NORMALIZE,
  TRIM_FULL_WHITE
}

export interface EscapeStrategy {
  shouldEscape(ch: number): boolean;
}

function isHighSurrogate(ch: number): boolean {
  return (ch >>> 10) === 0x36;
}

function isLowSurrogate(ch: number): boolean {
  return (ch >>> 10) === 0x37;
}

export function isXMLWhitespace(ch: number): boolean {
  return ch === 0x20 || ch === 0x0A || ch === 0x09 || ch === 0x0D;
}

export function isAllXMLWhitespace(value: string): boolean {
  for (let i = 0; i < value.length; i++) {
    if (!isXMLWhitespace(value.charCodeAt(i))) {
      return false;
    }
  }
  return true;
}

function hex(ch: number): string {
  return ch.toString(16);
}

class UtfEscapeStrategy implements EscapeStrategy {
  shouldEscape(ch: number): boolean {
    return isHighSurrogate(ch);
  }
}

class Bits8EscapeStrategy implements EscapeStrategy {
  shouldEscape(ch: number): boolean {
    return (ch >>> 8) !== 0;
  }
}

class Bits7EscapeStrategy implements EscapeStrategy {
  shouldEscape(ch: number): boolean {
    return (ch >>> 7) !== 0;
  }
}

// JDOM's DefaultCharsetEscapeStrategy: a high surrogate is always escaped (the pair becomes one &#x..;), any other
// char when the charset encoder cannot encode it.
class CharsetEscapeStrategy implements EscapeStrategy {
  private readonly starts: number[] = [];
  private readonly ends: number[] = [];

  constructor(ranges: string) {
    const values = ranges.split(',');
    let prevEnd = -1;
    for (let i = 0; i + 1 < values.length; i += 2) {
      const start = prevEnd + 1 + parseInt(values[i], 36);
      prevEnd = start + parseInt(values[i + 1], 36);
      this.starts.push(start);
      this.ends.push(prevEnd);
    }
  }

  shouldEscape(ch: number): boolean {
    if (isHighSurrogate(ch)) {
      return true;
    }
    let low = 0;
    let high = this.starts.length - 1;
    while (low <= high) {
      const mid = (low + high) >>> 1;
      if (ch < this.starts[mid]) {
        high = mid - 1;
      } else if (ch > this.ends[mid]) {
        low = mid + 1;
      } else {
        return false;
      }
    }
    return true;
  }
}

const UTF_ESCAPE_STRATEGY: EscapeStrategy = new UtfEscapeStrategy();
const BITS8_ESCAPE_STRATEGY: EscapeStrategy = new Bits8EscapeStrategy();
const BITS7_ESCAPE_STRATEGY: EscapeStrategy = new Bits7EscapeStrategy();
const CHARSET_STRATEGIES: Map<string, EscapeStrategy> = new Map<string, EscapeStrategy>();

function charsetStrategy(encoding: string): EscapeStrategy | null {
  const name = encoding.toLowerCase();
  for (const entry of CHARSET_TABLES) {
    if (entry[0].split('|').includes(name)) {
      let strategy = CHARSET_STRATEGIES.get(entry[0]);
      if (strategy === undefined) {
        strategy = new CharsetEscapeStrategy(entry[1]);
        CHARSET_STRATEGIES.set(entry[0], strategy);
      }
      return strategy;
    }
  }
  return null;
}

// Names without a generated table get JDOM's default strategy (the same as the UTF one): unknown names, charsets the
// JDK cannot encode with and, unlike JDOM, the multi-byte charsets CharsetTables.java leaves out.
function chooseStrategy(encoding: string): EscapeStrategy {
  const upper = encoding.toUpperCase();
  if (upper === 'UTF-8' || upper === 'UTF-16') {
    return UTF_ESCAPE_STRATEGY;
  }
  if (upper.startsWith('ISO-8859-') || upper === 'LATIN1') {
    return BITS8_ESCAPE_STRATEGY;
  }
  if (upper === 'US-ASCII' || upper === 'ASCII') {
    return BITS7_ESCAPE_STRATEGY;
  }
  const strategy = charsetStrategy(encoding);
  return strategy === null ? UTF_ESCAPE_STRATEGY : strategy;
}

const STANDARD_INDENT = '  ';
const STANDARD_LINE_SEPARATOR = '\r\n';
const STANDARD_ENCODING = 'UTF-8';

export class Format {
  private indent: string | null = null;
  private lineSeparator: string | null = STANDARD_LINE_SEPARATOR;
  private encoding: string = STANDARD_ENCODING;
  private omitDeclaration: boolean = false;
  private omitEncoding: boolean = false;
  private expandEmptyElements: boolean = false;
  private mode: TextMode = TextMode.PRESERVE;
  private escapeStrategy: EscapeStrategy = UTF_ESCAPE_STRATEGY;

  private constructor() {
    this.setEncoding(STANDARD_ENCODING);
  }

  static getRawFormat(): Format {
    return new Format();
  }

  static getPrettyFormat(): Format {
    const f = new Format();
    f.setIndent(STANDARD_INDENT);
    f.setTextMode(TextMode.TRIM);
    return f;
  }

  static getCompactFormat(): Format {
    const f = new Format();
    f.setTextMode(TextMode.NORMALIZE);
    return f;
  }

  static compact(str: string): string {
    let right = str.length - 1;
    let left = 0;
    while (left <= right && isXMLWhitespace(str.charCodeAt(left))) {
      left++;
    }
    while (right > left && isXMLWhitespace(str.charCodeAt(right))) {
      right--;
    }
    if (left > right) {
      return '';
    }
    let space = true;
    let buffer = '';
    while (left <= right) {
      const c = str.charCodeAt(left);
      if (isXMLWhitespace(c)) {
        if (space) {
          buffer += ' ';
          space = false;
        }
      } else {
        buffer += str.charAt(left);
        space = true;
      }
      left++;
    }
    return buffer;
  }

  static trimRight(str: string): string {
    let right = str.length - 1;
    while (right >= 0 && isXMLWhitespace(str.charCodeAt(right))) {
      right--;
    }
    return right < 0 ? '' : str.substring(0, right + 1);
  }

  static trimLeft(str: string): string {
    const right = str.length;
    let left = 0;
    while (left < right && isXMLWhitespace(str.charCodeAt(left))) {
      left++;
    }
    return left >= right ? '' : str.substring(left);
  }

  static trimBoth(str: string): string {
    let right = str.length - 1;
    while (right > 0 && isXMLWhitespace(str.charCodeAt(right))) {
      right--;
    }
    let left = 0;
    while (left <= right && isXMLWhitespace(str.charCodeAt(left))) {
      left++;
    }
    return left > right ? '' : str.substring(left, right + 1);
  }

  static escapeAttribute(strategy: EscapeStrategy, value: string): string {
    return Format.escape(strategy, null, value, true);
  }

  static escapeText(strategy: EscapeStrategy, eol: string | null, value: string): string {
    return Format.escape(strategy, eol, value, false);
  }

  private static escape(strategy: EscapeStrategy, eol: string | null, value: string, attribute: boolean): string {
    let sb = '';
    let highsurrogate = 0;
    for (let idx = 0; idx < value.length; idx++) {
      const ch = value.charCodeAt(idx);
      if (highsurrogate > 0) {
        if (!isLowSurrogate(ch)) {
          throw new IllegalDataException(`Could not decode surrogate pair 0x${hex(highsurrogate)} / 0x${hex(ch)}`);
        }
        sb += `&#x${hex(0x10000 + (highsurrogate - 0xD800) * 0x400 + (ch - 0xDC00))};`;
        highsurrogate = 0;
        continue;
      }
      if (ch === 0x3C) {
        sb += '&lt;';
      } else if (ch === 0x3E) {
        sb += '&gt;';
      } else if (ch === 0x26) {
        sb += '&amp;';
      } else if (ch === 0x0D) {
        sb += '&#xD;';
      } else if (ch === 0x0A) {
        sb += attribute ? '&#xA;' : (eol !== null ? eol : '\n');
      } else if (attribute && ch === 0x22) {
        sb += '&quot;';
      } else if (attribute && ch === 0x09) {
        sb += '&#x9;';
      } else if (strategy.shouldEscape(ch)) {
        if (isHighSurrogate(ch)) {
          highsurrogate = ch;
        } else {
          sb += `&#x${hex(ch)};`;
        }
      } else {
        sb += value.charAt(idx);
      }
    }
    if (highsurrogate > 0) {
      throw new IllegalDataException(`Surrogate pair 0x${hex(highsurrogate)}truncated`);
    }
    return sb;
  }

  getEscapeStrategy(): EscapeStrategy {
    return this.escapeStrategy;
  }

  // An empty string means no line separator at all, like null.
  setLineSeparator(separator: string | null): Format {
    this.lineSeparator = separator === '' ? null : separator;
    return this;
  }

  getLineSeparator(): string | null {
    return this.lineSeparator;
  }

  setOmitEncoding(omitEncoding: boolean): Format {
    this.omitEncoding = omitEncoding;
    return this;
  }

  getOmitEncoding(): boolean {
    return this.omitEncoding;
  }

  setOmitDeclaration(omitDeclaration: boolean): Format {
    this.omitDeclaration = omitDeclaration;
    return this;
  }

  getOmitDeclaration(): boolean {
    return this.omitDeclaration;
  }

  setExpandEmptyElements(expandEmptyElements: boolean): Format {
    this.expandEmptyElements = expandEmptyElements;
    return this;
  }

  getExpandEmptyElements(): boolean {
    return this.expandEmptyElements;
  }

  setTextMode(mode: TextMode): Format {
    this.mode = mode;
    return this;
  }

  getTextMode(): TextMode {
    return this.mode;
  }

  setIndent(indent: string | null): Format {
    this.indent = indent;
    return this;
  }

  getIndent(): string | null {
    return this.indent;
  }

  // Also picks the escape strategy: characters the encoding cannot represent are written as &#x..;.
  setEncoding(encoding: string): Format {
    this.encoding = encoding;
    this.escapeStrategy = chooseStrategy(encoding);
    return this;
  }

  getEncoding(): string {
    return this.encoding;
  }

  clone(): Format {
    const f = new Format();
    f.indent = this.indent;
    f.lineSeparator = this.lineSeparator;
    f.encoding = this.encoding;
    f.omitDeclaration = this.omitDeclaration;
    f.omitEncoding = this.omitEncoding;
    f.expandEmptyElements = this.expandEmptyElements;
    f.mode = this.mode;
    f.escapeStrategy = this.escapeStrategy;
    return f;
  }
}
