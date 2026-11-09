// Ported from ROME rome/src/main/java/com/rometools/rome/io/XmlReader.java (Apache-2.0)
import { util } from '@kit.ArkTS';
import { Strings } from '../utils/Strings';
import { JAVA_CHARSETS, JavaCharset, SINGLE_BYTE_TABLES } from './JavaCharsets';
import { XmlReaderException } from './XmlReaderException';

const BUFFER_SIZE = 4096;
const US_ASCII = 'US-ASCII';
const UTF_8 = 'UTF-8';
const UTF_16BE = 'UTF-16BE';
const UTF_16LE = 'UTF-16LE';
const UTF_16 = 'UTF-16';
const CP1047 = 'CP1047';
const UTF_32 = 'UTF-32';
const REPLACEMENT = 0xFFFD;
// Java's `[.[^; ]]`.
const CHARSET_PATTERN = /charset=([^; ]*)/;
// Java's `.` (which also stops at \u0085) and its ASCII-only `\s`.
const NOT_EOL = '[^\\n\\r\\u0085\\u2028\\u2029]';
const SPACE = '[ \\t\\n\\x0B\\f\\r]';
const ENCODING_PATTERN =
  new RegExp(`<\\?xml${NOT_EOL}*encoding${SPACE}*=${SPACE}*((?:"${NOT_EOL}[^"]*")|(?:'${NOT_EOL}[^']*'))`);

/**
 * Detects the charset of XML bytes with ROME's BOM, XML prolog and HTTP Content-Type rules. A null
 * httpContentType applies the raw-stream rules. read() decodes the bytes after the BOM.
 */
export class XmlReader {
  static defaultEncoding: string | null = null;

  private encodingName: string = '';
  private readonly fallbackEncoding: string | null;
  private input: Uint8Array = new Uint8Array(0);

  constructor(bytes: Uint8Array, httpContentType: string | null = null, lenient: boolean = true,
    defaultEncoding: string | null = null) {
    this.fallbackEncoding = defaultEncoding === null ? XmlReader.defaultEncoding : defaultEncoding;
    try {
      if (httpContentType === null) {
        this.doRawStream(bytes);
      } else {
        this.doHttpStream(bytes, httpContentType, lenient);
      }
    } catch (e) {
      if (!lenient || !(e instanceof XmlReaderException)) {
        throw e as Error;
      }
      this.doLenientDetection(httpContentType, e);
    }
  }

  get encoding(): string {
    return this.encodingName;
  }

  read(): string {
    return decodeAs(this.input, this.encodingName);
  }

  private doLenientDetection(httpContentType: string | null, ex: XmlReaderException): void {
    let failure: XmlReaderException | null = ex;
    if (httpContentType !== null && httpContentType.startsWith('text/html')) {
      try {
        this.doHttpStream(ex.inputStream, 'text/xml' + httpContentType.substring('text/html'.length), true);
        failure = null;
      } catch (e) {
        if (!(e instanceof XmlReaderException)) {
          throw e as Error;
        }
        failure = e;
      }
    }
    if (failure !== null) {
      this.prepareReader(failure.inputStream,
        failure.xmlEncoding ?? failure.contentTypeEncoding ?? this.fallbackEncoding ?? UTF_8);
    }
  }

  private doRawStream(bytes: Uint8Array): void {
    const bomEnc = getBOMEncoding(bytes);
    const pis = bytes.subarray(bomLength(bomEnc));
    const xmlGuessEnc = getXMLGuessEncoding(pis);
    const xmlEnc = getXmlProlog(pis, xmlGuessEnc);
    this.prepareReader(pis, this.calculateRawEncoding(bomEnc, xmlGuessEnc, xmlEnc, pis));
  }

  private doHttpStream(bytes: Uint8Array, httpContentType: string, lenient: boolean): void {
    const cTMime = getContentTypeMime(httpContentType);
    const cTEnc = getContentTypeEncoding(httpContentType);
    const bomEnc = getBOMEncoding(bytes);
    const pis = bytes.subarray(bomLength(bomEnc));
    const xmlGuessEnc = getXMLGuessEncoding(pis);
    const xmlEnc = getXmlProlog(pis, xmlGuessEnc);
    this.prepareReader(pis, this.calculateHttpEncoding(cTMime, cTEnc, bomEnc, xmlGuessEnc, xmlEnc, pis, lenient));
  }

  private prepareReader(input: Uint8Array, encoding: string): void {
    this.input = input;
    this.encodingName = encoding;
  }

  private calculateRawEncoding(bomEnc: string | null, xmlGuessEnc: string | null, xmlEnc: string | null,
    is: Uint8Array): string {
    const rawEx1 = (): XmlReaderException => new XmlReaderException(rawMessage(bomEnc, xmlGuessEnc, xmlEnc),
      null, null, bomEnc, xmlGuessEnc, xmlEnc, is);
    if (bomEnc === null) {
      if (xmlGuessEnc === null || xmlEnc === null) {
        return this.fallbackEncoding ?? UTF_8;
      }
      return xmlEnc === UTF_16 && (xmlGuessEnc === UTF_16BE || xmlGuessEnc === UTF_16LE) ? xmlGuessEnc : xmlEnc;
    }
    if (bomEnc === UTF_8) {
      if (xmlGuessEnc !== null && xmlGuessEnc !== UTF_8) {
        throw rawEx1();
      }
      if (xmlEnc !== null && xmlEnc !== UTF_8) {
        throw rawEx1();
      }
      return UTF_8;
    }
    if (xmlGuessEnc !== null && xmlGuessEnc !== bomEnc) {
      throw new Error(rawMessage(bomEnc, xmlGuessEnc, xmlEnc));
    }
    if (xmlEnc !== null && xmlEnc !== UTF_16 && xmlEnc !== bomEnc) {
      throw rawEx1();
    }
    return bomEnc;
  }

  private calculateHttpEncoding(cTMime: string, cTEnc: string | null, bomEnc: string | null,
    xmlGuessEnc: string | null, xmlEnc: string | null, is: Uint8Array, lenient: boolean): string {
    if (lenient && xmlEnc !== null) {
      return xmlEnc;
    }
    const httpEx = (reason: string): XmlReaderException => new XmlReaderException(
      `Invalid encoding, CT-MIME [${cTMime}] CT-Enc [${cTEnc}] BOM [${bomEnc}] XML guess [${xmlGuessEnc}] XML prolog [${xmlEnc}], ${reason}`,
      cTMime, cTEnc, bomEnc, xmlGuessEnc, xmlEnc, is);
    const appXml = isAppXml(cTMime);
    if (!appXml && !isTextXml(cTMime)) {
      throw httpEx('Invalid MIME');
    }
    if (cTEnc === null) {
      return appXml ? this.calculateRawEncoding(bomEnc, xmlGuessEnc, xmlEnc, is) : this.fallbackEncoding ?? US_ASCII;
    }
    if (bomEnc !== null && (cTEnc === UTF_16BE || cTEnc === UTF_16LE)) {
      throw httpEx('BOM must be NULL');
    }
    if (cTEnc === UTF_16) {
      if (bomEnc !== null && bomEnc.startsWith(UTF_16)) {
        return bomEnc;
      }
      throw httpEx('encoding mismatch');
    }
    return cTEnc;
  }
}

function rawMessage(bomEnc: string | null, xmlGuessEnc: string | null, xmlEnc: string | null): string {
  return `Invalid encoding, BOM [${bomEnc}] XML guess [${xmlGuessEnc}] XML prolog [${xmlEnc}] encoding mismatch`;
}

function getContentTypeMime(httpContentType: string): string {
  const i = httpContentType.indexOf(';');
  return Strings.trim(i === -1 ? httpContentType : httpContentType.substring(0, i))!;
}

function getContentTypeEncoding(httpContentType: string): string | null {
  const i = httpContentType.indexOf(';');
  if (i === -1) {
    return null;
  }
  const m = CHARSET_PATTERN.exec(httpContentType.substring(i + 1));
  if (m === null) {
    return null;
  }
  const encoding = m[1].toUpperCase();
  if (encoding.startsWith('"') && encoding.endsWith('"') || encoding.startsWith('\'') && encoding.endsWith('\'')) {
    // ROME's substring(1, 0) fails on a lone quote.
    if (encoding.length === 1) {
      throw new Error('begin 1, end 0, length 1');
    }
    return encoding.substring(1, encoding.length - 1);
  }
  return encoding;
}

function byteAt(is: Uint8Array, i: number): number {
  return i < is.length ? is[i] : -1;
}

function getBOMEncoding(is: Uint8Array): string | null {
  if (byteAt(is, 0) === 0xFE && byteAt(is, 1) === 0xFF) {
    return UTF_16BE;
  }
  if (byteAt(is, 0) === 0xFF && byteAt(is, 1) === 0xFE) {
    return UTF_16LE;
  }
  if (byteAt(is, 0) === 0xEF && byteAt(is, 1) === 0xBB && byteAt(is, 2) === 0xBF) {
    return UTF_8;
  }
  return null;
}

function bomLength(bomEnc: string | null): number {
  return bomEnc === null ? 0 : bomEnc === UTF_8 ? 3 : 2;
}

function getXMLGuessEncoding(is: Uint8Array): string | null {
  const b0 = byteAt(is, 0);
  const b1 = byteAt(is, 1);
  const b2 = byteAt(is, 2);
  const b3 = byteAt(is, 3);
  if (b0 === 0x00 && b1 === 0x3C && b2 === 0x00 && b3 === 0x3F) {
    return UTF_16BE;
  }
  if (b0 === 0x3C && b1 === 0x00 && b2 === 0x3F && b3 === 0x00) {
    return UTF_16LE;
  }
  if (b0 === 0x3C && b1 === 0x3F && b2 === 0x78 && b3 === 0x6D) {
    return UTF_8;
  }
  if (b0 === 0x4C && b1 === 0x6F && b2 === 0xA7 && b3 === 0x94) {
    return CP1047;
  }
  return null;
}

/** The encoding declared in `<?xml encoding=...?>`, uppercased, or null if none. */
export function getXmlProlog(is: Uint8Array, guessedEnc: string | null): string | null {
  if (guessedEnc === null) {
    return null;
  }
  const offset = Math.min(is.length, BUFFER_SIZE);
  const head = guessedEnc === UTF_8 ? decodeUtf8(is.subarray(0, offset)) : decodeAs(is.subarray(0, offset), guessedEnc);
  const firstGT = head.indexOf('>');
  if (firstGT === -1) {
    throw new Error(offset < BUFFER_SIZE ? 'Unexpected end of XML stream'
      : `XML prolog or ROOT element not found on first ${offset} bytes`);
  }
  const m = ENCODING_PATTERN.exec(head.substring(0, firstGT));
  if (m === null) {
    return null;
  }
  const encoding = m[1].toUpperCase();
  return encoding.substring(1, encoding.length - 1);
}

function isAppXml(mime: string): boolean {
  return mime === 'application/xml' || mime === 'application/xml-dtd' ||
    mime === 'application/xml-external-parsed-entity' || mime.startsWith('application/') && mime.endsWith('+xml');
}

function isTextXml(mime: string): boolean {
  return mime === 'text/xml' || mime === 'text/xml-external-parsed-entity' ||
    mime.startsWith('text/') && mime.endsWith('+xml');
}

// Every name and alias Charset.forName accepts, by ASCII lowercase as Java matches them.
const CHARSETS = new Map<string, JavaCharset>();
for (const cs of JAVA_CHARSETS) {
  CHARSETS.set(asciiLower(cs.name), cs);
  for (const alias of cs.aliases) {
    CHARSETS.set(asciiLower(alias), cs);
  }
}

const TEXT_DECODER_LABELS = new Map<string, string>([
  ['Big5', 'big5'], ['EUC-JP', 'euc-jp'], ['EUC-KR', 'euc-kr'], ['GB18030', 'gb18030'], ['GB2312', 'gb2312'],
  ['GBK', 'gbk'], ['ISO-2022-JP', 'iso-2022-jp'], ['Shift_JIS', 'shift_jis']
]);

function asciiLower(s: string): string {
  return s.replace(/[A-Z]/g, (c: string): string => String.fromCharCode(c.charCodeAt(0) + 32));
}

/**
 * Decodes like Java's new InputStreamReader(in, encoding). A name Java doesn't accept throws Error(encoding), the message
 * of Java's UnsupportedEncodingException.
 */
export function decodeAs(bytes: Uint8Array, encoding: string): string {
  const cs = CHARSETS.get(asciiLower(encoding));
  if (cs === undefined) {
    throw new Error(encoding);
  }
  if (cs.table !== -1) {
    return decodeTable(bytes, SINGLE_BYTE_TABLES[cs.table]);
  }
  switch (cs.name) {
    case UTF_8: {
      const text = textDecoder('utf-8', encoding)(bytes);
      return text.includes('\uFFFD') ? decodeUtf8(bytes) : text;
    }
    case UTF_16:
      return decodeUtf16(bytes, true, true);
    case UTF_16BE:
      return decodeUtf16(bytes, true, false);
    case UTF_16LE:
      return decodeUtf16(bytes, false, false);
    case UTF_32:
      return decodeUtf32(bytes, null);
    case 'UTF-32BE':
      return decodeUtf32(bytes, true);
    case 'UTF-32LE':
      return decodeUtf32(bytes, false);
    default: {
      const label = TEXT_DECODER_LABELS.get(cs.name);
      if (label === undefined) {
        throw new Error(`${encoding}: charset ${cs.name} is not supported by this port`);
      }
      // util.TextDecoder decodes malformed CJK input to U+001A where Java gives U+FFFD; U+001A is not legal in XML.
      const textDecode = textDecoder(label, encoding);
      const decode = (segment: Uint8Array): string => textDecode(segment).replace(/\u001A/g, '\uFFFD');
      return cs.name === 'ISO-2022-JP' ? decode(bytes) : decodeCjk(bytes, cs.name, decode);
    }
  }
}

// ASCII bytes below the limit and 0x7F decode to themselves wherever they occur (checked by tools/xmlreader-oracle/CjkSplit.java).
const ALWAYS_ASCII = new Map<string, number>([
  ['Shift_JIS', 0x40], ['GBK', 0x40], ['Big5', 0x40], ['GB2312', 0x80], ['EUC-KR', 0x80]
]);

// How many bytes Java's EUC-JP or GB18030 decoder takes at i, valid or not.
function unitLength(charset: string, bytes: Uint8Array, i: number): number {
  const b = bytes[i];
  if (b < 0x80) {
    return 1;
  }
  if (charset === 'EUC-JP') {
    return b === 0x8F ? 3 : 2;
  }
  if (b === 0x80 || b === 0xFF || i + 1 >= bytes.length) {
    return 1;
  }
  const b2 = bytes[i + 1];
  if (b2 < 0x30) {
    return 1;
  }
  if (b2 > 0x39) {
    return 2;
  }
  return i + 2 < bytes.length && bytes[i + 2] >= 0x81 && bytes[i + 2] <= 0xFE ? 4 : 3;
}

/**
 * Decodes Shift_JIS, EUC-JP, GBK, GB18030, GB2312, Big5 or EUC-KR: ASCII bytes that Java decodes on their own become the same
 * code point, every run of other bytes goes to decodeSegment.
 */
export function decodeCjk(bytes: Uint8Array, charset: string, decodeSegment: (segment: Uint8Array) => string): string {
  const limit = ALWAYS_ASCII.get(charset);
  const out: string[] = [];
  let start = 0;
  let i = 0;
  while (i < bytes.length) {
    const b = bytes[i];
    if (b < 0x80 && (limit === undefined || b < limit || b === 0x7F)) {
      if (start < i) {
        out.push(decodeSegment(bytes.subarray(start, i)));
      }
      out.push(String.fromCharCode(b));
      start = i + 1;
    }
    i += limit === undefined ? unitLength(charset, bytes, i) : 1;
  }
  if (start < bytes.length) {
    out.push(decodeSegment(bytes.subarray(start)));
  }
  return out.join('');
}

function textDecoder(label: string, encoding: string): (bytes: Uint8Array) => string {
  let decoder: util.TextDecoder | undefined = undefined;
  try {
    const options: util.TextDecoderOptions = { fatal: false, ignoreBOM: false };
    decoder = util.TextDecoder.create(label, options);
  } catch (e) {
    decoder = undefined;
  }
  return (bytes: Uint8Array): string => {
    let text: string | undefined = undefined;
    try {
      text = decoder === undefined ? undefined : decoder.decodeToString(bytes);
    } catch (e) {
      text = undefined;
    }
    if (typeof text !== 'string') {
      throw new Error(`${encoding}: util.TextDecoder could not decode ${label}`);
    }
    return text;
  };
}

function fromCodes(codes: number[]): string {
  let out = '';
  for (let i = 0; i < codes.length; i += 8192) {
    out += String.fromCharCode(...codes.slice(i, i + 8192));
  }
  return out;
}

function decodeTable(bytes: Uint8Array, table: string): string {
  const codes: number[] = [];
  for (let i = 0; i < bytes.length; i++) {
    codes.push(table.charCodeAt(bytes[i]));
  }
  return fromCodes(codes);
}

// Java's UTF-16 decoders: an unpaired high surrogate is malformed together with the unit after it, and leftover bytes at
// the end become one U+FFFD. detectBom is the "UTF-16" charset, which drops one leading BOM.
function decodeUtf16(bytes: Uint8Array, bigEndian: boolean, detectBom: boolean): string {
  const codes: number[] = [];
  let be = bigEndian;
  let i = 0;
  const unit = (k: number): number => be ? bytes[k] << 8 | bytes[k + 1] : bytes[k + 1] << 8 | bytes[k];
  if (detectBom && bytes.length >= 2) {
    const first = bytes[0] << 8 | bytes[1];
    if (first === 0xFEFF || first === 0xFFFE) {
      be = first === 0xFEFF;
      i = 2;
    }
  }
  while (bytes.length - i > 1) {
    const c = unit(i);
    if (c >= 0xD800 && c <= 0xDBFF) {
      if (bytes.length - i < 4) {
        break;
      }
      const c2 = unit(i + 2);
      if (c2 >= 0xDC00 && c2 <= 0xDFFF) {
        codes.push(c, c2);
      } else {
        codes.push(REPLACEMENT);
      }
      i += 4;
    } else {
      codes.push(c >= 0xDC00 && c <= 0xDFFF ? REPLACEMENT : c);
      i += 2;
    }
  }
  if (i < bytes.length) {
    codes.push(REPLACEMENT);
  }
  return fromCodes(codes);
}

// Java's UTF-32 decoders: a leading BOM is dropped unless it contradicts the charset's byte order, code points past
// U+10FFFF are malformed, and leftover bytes become one U+FFFD.
function decodeUtf32(bytes: Uint8Array, expectedBigEndian: boolean | null): string {
  const codes: number[] = [];
  const word = (k: number, be: boolean): number => be
    ? (bytes[k] << 24 | bytes[k + 1] << 16 | bytes[k + 2] << 8 | bytes[k + 3]) >>> 0
    : (bytes[k + 3] << 24 | bytes[k + 2] << 16 | bytes[k + 1] << 8 | bytes[k]) >>> 0;
  let be = expectedBigEndian ?? true;
  let i = 0;
  if (bytes.length >= 4) {
    const first = word(0, true);
    if (first === 0xFEFF && expectedBigEndian !== false) {
      be = true;
      i = 4;
    } else if (first === 0xFFFE0000 && expectedBigEndian !== true) {
      be = false;
      i = 4;
    }
  }
  for (; bytes.length - i >= 4; i += 4) {
    const cp = word(i, be);
    if (cp < 0x10000) {
      codes.push(cp);
    } else if (cp <= 0x10FFFF) {
      codes.push(0xD7C0 + (cp >> 10), 0xDC00 | cp & 0x3FF);
    } else {
      codes.push(REPLACEMENT);
    }
  }
  if (i < bytes.length) {
    codes.push(REPLACEMENT);
  }
  return fromCodes(codes);
}

function isCont(b: number): boolean {
  return (b & 0xC0) === 0x80;
}

// JDK 17's UTF-8 decoder, including how many bytes each malformed sequence takes (one U+FFFD each) and that leftover
// bytes of an incomplete sequence at the end become one U+FFFD.
export function decodeUtf8(bytes: Uint8Array): string {
  const codes: number[] = [];
  const n = bytes.length;
  let i = 0;
  while (i < n) {
    const b1 = bytes[i];
    const left = n - i;
    if (b1 < 0x80) {
      codes.push(b1);
      i++;
    } else if (b1 >= 0xC2 && b1 <= 0xDF) {
      if (left < 2) {
        codes.push(REPLACEMENT);
        i = n;
      } else if (!isCont(bytes[i + 1])) {
        codes.push(REPLACEMENT);
        i++;
      } else {
        codes.push((b1 & 0x1F) << 6 | bytes[i + 1] & 0x3F);
        i += 2;
      }
    } else if (b1 >= 0xE0 && b1 <= 0xEF) {
      const badSecond = left > 1 && (b1 === 0xE0 && (bytes[i + 1] & 0xE0) === 0x80 || !isCont(bytes[i + 1]));
      if (left < 3) {
        codes.push(REPLACEMENT);
        i = badSecond ? i + 1 : n;
      } else if (badSecond || !isCont(bytes[i + 2])) {
        codes.push(REPLACEMENT);
        i += badSecond ? 1 : 2;
      } else {
        const c = (b1 & 0x0F) << 12 | (bytes[i + 1] & 0x3F) << 6 | bytes[i + 2] & 0x3F;
        codes.push(c >= 0xD800 && c <= 0xDFFF ? REPLACEMENT : c);
        i += 3;
      }
    } else if (b1 >= 0xF0 && b1 <= 0xF7) {
      const b2 = left > 1 ? bytes[i + 1] : -1;
      const badSecond = b1 > 0xF4 || left > 1 &&
        (b1 === 0xF0 && (b2 < 0x90 || b2 > 0xBF) || b1 === 0xF4 && (b2 & 0xF0) !== 0x80 || !isCont(b2));
      const badThird = left > 2 && !isCont(bytes[i + 2]);
      if (badSecond) {
        codes.push(REPLACEMENT);
        i++;
      } else if (badThird) {
        codes.push(REPLACEMENT);
        i += 2;
      } else if (left < 4) {
        codes.push(REPLACEMENT);
        i = n;
      } else if (!isCont(bytes[i + 3])) {
        codes.push(REPLACEMENT);
        i += 3;
      } else {
        const cp = (b1 & 0x07) << 18 | (b2 & 0x3F) << 12 | (bytes[i + 2] & 0x3F) << 6 | bytes[i + 3] & 0x3F;
        codes.push(0xD7C0 + (cp >> 10), 0xDC00 | cp & 0x3FF);
        i += 4;
      }
    } else {
      codes.push(REPLACEMENT);
      i++;
    }
  }
  return fromCodes(codes);
}
