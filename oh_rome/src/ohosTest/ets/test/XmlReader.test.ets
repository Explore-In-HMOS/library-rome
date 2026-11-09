import { util } from '@kit.ArkTS';
import { describe, it, expect } from '@ohos/hypium';
import { decodeAs, XmlReader } from '../../../main/ets/io/XmlReader';
import { XmlReaderException } from '../../../main/ets/io/XmlReaderException';

const TURKISH = '\u011F\u00FC\u015F\u0130\u0131\u00E7\u011E\u00DC\u015E\u00D6\u00F6\u00C7';

function utf8(s: string): number[] {
  return Array.from(util.TextEncoder.create('utf-8').encodeInto(s));
}

function utf16(s: string, bigEndian: boolean): number[] {
  const out: number[] = [];
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (bigEndian) {
      out.push(c >> 8, c & 0xFF);
    } else {
      out.push(c & 0xFF, c >> 8);
    }
  }
  return out;
}

function ascii(s: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < s.length; i++) {
    out.push(s.charCodeAt(i));
  }
  return out;
}

function decode(bytes: number[], encoding: string): string {
  try {
    return decodeAs(new Uint8Array(bytes), encoding);
  } catch (e) {
    return `Error: ${(e as Error).message}`;
  }
}

export default function xmlReaderDecodingTest() {
  describe('XmlReaderDecoding', () => {
    it('utf8WithoutBom', 0, () => {
      const xml = `<?xml version="1.0" encoding="UTF-8"?><a>${TURKISH} \u20AC \uD83D\uDE00</a>`;
      const reader = new XmlReader(new Uint8Array(utf8(xml)));
      expect(reader.encoding).assertEqual('UTF-8');
      expect(reader.read()).assertEqual(xml);
    });

    it('utf8WithBom', 0, () => {
      const xml = `<?xml version="1.0"?><a>${TURKISH}</a>`;
      const reader = new XmlReader(new Uint8Array([0xEF, 0xBB, 0xBF].concat(utf8(xml))));
      expect(reader.encoding).assertEqual('UTF-8');
      expect(reader.read()).assertEqual(xml);
    });

    it('utf16BeWithBom', 0, () => {
      const xml = `<?xml version="1.0" encoding="UTF-16"?><a>${TURKISH} \uD83D\uDE00</a>`;
      const reader = new XmlReader(new Uint8Array([0xFE, 0xFF].concat(utf16(xml, true))));
      expect(reader.encoding).assertEqual('UTF-16BE');
      expect(reader.read()).assertEqual(xml);
    });

    it('utf16LeWithBom', 0, () => {
      const xml = `<?xml version="1.0" encoding="UTF-16"?><a>${TURKISH}</a>`;
      const reader = new XmlReader(new Uint8Array([0xFF, 0xFE].concat(utf16(xml, false))));
      expect(reader.encoding).assertEqual('UTF-16LE');
      expect(reader.read()).assertEqual(xml);
    });

    it('utf16FromLenientHttp', 0, () => {
      const xml = `<?xml version="1.0" encoding="UTF-16"?><a>${TURKISH}</a>`;
      const reader = new XmlReader(new Uint8Array([0xFE, 0xFF].concat(utf16(xml, true))), 'text/xml;charset=UTF-16', true);
      expect(reader.encoding).assertEqual('UTF-16');
      expect(reader.read()).assertEqual(xml);
    });

    it('iso88591', 0, () => {
      const xml = '<?xml version="1.0" encoding="ISO-8859-1"?><a>\u00E9\u00F1\u00FC\u00DF\u0080\u00FF</a>';
      const reader = new XmlReader(new Uint8Array(ascii(xml)));
      expect(reader.encoding).assertEqual('ISO-8859-1');
      expect(reader.read()).assertEqual(xml);
    });

    it('windows1254', 0, () => {
      const head = '<?xml version="1.0" encoding="windows-1254"?><a>';
      const body = [0xF0, 0xFC, 0xFE, 0xDD, 0xFD, 0xE7, 0xD0, 0xDC, 0xDE, 0xD6, 0xF6, 0xC7];
      const reader = new XmlReader(new Uint8Array(ascii(head).concat(body, ascii('</a>'))));
      expect(reader.encoding).assertEqual('WINDOWS-1254');
      expect(reader.read()).assertEqual(`${head}${TURKISH}</a>`);
    });

    it('bomPrologMismatchThrows', 0, () => {
      const bytes = new Uint8Array([0xEF, 0xBB, 0xBF].concat(ascii('<?xml version="1.0" encoding="ISO-8859-1"?><a/>')));
      let message = '';
      try {
        new XmlReader(bytes, null, false);
      } catch (e) {
        message = e instanceof XmlReaderException ? e.message : 'not an XmlReaderException';
      }
      expect(message).assertEqual('Invalid encoding, BOM [UTF-8] XML guess [UTF-8] XML prolog [ISO-8859-1] encoding mismatch');
      expect(new XmlReader(bytes).encoding).assertEqual('ISO-8859-1');
    });

    it('unsupportedEncodingThrowsOnRead', 0, () => {
      const reader = new XmlReader(new Uint8Array(ascii('<?xml version="1.0" encoding="X-NO-SUCH"?><a/>')));
      expect(reader.encoding).assertEqual('X-NO-SUCH');
      let message = '';
      try {
        reader.read();
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('X-NO-SUCH');
    });

    // Expected values from tools/xmlreader-oracle (Java 17.0.17).
    it('decodesLikeJava', 0, () => {
      expect(decode([0x80, 0x81, 0x8D, 0x8F, 0x90, 0x9D, 0x9F], 'windows-1252')).assertEqual('\u20AC\uFFFD\uFFFD\uFFFD\uFFFD\uFFFD\u0178');
      expect(decode([0x5C, 0x7E, 0x80, 0xA0, 0xFD], 'Shift_JIS')).assertEqual('\\~\uFFFD\uFFFD\uFFFD');
      expect(decode([0x82, 0xA0, 0x93, 0xFA, 0x96, 0x7B], 'Shift_JIS')).assertEqual('\u3042\u65E5\u672C');
      expect(decode([0x3C, 0xED, 0xA0, 0x80, 0x3E], 'UTF-8')).assertEqual('<\uFFFD>');
      expect(decode([0x3C, 0x61, 0x3E], 'X-UNKNOWN')).assertEqual('Error: X-UNKNOWN');
      expect(decode([0x3C, 0x61, 0x3E], 'windows-31j')).assertEqual('Error: windows-31j: charset windows-31j is not supported by this port');
      expect(decode([0x41, 0x1A, 0x42], 'Shift_JIS')).assertEqual('A\u001AB');
      expect(decode([0x41, 0x1C, 0x42], 'Shift_JIS')).assertEqual('A\u001CB');
      expect(decode([0x41, 0x7F, 0x42], 'Shift_JIS')).assertEqual('A\u007FB');
      expect(decode([0x93, 0xFA, 0x1A, 0x1C, 0x7F, 0x41, 0x3C, 0x93, 0xFA], 'Shift_JIS')).assertEqual('\u65E5\u001A\u001C\u007FA<\u65E5');
      expect(decode([0xC6, 0xFC, 0x1A, 0x1C, 0x7F, 0x41, 0x3C, 0xC6, 0xFC], 'EUC-JP')).assertEqual('\u65E5\u001A\u001C\u007FA<\u65E5');
      expect(decode([0xC8, 0xD5, 0x1A, 0x1C, 0x7F, 0x41, 0x3C, 0xC8, 0xD5], 'GBK')).assertEqual('\u65E5\u001A\u001C\u007FA<\u65E5');
      expect(decode([0xC8, 0xD5, 0x1A, 0x1C, 0x7F, 0x41, 0x3C, 0xC8, 0xD5, 0x81, 0x30, 0x84, 0x36, 0x1A], 'GB18030')).assertEqual('\u65E5\u001A\u001C\u007FA<\u65E5\u00A5\u001A');
      expect(decode([0xC8, 0xD5, 0x1A, 0x1C, 0x7F, 0x41, 0x3C, 0xC8, 0xD5], 'GB2312')).assertEqual('\u65E5\u001A\u001C\u007FA<\u65E5');
      expect(decode([0xA4, 0xE9, 0x1A, 0x1C, 0x7F, 0x41, 0x3C, 0xA4, 0xE9], 'Big5')).assertEqual('\u65E5\u001A\u001C\u007FA<\u65E5');
      expect(decode([0xEC, 0xED, 0x1A, 0x1C, 0x7F, 0x41, 0x3C, 0xEC, 0xED], 'EUC-KR')).assertEqual('\u65E5\u001A\u001C\u007FA<\u65E5');
    });
  });
}
