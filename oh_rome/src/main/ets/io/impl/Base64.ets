// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/Base64.java (Apache-2.0)
import { IllegalArgumentException } from '../../utils/Exceptions';

const ALPHASET: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';

const I6O2: number = 255 - 3;
const O6I2: number = 3;
const I4O4: number = 255 - 15;
const O4I4: number = 15;
const I2O6: number = 255 - 63;
const O2I6: number = 63;

function buildCodes(): number[] {
  const codes = new Array<number>(256).fill(64);
  for (let i = 0; i < ALPHASET.length; i++) {
    codes[ALPHASET.charCodeAt(i)] = i;
  }
  return codes;
}

const CODES: number[] = buildCodes();

// Java's message for the ArrayIndexOutOfBoundsException that ROME's code runs into on malformed input.
function outOfBounds(index: number, length: number): Error {
  return new Error('Index ' + index + ' out of bounds for length ' + length);
}

// String.getBytes() with Java's default charset, UTF-8; unpaired surrogates become '?'.
function utf8Encode(s: string): Uint8Array {
  const bytes: number[] = [];
  for (let i = 0; i < s.length; i++) {
    let c = s.charCodeAt(i);
    if (c >= 0xd800 && c <= 0xdbff && i + 1 < s.length && s.charCodeAt(i + 1) >= 0xdc00 &&
      s.charCodeAt(i + 1) <= 0xdfff) {
      c = 0x10000 + ((c - 0xd800) << 10) + (s.charCodeAt(i + 1) - 0xdc00);
      i++;
    } else if (c >= 0xd800 && c <= 0xdfff) {
      c = 0x3f;
    }
    if (c < 0x80) {
      bytes.push(c);
    } else if (c < 0x800) {
      bytes.push(0xc0 | (c >> 6), 0x80 | (c & 0x3f));
    } else if (c < 0x10000) {
      bytes.push(0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f));
    } else {
      bytes.push(0xf0 | (c >> 18), 0x80 | ((c >> 12) & 0x3f), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f));
    }
  }
  return new Uint8Array(bytes);
}

function isNotContinuation(b: number): boolean {
  return (b & 0xc0) !== 0x80;
}

function isMalformed3(b1: number, b2: number, b3: number): boolean {
  return (b1 === 0xe0 && (b2 & 0xe0) === 0x80) || isNotContinuation(b2) || isNotContinuation(b3);
}

function isMalformed3x2(b1: number, b2: number): boolean {
  return (b1 === 0xe0 && (b2 & 0xe0) === 0x80) || isNotContinuation(b2);
}

function isMalformed4x2(b1: number, b2: number): boolean {
  return (b1 === 0xf0 && (b2 < 0x90 || b2 > 0xbf)) || (b1 === 0xf4 && (b2 & 0xf0) !== 0x80) || isNotContinuation(b2);
}

function malformed3(src: Uint8Array, sp: number): number {
  const b1 = src[sp];
  const b2 = src[sp + 1];
  return (b1 === 0xe0 && (b2 & 0xe0) === 0x80) || isNotContinuation(b2) ? 1 : 2;
}

function malformed4(src: Uint8Array, sp: number): number {
  const b1 = src[sp];
  const b2 = src[sp + 1];
  if (b1 > 0xf4 || (b1 === 0xf0 && (b2 < 0x90 || b2 > 0xbf)) || (b1 === 0xf4 && (b2 & 0xf0) !== 0x80) ||
    isNotContinuation(b2)) {
    return 1;
  }
  return isNotContinuation(src[sp + 2]) ? 2 : 3;
}

// new String(bytes, UTF_8) as JDK 17's String.decodeUTF8_UTF16 does it, including which malformed bytes
// collapse into one U+FFFD.
function utf8Decode(src: Uint8Array): string {
  const chars: string[] = [];
  const sl = src.length;
  let sp = 0;
  while (sp < sl) {
    const b1 = src[sp++];
    if (b1 < 0x80) {
      chars.push(String.fromCharCode(b1));
    } else if (b1 >= 0xc2 && b1 <= 0xdf) {
      if (sp < sl) {
        const b2 = src[sp++];
        if (isNotContinuation(b2)) {
          chars.push('\ufffd');
          sp--;
        } else {
          chars.push(String.fromCharCode(((b1 & 0x1f) << 6) | (b2 & 0x3f)));
        }
        continue;
      }
      chars.push('\ufffd');
      break;
    } else if (b1 >= 0xe0 && b1 <= 0xef) {
      if (sp + 1 < sl) {
        const b2 = src[sp++];
        const b3 = src[sp++];
        if (isMalformed3(b1, b2, b3)) {
          chars.push('\ufffd');
          sp -= 3;
          sp += malformed3(src, sp);
        } else {
          const c = ((b1 & 0x0f) << 12) | ((b2 & 0x3f) << 6) | (b3 & 0x3f);
          chars.push(c >= 0xd800 && c <= 0xdfff ? '\ufffd' : String.fromCharCode(c));
        }
        continue;
      }
      if (sp < sl && isMalformed3x2(b1, src[sp])) {
        chars.push('\ufffd');
        continue;
      }
      chars.push('\ufffd');
      break;
    } else if (b1 >= 0xf0 && b1 <= 0xf7) {
      if (sp + 2 < sl) {
        const b2 = src[sp++];
        const b3 = src[sp++];
        const b4 = src[sp++];
        const uc = ((b1 & 0x07) << 18) | ((b2 & 0x3f) << 12) | ((b3 & 0x3f) << 6) | (b4 & 0x3f);
        if (isNotContinuation(b2) || isNotContinuation(b3) || isNotContinuation(b4) || uc < 0x10000 ||
          uc > 0x10ffff) {
          chars.push('\ufffd');
          sp -= 4;
          sp += malformed4(src, sp);
        } else {
          chars.push(String.fromCodePoint(uc));
        }
        continue;
      }
      if (b1 > 0xf4 || (sp < sl && isMalformed4x2(b1, src[sp]))) {
        chars.push('\ufffd');
        continue;
      }
      sp++;
      chars.push('\ufffd');
      if (sp < sl && isNotContinuation(src[sp])) {
        continue;
      }
      break;
    } else {
      chars.push('\ufffd');
    }
  }
  return chars.join('');
}

export class Base64 {
  static encode(s: string): string {
    return utf8Decode(Base64.encodeBytes(utf8Encode(s)));
  }

  static decode(s: string): string {
    return utf8Decode(Base64.decodeBytes(utf8Encode(s.replace(/\n/g, '').replace(/\r/g, ''))));
  }

  static encodeBytes(dData: Uint8Array): Uint8Array {
    const eData = new Uint8Array(Math.floor((dData.length + 2) / 3) * 4);
    let eIndex = 0;
    for (let i = 0; i < dData.length; i += 3) {
      const d1 = dData[i];
      let d2 = 0;
      let d3 = 0;
      let pad = 0;
      if (i + 1 < dData.length) {
        d2 = dData[i + 1];
        if (i + 2 < dData.length) {
          d3 = dData[i + 2];
        } else {
          pad = 1;
        }
      } else {
        pad = 2;
      }
      eData[eIndex++] = ALPHASET.charCodeAt((d1 & I6O2) >> 2);
      eData[eIndex++] = ALPHASET.charCodeAt((d1 & O6I2) << 4 | (d2 & I4O4) >> 4);
      eData[eIndex++] = pad < 2 ? ALPHASET.charCodeAt((d2 & O4I4) << 2 | (d3 & I2O6) >> 6) : 61;
      eData[eIndex++] = pad < 1 ? ALPHASET.charCodeAt(d3 & O2I6) : 61;
    }
    return eData;
  }

  // Keeps ROME's quirks: the loop runs over the uncleaned length and reads past the cleaned bytes.
  static decodeBytes(eData: Uint8Array): Uint8Array {
    const cleanEData = eData.slice();
    let cleanELength = 0;
    for (const element of eData) {
      if (element > 127) {
        throw outOfBounds(element - 256, 256);
      }
      if (CODES[element] < 64) {
        cleanEData[cleanELength++] = element;
      }
    }
    let dLength = Math.floor(cleanELength / 4) * 3;
    if (cleanELength % 4 === 3) {
      dLength += 2;
    } else if (cleanELength % 4 === 2) {
      dLength++;
    }
    const dData = new Uint8Array(dLength);
    let dIndex = 0;
    for (let i = 0; i < eData.length; i += 4) {
      if (i + 3 > eData.length) {
        throw new IllegalArgumentException('byte array is not a valid com.rometools.rome.io.impl.Base64 encoding');
      }
      if (i + 3 >= eData.length) {
        throw outOfBounds(i + 3, eData.length);
      }
      const e1 = CODES[cleanEData[i]];
      const e2 = CODES[cleanEData[i + 1]];
      const e3 = CODES[cleanEData[i + 2]];
      const e4 = CODES[cleanEData[i + 3]];
      if (dIndex >= dData.length) {
        throw outOfBounds(dIndex, dData.length);
      }
      dData[dIndex++] = (e1 << 2 | e2 >> 4) & 0xff;
      if (dIndex < dData.length) {
        dData[dIndex++] = (e2 << 4 | e3 >> 2) & 0xff;
      }
      if (dIndex < dData.length) {
        dData[dIndex++] = (e3 << 6 | e4) & 0xff;
      }
    }
    return dData;
  }
}
