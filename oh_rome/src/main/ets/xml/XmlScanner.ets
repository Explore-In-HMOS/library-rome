// Ported from the JDK 17 Xerces com/sun/org/apache/xerces/internal/impl/XMLEntityScanner.java, XMLScanner.java and
// util/XMLChar.java, XML11Char.java (Apache-2.0): the lexical layer of XmlParser over one string (names, characters,
// references, comments, PIs) with Xerces' rules, JDK limits and messages.
import { XmlParseException } from './Dom';
import { NAME_RUN_10, NAME_RUN_11, NAME_START_10, NAME_START_11 } from './XmlNameChars';

export const EOF_IN_ENTITY = 'XML document structures must start and end within the same entity.';
const SPACES = /[ \t\r\n]*/y;
const MAX_NAME_LENGTH = 1000;
const PLAIN = /^[^\r\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\uD800-\uDFFF\uFFFE\uFFFF]*$/;

function inRanges(ranges: number[], cp: number): boolean {
  let lo = 0;
  let hi = ranges.length / 2 - 1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (cp < ranges[2 * mid]) {
      hi = mid - 1;
    } else if (cp > ranges[2 * mid + 1]) {
      lo = mid + 1;
    } else {
      return true;
    }
  }
  return false;
}

// Java's MessageFormat prints numbers with grouping separators.
export function grouped(n: number): string {
  return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

export class XmlScanner {
  protected s: string;
  protected n: number;
  protected i: number = 0;
  protected xml11: boolean;
  // Line breaks Xerces does not count: those between "<?xml" and the first pseudo attribute.
  protected uncountedLines: number = 0;

  constructor(s: string, xml11: boolean) {
    this.s = s;
    this.n = s.length;
    this.xml11 = xml11;
  }

  // Includes ':', as Xerces' isNameStart does.
  protected isNameStart(at: number): boolean {
    const cp = this.s.codePointAt(at);
    return cp !== undefined && inRanges(this.xml11 ? NAME_START_11 : NAME_START_10, cp);
  }

  private nameStartLength(): number {
    const c = this.code(this.i);
    return c >= 0xd800 && c <= 0xdbff ? 2 : 1;
  }

  protected name(allowColon: boolean): string {
    const start = this.i;
    if (this.isNameStart(this.i) && (allowColon || this.code(this.i) !== 58)) {
      const run = this.xml11 ? NAME_RUN_11 : NAME_RUN_10;
      this.i += this.nameStartLength();
      this.skip(run);
      while (allowColon && this.code(this.i) === 58) {
        this.i++;
        this.skip(run);
      }
    }
    this.limitName(this.i - start);
    return this.s.substring(start, this.i);
  }

  private limitName(length: number): void {
    if (length > MAX_NAME_LENGTH) {
      this.fail(`JAXP00010005: The length of entity "[xml]" is "${grouped(length)}" that exceeds the "${grouped(MAX_NAME_LENGTH)}" limit set by "FEATURE_SECURE_PROCESSING".`);
    }
  }

  // Xerces' scanQName: a Name that ends before a second colon; the part after a colon must start an NCName.
  protected qname(): string {
    const start = this.i;
    if (!this.isNameStart(this.i)) {
      return '';
    }
    const run = this.xml11 ? NAME_RUN_11 : NAME_RUN_10;
    this.i += this.nameStartLength();
    this.skip(run);
    if (this.code(this.i) === 58) {
      this.limitName(this.i - start);
      this.i++;
      const local = this.i;
      this.skip(run);
      if (!this.isNameStart(local) || this.code(local) === 58) {
        this.fail(`Element or attribute "${this.s.substring(start, this.i)}" do not match QName production: QName::=(NCName:)?NCName.`);
      }
      this.limitName(this.i - local);
    } else {
      this.limitName(this.i - start);
    }
    return this.s.substring(start, this.i);
  }

  protected charReference(): string {
    this.i += 2;
    const hex = this.code(this.i) === 120;
    if (hex) {
      this.i++;
    }
    const start = this.i;
    while (this.i < this.n && (hex ? this.isHexDigit(this.code(this.i)) : this.isDigit(this.code(this.i)))) {
      this.i++;
    }
    const digits = this.s.substring(start, this.i);
    if (digits.length === 0) {
      this.fail(hex
        ? 'A hexadecimal representation must immediately follow the "&#x" in a character reference.'
        : 'A decimal representation must immediately follow the "&#" in a character reference.');
    }
    if (this.code(this.i) !== 59) {
      this.fail('The character reference must end with the \';\' delimiter.');
    }
    this.i++;
    const cp = parseInt(digits, hex ? 16 : 10);
    if (!this.isXmlChar(cp)) {
      this.fail(`Character reference "&#${hex ? 'x' : ''}${digits}" is an invalid XML character.`);
    }
    return String.fromCodePoint(cp);
  }

  protected referenceName(): string {
    this.i++;
    if (!this.isNameStart(this.i)) {
      this.fail('The entity name must immediately follow the \'&\' in the entity reference.');
    }
    const name = this.name(true);
    if (this.code(this.i) !== 59) {
      this.fail(`The reference to entity "${name}" must end with the ';' delimiter.`);
    }
    this.i++;
    return name;
  }

  protected predefined(name: string): string | null {
    switch (name) {
      case 'lt': return '<';
      case 'gt': return '>';
      case 'amp': return '&';
      case 'quot': return '"';
      case 'apos': return '\'';
      default: return null;
    }
  }

  protected comment(): string {
    this.i += 4;
    const end = this.checked('--', 'the comment');
    if (this.code(end + 2) !== 62) {
      this.i = end;
      this.fail('The string "--" is not permitted within comments.');
    }
    const text = this.normalized(this.i, end);
    this.i = end + 3;
    return text;
  }

  protected processingInstruction(): string[] {
    this.i += 2;
    const target = this.name(true);
    if (target === '') {
      this.fail(this.i >= this.n ? EOF_IN_ENTITY : 'The processing instruction must begin with the name of the target.');
    }
    if (target.toLowerCase() === 'xml') {
      this.fail('The processing instruction target matching "[xX][mM][lL]" is not allowed.');
    }
    if (this.startsWith('?>')) {
      this.i += 2;
      return [target, ''];
    }
    if (!this.skipSpaces()) {
      if (this.i >= this.n) {
        this.fail(EOF_IN_ENTITY);
      }
      this.fail('White space is required between the processing instruction target and data.');
    }
    const end = this.checked('?>', 'the processing instruction');
    const data = this.normalized(this.i, end);
    this.i = end + 2;
    return [target, data];
  }

  protected checked(terminator: string, where: string): number {
    const found = this.s.indexOf(terminator, this.i);
    const end = found < 0 ? this.n : found;
    if (!PLAIN.test(this.s.substring(this.i, end))) {
      for (let k = this.i; k < end; k += this.validChar(k, where)) {
      }
    }
    if (found < 0) {
      this.i = this.n;
      this.fail(EOF_IN_ENTITY);
    }
    return end;
  }

  protected normalized(start: number, end: number): string {
    const text = this.s.substring(start, end);
    return text.indexOf('\r') < 0 ? text : text.replace(/\r\n?/g, '\n');
  }

  protected quoted(): string {
    const quote = this.code(this.i);
    if (quote !== 34 && quote !== 39) {
      this.fail('The markup declarations contained or pointed to by the document type declaration must be well-formed.');
    }
    const end = this.s.indexOf(String.fromCharCode(quote), this.i + 1);
    if (end < 0) {
      this.i = this.n;
      this.fail('Premature end of file.');
    }
    const value = this.s.substring(this.i + 1, end);
    this.i = end + 1;
    return value;
  }

  protected skipSpaces(): boolean {
    const start = this.i;
    this.skip(SPACES);
    return this.i > start;
  }

  protected skip(run: RegExp): void {
    run.lastIndex = this.i;
    run.test(this.s);
    this.i = run.lastIndex;
  }

  protected expect(c: number, message: string): void {
    if (this.code(this.i) !== c) {
      this.fail(message);
    }
    this.i++;
  }

  protected startsWith(prefix: string): boolean {
    return this.s.startsWith(prefix, this.i);
  }

  protected code(at: number): number {
    return at < this.n ? this.s.charCodeAt(at) : -1;
  }

  // Length (1 or 2) of the character at `at` if it may appear literally, else 0. Text of an XML 1.1 document has
  // its NEL and U+2028 line ends normalized already; its other C1 controls are only allowed as references.
  protected charLength(at: number): number {
    const c = this.code(at);
    if (c >= 0x20 && c < 0x7f || c === 9 || c === 10 || c === 13 || c >= 0xa0 && c < 0xd800 || c >= 0xe000 && c <= 0xfffd ||
      c >= 0x7f && c <= 0x9f && !this.xml11) {
      return 1;
    }
    const next = this.code(at + 1);
    return c >= 0xd800 && c <= 0xdbff && next >= 0xdc00 && next <= 0xdfff ? 2 : 0;
  }

  // Xerces reports a lone high surrogate as invalid content wherever it is.
  protected validChar(at: number, where: string): number {
    const length = this.charLength(at);
    if (length === 0) {
      const c = this.code(at);
      this.i = at;
      this.fail(`An invalid XML character (Unicode: 0x${c.toString(16)}) was found in ${c >= 0xd800 && c <= 0xdbff ? 'the element content of the document' : where}.`);
    }
    return length;
  }

  private isXmlChar(cp: number): boolean {
    return cp === 9 || cp === 10 || cp === 13 || cp >= (this.xml11 ? 1 : 0x20) && cp <= 0xd7ff ||
      cp >= 0xe000 && cp <= 0xfffd || cp >= 0x10000 && cp <= 0x10ffff;
  }

  protected isSpace(c: number): boolean {
    return c === 32 || c === 10 || c === 9 || c === 13;
  }

  private isDigit(c: number): boolean {
    return c >= 48 && c <= 57;
  }

  private isHexDigit(c: number): boolean {
    return this.isDigit(c) || c >= 65 && c <= 70 || c >= 97 && c <= 102;
  }

  protected fail(message: string): never {
    let line = 1;
    let lineStart = 0;
    const end = Math.min(this.i, this.n);
    for (let k = 0; k < end; k++) {
      const c = this.s.charCodeAt(k);
      if (c === 10 || (c === 13 && this.s.charCodeAt(k + 1) !== 10)) {
        line++;
        lineStart = k + 1;
      }
    }
    throw new XmlParseException(message, line - this.uncountedLines, end - lineStart + 1);
  }
}
