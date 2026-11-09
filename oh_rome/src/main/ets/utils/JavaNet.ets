// Replicates JDK 17 new java.net.URL(String) and new java.net.URI(String): which inputs throw, and the parsed URL.
import { NumberFormatException } from './Exceptions';
import { parseJavaInt } from './JavaMath';

export class MalformedURLException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'MalformedURLException';
  }
}

export class URISyntaxException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'URISyntaxException';
  }
}

export class JavaUrl {
  readonly protocol: string;
  readonly host: string;
  readonly port: number;
  readonly defaultPort: number;
  private readonly externalForm: string;

  constructor(protocol: string, host: string, port: number, defaultPort: number, authority: string | null, path: string,
    query: string | null, ref: string | null) {
    this.protocol = protocol;
    this.host = host;
    this.port = port;
    this.defaultPort = defaultPort;
    this.externalForm = protocol + ':' + (authority !== null && authority.length > 0 ? '//' + authority : '') + path +
      (query !== null ? '?' + query : '') + (ref !== null ? '#' + ref : '');
  }

  toString(): string {
    return this.externalForm;
  }
}

// The protocols with a built-in handler, and their default ports.
const DEFAULT_PORTS: Map<string, number> = new Map<string, number>([
  ['file', -1], ['ftp', 21], ['http', 80], ['https', 443], ['jar', -1], ['jmod', -1], ['jrt', -1], ['mailto', -1]
]);

// Characters IPAddressUtil.checkHostString rejects in a host besides controls and '/'.
const ILLEGAL_IN_HOST_OTHERS: number[] = [8263, 8264, 8265, 8448, 8449, 8453, 8454, 10868, 65109, 65110, 65119, 65131,
  65283, 65295, 65306, 65311, 65312];

export function parseUrl(spec: string): JavaUrl {
  try {
    return parseUrlUnwrapped(spec);
  } catch (e) {
    throw e instanceof MalformedURLException ? e : new MalformedURLException((e as Error).message);
  }
}

function parseUrlUnwrapped(spec: string): JavaUrl {
  let limit = spec.length;
  while (limit > 0 && spec.charCodeAt(limit - 1) <= 0x20) {
    limit--;
  }
  let start = 0;
  while (start < limit && spec.charCodeAt(start) <= 0x20) {
    start++;
  }
  if (spec.substring(start, start + 4).toLowerCase() === 'url:') {
    start += 4;
  }
  let protocol: string | null = null;
  for (let i = start; spec.charAt(start) !== '#' && i < limit && spec.charAt(i) !== '/'; i++) {
    if (spec.charAt(i) === ':') {
      protocol = spec.substring(start, i).toLowerCase();
      start = i + 1;
      break;
    }
  }
  if (protocol === null) {
    throw new MalformedURLException('no protocol: ' + spec);
  }
  if (!DEFAULT_PORTS.has(protocol)) {
    throw new MalformedURLException('unknown protocol: ' + protocol);
  }
  const defaultPort = DEFAULT_PORTS.get(protocol)!;
  let ref: string | null = null;
  const hash = spec.indexOf('#', start);
  if (hash >= 0) {
    ref = spec.substring(hash + 1, limit);
    limit = hash;
  }
  if (protocol === 'mailto') {
    const file = start < limit ? spec.substring(start, limit) : '';
    if (isJavaBlank(file)) {
      throw new Error('No email address');
    }
    return fromFile(protocol, defaultPort, file, null);
  }
  if (protocol === 'jar') {
    return parseJarUrl(defaultPort, spec, start, limit);
  }
  return parseHierarchicalUrl(protocol, defaultPort, ref, spec, start, limit);
}

// String.isBlank(): every character is Character.isWhitespace.
function isJavaBlank(s: string): boolean {
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    const whitespace = (c >= 0x09 && c <= 0x0D) || (c >= 0x1C && c <= 0x20) || c === 0x1680 ||
      (c >= 0x2000 && c <= 0x2006) || (c >= 0x2008 && c <= 0x200A) || c === 0x2028 || c === 0x2029 || c === 0x205F ||
      c === 0x3000;
    if (!whitespace) {
      return false;
    }
  }
  return true;
}

// URLStreamHandler.setURL(u, protocol, "", -1, file, ref) as the jar and mailto handlers call it.
function fromFile(protocol: string, defaultPort: number, file: string | null, ref: string | null): JavaUrl {
  const q = file === null ? -1 : file.lastIndexOf('?');
  const path = file === null ? '' : q === -1 ? file : file.substring(0, q);
  const query = file === null || q === -1 ? null : file.substring(q + 1);
  return new JavaUrl(protocol, '', -1, defaultPort, null, path, query, ref);
}

function parseJarUrl(defaultPort: number, spec: string, start: number, limit: number): JavaUrl {
  const refPos = spec.indexOf('#', limit);
  const ref = refPos > -1 ? spec.substring(refPos + 1) : null;
  const file = spec.substring(start, limit);
  if (file.substring(0, 4).toLowerCase() === 'jar:') {
    throw new Error('Nested JAR URLs are not supported');
  }
  if (spec.substring(0, 4).toLowerCase() === 'jar:') {
    const bangSlash = file.lastIndexOf('!/');
    if (bangSlash === -1) {
      throw new Error('no !/ in spec');
    }
    parseUrl(file.substring(0, bangSlash));
    return fromFile('jar', defaultPort, file, ref);
  }
  if (refPos === start) {
    return fromFile('jar', defaultPort, null, ref);
  }
  throw new Error('malformed context url');
}

function parseHierarchicalUrl(protocol: string, defaultPort: number, ref: string | null, spec: string, start: number,
  limit: number): JavaUrl {
  let authority: string | null = null;
  let query: string | null = null;
  let host: string | null = null;
  let port = -1;
  let path: string | null = null;
  if (start < limit) {
    const queryStart = spec.indexOf('?');
    if (queryStart !== -1 && queryStart < limit) {
      query = spec.substring(queryStart + 1, limit);
      limit = queryStart;
      spec = spec.substring(0, queryStart);
    }
  }
  const isUNCName = start <= limit - 4 && spec.startsWith('////', start);
  if (!isUNCName && start <= limit - 2 && spec.startsWith('//', start)) {
    start += 2;
    let i = spec.indexOf('/', start);
    if (i < 0 || i > limit) {
      i = spec.indexOf('?', start);
      if (i < 0 || i > limit) {
        i = limit;
      }
    }
    authority = spec.substring(start, i);
    host = authority;
    const at = authority.indexOf('@');
    if (at !== -1) {
      if (at !== authority.lastIndexOf('@')) {
        host = null;
      } else {
        host = authority.substring(at + 1);
      }
    }
    if (host === null) {
      host = '';
    } else if (host.length > 0 && host.charAt(0) === '[') {
      const close = host.indexOf(']');
      if (close <= 2) {
        throw new Error('Invalid authority field: ' + authority);
      }
      const rest = host.substring(close + 1);
      host = host.substring(0, close + 1);
      if (!isIPv6LiteralAddress(host.substring(1, close))) {
        throw new Error('Invalid host: ' + host);
      }
      if (rest.length > 0 && rest.charAt(0) !== ':') {
        throw new Error('Invalid authority field: ' + authority);
      }
      if (rest.length > 1) {
        port = parseJavaInt(rest.substring(1));
      }
    } else {
      const colon = host.indexOf(':');
      if (colon >= 0) {
        if (host.length > colon + 1) {
          port = parseJavaInt(host.substring(colon + 1));
        }
        host = host.substring(0, colon);
      }
    }
    if (port < -1) {
      throw new Error('Invalid port number :' + port);
    }
    start = i;
    if (authority.length > 0) {
      path = '';
    }
  }
  if (start < limit) {
    const specStr = spec.substring(start, limit);
    path = spec.charAt(start) === '/' || authority === null ? specStr : '/' + specStr;
  }
  host = host === null ? '' : host;
  for (let j = 0; j < host.length; j++) {
    const c = host.charCodeAt(j);
    if (c < 0x20 || c === 0x7F || c === 0x2F || ILLEGAL_IN_HOST_OTHERS.indexOf(c) >= 0) {
      throw new Error('Illegal character found in host');
    }
  }
  return new JavaUrl(protocol, host, port, defaultPort, authority, path === null ? '' : path, query, ref);
}

function asciiHexDigit(c: string): number {
  return '0123456789abcdef'.indexOf(c.toLowerCase());
}

// IPAddressUtil.textToNumericFormatV4(src) != null
function isIPv4LiteralAddress(src: string): boolean {
  if (src.length === 0 || src.length > 15) {
    return false;
  }
  let value = 0;
  let currByte = 0;
  let newOctet = true;
  for (let i = 0; i < src.length; i++) {
    const c = src.charAt(i);
    if (c === '.') {
      if (newOctet || value > 0xff || currByte === 3) {
        return false;
      }
      currByte++;
      value = 0;
      newOctet = true;
    } else {
      const digit = '0123456789'.indexOf(c);
      if (digit < 0) {
        return false;
      }
      value = value * 10 + digit;
      newOctet = false;
    }
  }
  return !newOctet && value < Math.pow(2, (4 - currByte) * 8);
}

// IPAddressUtil.textToNumericFormatV6(src) != null
function isIPv6LiteralAddress(src: string): boolean {
  if (src.length < 2) {
    return false;
  }
  const percent = src.indexOf('%');
  if (percent === src.length - 1) {
    return false;
  }
  const end = percent !== -1 ? percent : src.length;
  let colonp = -1;
  let i = 0;
  let j = 0;
  if (src.charAt(0) === ':' && src.charAt(++i) !== ':') {
    return false;
  }
  let curtok = i;
  let sawXdigit = false;
  let val = 0;
  while (i < end) {
    const ch = src.charAt(i++);
    const chval = asciiHexDigit(ch);
    if (chval !== -1) {
      val = val * 16 + chval;
      if (val > 0xffff) {
        return false;
      }
      sawXdigit = true;
      continue;
    }
    if (ch === ':') {
      curtok = i;
      if (!sawXdigit) {
        if (colonp !== -1) {
          return false;
        }
        colonp = j;
        continue;
      } else if (i === end || j + 2 > 16) {
        return false;
      }
      j += 2;
      sawXdigit = false;
      val = 0;
      continue;
    }
    if (ch === '.' && j + 4 <= 16) {
      const ia4 = src.substring(curtok, end);
      if (ia4.split('.').length !== 4 || !isIPv4LiteralAddress(ia4)) {
        return false;
      }
      j += 4;
      sawXdigit = false;
      break;
    }
    return false;
  }
  if (sawXdigit) {
    if (j + 2 > 16) {
      return false;
    }
    j += 2;
  }
  if (colonp !== -1) {
    if (j === 16) {
      return false;
    }
    j = 16;
  }
  return j === 16;
}

// Character classes of java.net.URI (RFC 2396), ASCII only. Classes that allow escapes also accept "%XX" and
// non-ASCII characters other than controls and space separators.
const DIGIT = '0123456789';
const ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const ALPHANUM = DIGIT + ALPHA;
const HEX = DIGIT + 'ABCDEFabcdef';
const UNRESERVED = ALPHANUM + '-_.!~*\'()';
const URIC = UNRESERVED + ';/?:@&=+$,[]';
const PATH = UNRESERVED + ':@&=+$,;/';
const USERINFO = UNRESERVED + ';:&=+$,';
const REG_NAME = UNRESERVED + '$,;:@&=+';
const SERVER = USERINFO + '.:@[]';
const SERVER_PERCENT = SERVER + '%';
const SCHEME = ALPHANUM + '+-.';
const SCOPE_ID = ALPHANUM + '_.';

function isSpaceOrControl(c: number): boolean {
  return c <= 0x20 || (c >= 0x7F && c <= 0xA0) || c === 0x1680 || (c >= 0x2000 && c <= 0x200A) || c === 0x2028 ||
    c === 0x2029 || c === 0x202F || c === 0x205F || c === 0x3000;
}

export function parseUri(s: string): string {
  new UriParser(s).parse();
  return s;
}

// java.net.URI.Parser with requireServerAuthority = false, keeping only what decides whether the input is accepted.
class UriParser {
  private input: string;
  private ipv6byteCount = 0;

  constructor(input: string) {
    this.input = input;
  }

  private fail(reason: string, p: number): URISyntaxException {
    return new URISyntaxException(`${reason} at index ${p}: ${this.input}`);
  }

  private at(start: number, end: number, s: string): boolean {
    return end - start >= s.length && this.input.startsWith(s, start);
  }

  private scanChar(start: number, end: number, c: string): number {
    return this.at(start, end, c) ? start + 1 : start;
  }

  private scanStop(start: number, end: number, err: string, stop: string): number {
    let p = start;
    for (; p < end; p++) {
      const c = this.input.charAt(p);
      if (err.indexOf(c) >= 0) {
        return -1;
      }
      if (stop.indexOf(c) >= 0) {
        break;
      }
    }
    return p;
  }

  private scanTo(start: number, end: number, stop: string): number {
    let p = start;
    while (p < end && stop.indexOf(this.input.charAt(p)) < 0) {
      p++;
    }
    return p;
  }

  private scan(start: number, end: number, chars: string, escaped: boolean): number {
    let p = start;
    while (p < end) {
      const c = this.input.charAt(p);
      if (c.charCodeAt(0) < 0x80 && chars.indexOf(c) >= 0) {
        p++;
      } else if (escaped && c === '%') {
        if (p + 3 > end || HEX.indexOf(this.input.charAt(p + 1)) < 0 || HEX.indexOf(this.input.charAt(p + 2)) < 0) {
          throw this.fail('Malformed escape pair', p);
        }
        p += 3;
      } else if (escaped && c.charCodeAt(0) > 0x80 && !isSpaceOrControl(c.charCodeAt(0))) {
        p++;
      } else {
        break;
      }
    }
    return p;
  }

  private checkChars(start: number, end: number, chars: string, escaped: boolean, what: string): void {
    const p = this.scan(start, end, chars, escaped);
    if (p < end) {
      throw this.fail('Illegal character in ' + what, p);
    }
  }

  parse(): void {
    const n = this.input.length;
    let p = this.scanStop(0, n, '/?#', ':');
    if (p >= 0 && this.at(p, n, ':')) {
      if (p === 0) {
        throw this.fail('Expected scheme name', 0);
      }
      this.checkChars(0, 1, ALPHA, false, 'scheme name');
      this.checkChars(1, p, SCHEME, false, 'scheme name');
      p++;
      if (this.at(p, n, '/')) {
        p = this.parseHierarchical(p, n);
      } else {
        const q = this.scanTo(p, n, '#');
        if (q <= p) {
          throw this.fail('Expected scheme-specific part', p);
        }
        this.checkChars(p, q, URIC, true, 'opaque part');
        p = q;
      }
    } else {
      p = this.parseHierarchical(0, n);
    }
    if (this.at(p, n, '#')) {
      this.checkChars(p + 1, n, URIC, true, 'fragment');
      p = n;
    }
    if (p < n) {
      throw this.fail('end of URI', p);
    }
  }

  private parseHierarchical(start: number, n: number): number {
    let p = start;
    if (this.at(p, n, '//')) {
      p += 2;
      const q = this.scanTo(p, n, '/?#');
      if (q > p) {
        p = this.parseAuthority(p, q);
      } else if (q >= n) {
        throw this.fail('Expected authority', p);
      }
    }
    let q = this.scanTo(p, n, '?#');
    this.checkChars(p, q, PATH, true, 'path');
    p = q;
    if (this.at(p, n, '?')) {
      p++;
      q = this.scanTo(p, n, '#');
      this.checkChars(p, q, URIC, true, 'query');
      p = q;
    }
    return p;
  }

  private parseAuthority(p: number, n: number): number {
    const serverChars = this.scan(p, n, this.scanTo(p, n, ']') > p ? SERVER_PERCENT : SERVER, true) === n;
    const qreg = this.scan(p, n, REG_NAME, true);
    const regChars = qreg === n;
    if (regChars) {
      return n;
    }
    let q = p;
    let ex: URISyntaxException | null = null;
    if (serverChars) {
      try {
        q = this.parseServer(p, n);
        if (q < n) {
          ex = this.fail('Expected end of authority', q);
          q = p;
        }
      } catch (e) {
        if (!(e instanceof URISyntaxException)) {
          throw e as Error;
        }
        ex = e;
        q = p;
      }
    }
    if (q < n) {
      throw ex !== null ? ex : this.fail('Illegal character in authority', serverChars ? q : qreg);
    }
    return n;
  }

  // Only reached with an authority that is not a valid registry name, so skipParseException is always false.
  private parseServer(start: number, n: number): number {
    let p = start;
    let q = this.scanStop(p, n, '/?#', '@');
    if (q >= p && this.at(q, n, '@')) {
      this.checkChars(p, q, USERINFO, true, 'user info');
      p = q + 1;
    }
    if (this.at(p, n, '[')) {
      p++;
      q = this.scanStop(p, n, '/?#', ']');
      if (q <= p || !this.at(q, n, ']')) {
        throw this.fail('Expected closing bracket for IPv6 address', q);
      }
      const r = this.scanTo(p, q, '%');
      this.parseIPv6Reference(p, r > p ? r : q);
      if (r > p && r + 1 === q) {
        throw this.fail('scope id expected', r);
      }
      if (r > p) {
        this.checkChars(r + 1, q, SCOPE_ID, false, 'scope id');
      }
      p = q + 1;
    } else {
      q = this.parseIPv4Address(p, n);
      p = q <= p ? this.parseHostname(p, n) : q;
    }
    if (this.at(p, n, ':')) {
      p++;
      q = this.scanTo(p, n, '/');
      if (q > p) {
        this.checkChars(p, q, DIGIT, false, 'port number');
        if (Number(this.input.substring(p, q)) > 2147483647) {
          throw this.fail('Malformed port number', p);
        }
        p = q;
      }
    }
    if (p < n) {
      throw this.fail('Expected port number', p);
    }
    return p;
  }

  // Integer.parseInt overflow escapes the parser as a NumberFormatException.
  private scanByte(start: number, n: number): number {
    const q = this.scan(start, n, DIGIT, false);
    if (q <= start) {
      return q;
    }
    const value = Number(this.input.substring(start, q));
    if (value > 2147483647) {
      throw new NumberFormatException(`For input string: "${this.input.substring(start, q)}"`);
    }
    return value > 255 ? start : q;
  }

  private scanIPv4Address(start: number, n: number, strict: boolean): number {
    let p = start;
    const m = this.scan(p, n, DIGIT + '.', false);
    if (m <= p || (strict && m !== n)) {
      return -1;
    }
    let q = p;
    for (let part = 0; part < 7; part++) {
      q = part % 2 === 0 ? this.scanByte(p, m) : this.scanChar(p, m, '.');
      if (q <= p) {
        break;
      }
      p = q;
      if (part === 6 && q >= m) {
        return q;
      }
    }
    throw this.fail('Malformed IPv4 address', q);
  }

  private takeIPv4Address(start: number, n: number, expected: string): number {
    const p = this.scanIPv4Address(start, n, true);
    if (p <= start) {
      throw this.fail('Expected ' + expected, start);
    }
    return p;
  }

  private parseIPv4Address(start: number, n: number): number {
    let p: number;
    try {
      p = this.scanIPv4Address(start, n, false);
    } catch (e) {
      return -1;
    }
    if (p > start && p < n && this.input.charAt(p) !== ':') {
      p = -1;
    }
    return p;
  }

  private parseHostname(start: number, n: number): number {
    let p = start;
    let l = -1;
    do {
      let q = this.scan(p, n, ALPHANUM, false);
      if (q <= p) {
        break;
      }
      l = p;
      p = q;
      q = this.scan(p, n, ALPHANUM + '-', false);
      if (q > p) {
        if (this.input.charAt(q - 1) === '-') {
          throw this.fail('Illegal character in hostname', q - 1);
        }
        p = q;
      }
      q = this.scanChar(p, n, '.');
      if (q <= p) {
        break;
      }
      p = q;
    } while (p < n);
    if (p < n && !this.at(p, n, ':')) {
      throw this.fail('Illegal character in hostname', p);
    }
    if (l < 0) {
      throw this.fail('Expected hostname', start);
    }
    if (l > start && ALPHA.indexOf(this.input.charAt(l)) < 0) {
      throw this.fail('Illegal character in hostname', l);
    }
    return p;
  }

  private parseIPv6Reference(start: number, n: number): number {
    let p = start;
    let compressedZeros = false;
    const q = this.scanHexSeq(p, n);
    if (q > p) {
      p = q;
      if (this.at(p, n, '::')) {
        compressedZeros = true;
        p = this.scanHexPost(p + 2, n);
      } else if (this.at(p, n, ':')) {
        p = this.takeIPv4Address(p + 1, n, 'IPv4 address');
        this.ipv6byteCount += 4;
      }
    } else if (this.at(p, n, '::')) {
      compressedZeros = true;
      p = this.scanHexPost(p + 2, n);
    }
    if (p < n || this.ipv6byteCount > 16 || (!compressedZeros && this.ipv6byteCount < 16) ||
      (compressedZeros && this.ipv6byteCount === 16)) {
      throw this.fail('Malformed IPv6 address', start);
    }
    return p;
  }

  private scanHexPost(start: number, n: number): number {
    let p = start;
    if (p === n) {
      return p;
    }
    const q = this.scanHexSeq(p, n);
    if (q > p) {
      p = q;
      if (this.at(p, n, ':')) {
        p = this.takeIPv4Address(p + 1, n, 'hex digits or IPv4 address');
        this.ipv6byteCount += 4;
      }
    } else {
      p = this.takeIPv4Address(p, n, 'hex digits or IPv4 address');
      this.ipv6byteCount += 4;
    }
    return p;
  }

  private scanHexSeq(start: number, n: number): number {
    let p = start;
    let q = this.scan(p, n, HEX, false);
    if (q <= p || this.at(q, n, '.')) {
      return -1;
    }
    if (q > p + 4) {
      throw this.fail('IPv6 hexadecimal digit sequence too long', p);
    }
    this.ipv6byteCount += 2;
    p = q;
    while (p < n && this.at(p, n, ':') && !this.at(p + 1, n, ':')) {
      p++;
      q = this.scan(p, n, HEX, false);
      if (q <= p) {
        throw this.fail('Expected digits for an IPv6 address', p);
      }
      if (this.at(q, n, '.')) {
        p--;
        break;
      }
      if (q > p + 4) {
        throw this.fail('IPv6 hexadecimal digit sequence too long', p);
      }
      this.ipv6byteCount += 2;
      p = q;
    }
    return p;
  }
}
