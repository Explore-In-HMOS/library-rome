import { describe, it, expect } from '@ohos/hypium';
import { JAVA_CHARSETS, SINGLE_BYTE_TABLES } from '../main/ets/io/JavaCharsets';
import { decodeAs, decodeCjk, decodeUtf8, getXmlProlog, XmlReader } from '../main/ets/io/XmlReader';
import { XmlReaderException } from '../main/ets/io/XmlReaderException';

// Every assertion is pasted from tools/xmlreader-oracle (ROME's XmlReader on JDK 17); ROME's tests only assert some of them.
const XML1 = 'xml';
const XML2 = 'xml-prolog';
const XML3 = 'xml-prolog-encoding-double-quotes';
const XML4 = 'xml-prolog-encoding-single-quotes';
const XML5 = 'xml-prolog-encoding-spaced-single-quotes';

const CP1047_CHARS = SINGLE_BYTE_TABLES[JAVA_CHARSETS.find((cs) => cs.name === 'IBM1047')!.table];

const BOMS = new Map<string, number[]>([
  ['no-bom', []],
  ['UTF-16BE-bom', [0xFE, 0xFF]],
  ['UTF-16LE-bom', [0xFF, 0xFE]],
  ['UTF-16-bom', []],
  ['UTF-8-bom', [0xEF, 0xBB, 0xBF]]
]);

function xmlDoc(xmlType: string, prologEnc: string | null, info: string): string {
  switch (xmlType) {
    case XML1:
      return `<root>${info}</root>`;
    case XML2:
      return `<?xml version="1.0"?>\n<root>${info}</root>`;
    case XML3:
      return `<?xml version="1.0" encoding="${prologEnc}"?>\n<root>${info}</root>`;
    case XML4:
      return `<?xml version="1.0" encoding='${prologEnc}'?>\n<root>${info}</root>`;
    default:
      return `<?xml version="1.0" encoding =  \t \n \r'${prologEnc}'?>\n<root>${info}</root>`;
  }
}

function encode(s: string, encoding: string): number[] {
  const out: number[] = encoding === 'UTF-16' ? [0xFE, 0xFF] : [];
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (encoding === 'CP1047') {
      out.push(CP1047_CHARS.indexOf(s.charAt(i)));
    } else if (encoding === 'UTF-16BE' || encoding === 'UTF-16') {
      out.push(c >> 8, c & 0xFF);
    } else if (encoding === 'UTF-16LE') {
      out.push(c & 0xFF, c >> 8);
    } else if (encoding !== 'UTF-8' || c < 0x80) {
      out.push(c);
    } else if (c < 0x800) {
      out.push(0xC0 | c >> 6, 0x80 | c & 0x3F);
    } else {
      out.push(0xE0 | c >> 12, 0x80 | c >> 6 & 0x3F, 0x80 | c & 0x3F);
    }
  }
  return out;
}

function bytes(s: string, encoding: string): Uint8Array {
  return new Uint8Array(encode(s, encoding));
}

// ROME's padding after the document is left out: detection only reads the first 4096 bytes.
function xmlStream(bomType: string, xmlType: string, streamEnc: string, prologEnc: string | null): Uint8Array {
  const info = `\nBOM : ${bomType}\nDoc : ${xmlType}\nStream Enc : ${prologEnc}\nProlog Enc : {3}\n`;
  return new Uint8Array((BOMS.get(bomType) ?? []).concat(encode(xmlDoc(xmlType, prologEnc, info), streamEnc)));
}

function result(run: () => string | null): string {
  try {
    return `${run()}`;
  } catch (e) {
    const err = e as Error;
    return err instanceof XmlReaderException ? `XmlReaderException: ${err.message}` : `Error: ${err.message}`;
  }
}

function raw(bomType: string, xmlType: string, streamEnc: string, prologEnc: string | null, lenient: boolean): string {
  return result(() => new XmlReader(xmlStream(bomType, xmlType, streamEnc, prologEnc), null, lenient).encoding);
}

function http(cT: string, bomType: string, xmlType: string, streamEnc: string, prologEnc: string | null,
  lenient: boolean, defaultEncoding: string | null): string {
  XmlReader.defaultEncoding = defaultEncoding;
  try {
    return result(() => new XmlReader(xmlStream(bomType, xmlType, streamEnc, prologEnc), cT, lenient).encoding);
  } finally {
    XmlReader.defaultEncoding = null;
  }
}

function prolog(s: string, encoding: string, guessedEnc: string | null): string {
  return result(() => getXmlProlog(bytes(s, encoding), guessedEnc));
}

function decode(bytes: number[], encoding: string): string {
  return result(() => decodeAs(new Uint8Array(bytes), encoding));
}

function cjk(bytes: number[], charset: string): string {
  return decodeCjk(new Uint8Array(bytes), charset, (segment: Uint8Array): string =>
    `[${Array.from(segment).map((b: number): string => b.toString(16).toUpperCase().padStart(2, '0')).join(' ')}]`);
}

function utf8(bytes: number[]): string {
  return result(() => decodeUtf8(new Uint8Array(bytes)));
}

function raw4096(head: string, bom: boolean): string {
  return result(() => new XmlReader(bytes(bom ? `\uFEFF${head}` : head, 'UTF-8'), null, false).encoding);
}

export default function xmlReaderTest() {
  describe('XmlReader', () => {
    it('rawNoBom', 0, () => {
      expect(raw('no-bom', XML1, 'US-ASCII', 'US-ASCII', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML2, 'US-ASCII', 'US-ASCII', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML3, 'US-ASCII', 'US-ASCII', false)).assertEqual('US-ASCII');
      expect(raw('no-bom', XML4, 'US-ASCII', 'US-ASCII', false)).assertEqual('US-ASCII');
      expect(raw('no-bom', XML5, 'US-ASCII', 'US-ASCII', false)).assertEqual('US-ASCII');
      expect(raw('no-bom', XML1, 'UTF-8', 'UTF-8', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML2, 'UTF-8', 'UTF-8', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML3, 'UTF-8', 'UTF-8', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML4, 'UTF-8', 'UTF-8', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML5, 'UTF-8', 'UTF-8', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML1, 'ISO-8859-1', 'ISO-8859-1', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML2, 'ISO-8859-1', 'ISO-8859-1', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML3, 'ISO-8859-1', 'ISO-8859-1', false)).assertEqual('ISO-8859-1');
      expect(raw('no-bom', XML4, 'ISO-8859-1', 'ISO-8859-1', false)).assertEqual('ISO-8859-1');
      expect(raw('no-bom', XML5, 'ISO-8859-1', 'ISO-8859-1', false)).assertEqual('ISO-8859-1');
      expect(raw('no-bom', XML1, 'CP1047', 'CP1047', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML2, 'CP1047', 'CP1047', false)).assertEqual('UTF-8');
      expect(raw('no-bom', XML3, 'CP1047', 'CP1047', false)).assertEqual('CP1047');
      expect(raw('no-bom', XML4, 'CP1047', 'CP1047', false)).assertEqual('CP1047');
      expect(raw('no-bom', XML5, 'CP1047', 'CP1047', false)).assertEqual('CP1047');
    });

    it('rawBom', 0, () => {
      expect(raw('UTF-8-bom', XML3, 'UTF-8', 'UTF-8', false)).assertEqual('UTF-8');
      expect(raw('UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16BE', false)).assertEqual('UTF-16BE');
      expect(raw('UTF-16LE-bom', XML3, 'UTF-16LE', 'UTF-16LE', false)).assertEqual('UTF-16LE');
      expect(raw('UTF-16-bom', XML3, 'UTF-16', 'UTF-16', false)).assertEqual('UTF-16BE');
      expect(raw('UTF-8-bom', XML3, 'US-ASCII', 'US-ASCII', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-8] XML guess [UTF-8] XML prolog [US-ASCII] encoding mismatch');
      expect(raw('UTF-8-bom', XML3, 'ISO-8859-1', 'ISO-8859-1', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-8] XML guess [UTF-8] XML prolog [ISO-8859-1] encoding mismatch');
      expect(raw('UTF-8-bom', XML3, 'UTF-8', 'UTF-16', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-8] XML guess [UTF-8] XML prolog [UTF-16] encoding mismatch');
      expect(raw('UTF-8-bom', XML3, 'UTF-8', 'UTF-16BE', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-8] XML guess [UTF-8] XML prolog [UTF-16BE] encoding mismatch');
      expect(raw('UTF-8-bom', XML3, 'UTF-8', 'UTF-16LE', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-8] XML guess [UTF-8] XML prolog [UTF-16LE] encoding mismatch');
      expect(raw('UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16LE', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-16BE] XML guess [UTF-16BE] XML prolog [UTF-16LE] encoding mismatch');
      expect(raw('UTF-16LE-bom', XML3, 'UTF-16LE', 'UTF-16BE', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-16LE] XML guess [UTF-16LE] XML prolog [UTF-16BE] encoding mismatch');
      expect(raw('UTF-16LE-bom', XML3, 'UTF-16LE', 'UTF-8', false)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-16LE] XML guess [UTF-16LE] XML prolog [UTF-8] encoding mismatch');
    });

    it('http', 0, () => {
      expect(http('application/xml', 'no-bom', XML1, 'US-ASCII', null, false, null)).assertEqual('UTF-8');
      expect(http('application/xml', 'UTF-8-bom', XML1, 'US-ASCII', null, false, null)).assertEqual('UTF-8');
      expect(http('application/xml', 'UTF-8-bom', XML1, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('application/xml', 'UTF-8-bom', XML3, 'UTF-8', 'UTF-8', false, null)).assertEqual('UTF-8');
      expect(http('application/xml;charset=UTF-8', 'UTF-8-bom', XML1, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('application/xml;charset="UTF-8"', 'UTF-8-bom', XML1, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('application/xml;charset=\'UTF-8\'', 'UTF-8-bom', XML1, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('application/xml;charset=UTF-8', 'UTF-8-bom', XML3, 'UTF-8', 'UTF-8', false, null)).assertEqual('UTF-8');
      expect(http('application/xml;charset=UTF-16', 'UTF-16BE-bom', XML1, 'UTF-16BE', null, false, null)).assertEqual('UTF-16BE');
      expect(http('application/xml;charset=UTF-16', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16', false, null)).assertEqual('UTF-16BE');
      expect(http('application/xml;charset=UTF-16', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16BE', false, null)).assertEqual('UTF-16BE');
      expect(http('application/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML2, 'UTF-16BE', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [application/xml] CT-Enc [UTF-16BE] BOM [UTF-16BE] XML guess [UTF-16BE] XML prolog [null], BOM must be NULL');
      expect(http('application/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [application/xml] CT-Enc [UTF-16BE] BOM [UTF-16BE] XML guess [UTF-16BE] XML prolog [UTF-16], BOM must be NULL');
      expect(http('application/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16BE', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [application/xml] CT-Enc [UTF-16BE] BOM [UTF-16BE] XML guess [UTF-16BE] XML prolog [UTF-16BE], BOM must be NULL');
      expect(http('application/xml', 'UTF-8-bom', XML3, 'US-ASCII', 'US-ASCII', false, null)).assertEqual('XmlReaderException: Invalid encoding, BOM [UTF-8] XML guess [UTF-8] XML prolog [US-ASCII] encoding mismatch');
      expect(http('application/xml;charset=UTF-16', 'UTF-16LE', XML3, 'UTF-8', 'UTF-8', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [application/xml] CT-Enc [UTF-16] BOM [null] XML guess [UTF-8] XML prolog [UTF-8], encoding mismatch');
      expect(http('application/xml;charset=UTF-16', 'no-bom', XML3, 'UTF-16BE', 'UTF-16BE', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [application/xml] CT-Enc [UTF-16] BOM [null] XML guess [UTF-16BE] XML prolog [UTF-16BE], encoding mismatch');
      expect(http('text/xml', 'no-bom', XML1, 'US-ASCII', null, false, null)).assertEqual('US-ASCII');
      expect(http('text/xml;charset=UTF-8', 'UTF-8-bom', XML3, 'UTF-8', 'UTF-8', false, null)).assertEqual('UTF-8');
      expect(http('text/xml;charset=UTF-8', 'UTF-8-bom', XML1, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('text/xml;charset=UTF-16', 'UTF-16BE-bom', XML1, 'UTF-16BE', null, false, null)).assertEqual('UTF-16BE');
      expect(http('text/xml;charset=UTF-16', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16', false, null)).assertEqual('UTF-16BE');
      expect(http('text/xml;charset=UTF-16', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16BE', false, null)).assertEqual('UTF-16BE');
      expect(http('text/xml', 'UTF-8-bom', XML1, 'US-ASCII', null, false, null)).assertEqual('US-ASCII');
      expect(http('application/xml', 'UTF-8-bom', XML1, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('application/xml', 'no-bom', XML1, 'US-ASCII', null, false, 'US-ASCII')).assertEqual('US-ASCII');
      expect(http('application/xml', 'UTF-8-bom', XML1, 'UTF-8', null, false, 'UTF-8')).assertEqual('UTF-8');
      expect(http('text/xml', 'no-bom', XML1, 'US-ASCII', null, false, null)).assertEqual('US-ASCII');
      expect(http('text/xml', 'no-bom', XML1, 'US-ASCII', null, false, 'US-ASCII')).assertEqual('US-ASCII');
      expect(http('text/xml', 'no-bom', XML1, 'US-ASCII', null, false, 'UTF-8')).assertEqual('UTF-8');
      expect(http('text/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML2, 'UTF-16BE', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml] CT-Enc [UTF-16BE] BOM [UTF-16BE] XML guess [UTF-16BE] XML prolog [null], BOM must be NULL');
      expect(http('text/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml] CT-Enc [UTF-16BE] BOM [UTF-16BE] XML guess [UTF-16BE] XML prolog [UTF-16], BOM must be NULL');
      expect(http('text/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16BE', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml] CT-Enc [UTF-16BE] BOM [UTF-16BE] XML guess [UTF-16BE] XML prolog [UTF-16BE], BOM must be NULL');
      expect(http('text/xml;charset=UTF-16', 'no-bom', XML3, 'UTF-16BE', 'UTF-16BE', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml] CT-Enc [UTF-16] BOM [null] XML guess [UTF-16BE] XML prolog [UTF-16BE], encoding mismatch');
      expect(http('text/xml;charset=UTF-16', 'no-bom', XML2, 'UTF-16BE', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml] CT-Enc [UTF-16] BOM [null] XML guess [UTF-16BE] XML prolog [null], encoding mismatch');
      expect(http('text/xml', 'no-bom', XML2, 'US-ASCII', null, true, null)).assertEqual('US-ASCII');
      expect(http('text/xml;charset=UTF-8', 'UTF-8-bom', XML3, 'UTF-8', 'UTF-8', true, null)).assertEqual('UTF-8');
      expect(http('text/xml;charset=UTF-8', 'UTF-8-bom', XML2, 'UTF-8', null, true, null)).assertEqual('UTF-8');
      expect(http('text/xml;charset=UTF-16', 'UTF-16BE-bom', XML2, 'UTF-16BE', null, true, null)).assertEqual('UTF-16BE');
      expect(http('text/xml;charset=UTF-16', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16', true, null)).assertEqual('UTF-16');
      expect(http('text/xml;charset=UTF-16', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16BE', true, null)).assertEqual('UTF-16BE');
      expect(http('text/xml', 'UTF-8-bom', XML2, 'US-ASCII', null, true, null)).assertEqual('US-ASCII');
      expect(http('text/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML2, 'UTF-16BE', null, true, null)).assertEqual('UTF-16BE');
      expect(http('text/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16', true, null)).assertEqual('UTF-16');
      expect(http('text/xml;charset=UTF-16BE', 'UTF-16BE-bom', XML3, 'UTF-16BE', 'UTF-16BE', true, null)).assertEqual('UTF-16BE');
      expect(http('text/xml;charset=UTF-16', 'no-bom', XML3, 'UTF-16BE', 'UTF-16BE', true, null)).assertEqual('UTF-16BE');
      expect(http('text/xml;charset=UTF-16', 'no-bom', XML2, 'UTF-16BE', null, true, null)).assertEqual('UTF-16');
      expect(http('text/html', 'no-bom', XML3, 'US-ASCII', 'US-ASCII', true, null)).assertEqual('US-ASCII');
      expect(http('text/html', 'no-bom', XML2, 'US-ASCII', null, true, null)).assertEqual('US-ASCII');
      expect(http('text/html;charset=UTF-8', 'no-bom', XML3, 'US-ASCII', 'UTF-8', true, null)).assertEqual('UTF-8');
      expect(http('text/html;charset=UTF-16BE', 'no-bom', XML3, 'US-ASCII', 'UTF-8', true, null)).assertEqual('UTF-8');
    });

    it('encodingAttributeXml', 0, () => {
      const xml = '<?xml version="1.0" ?> \n<atom:feed xmlns:atom="http://www.w3.org/2005/Atom">\n\n  <atom:entry>\n' +
        '    <atom:title encoding="base64"><![CDATA\naW5nTGluZSIgLz4';
      expect(new XmlReader(bytes(xml, 'UTF-8'), '', true).encoding).assertEqual('UTF-8');
    });

    it('httpHeaderContentType', 0, () => {
      const body = '<?xml version="1.0" encoding="utf-8"?><rss version="2.0"><channel/></rss>';
      expect(new XmlReader(bytes(body, 'UTF-8'), 'text/xml').encoding).assertEqual('UTF-8');
    });

    it('getXmlProlog', 0, () => {
      expect(prolog('<?xml encoding="TEST"?>', 'UTF-8', 'UTF-8')).assertEqual('TEST');
      expect(prolog('<?xml encoding="UTF-8"?>', 'UTF-8', 'UTF-8')).assertEqual('UTF-8');
      expect(prolog('<?xml encoding="UTF-16"?>', 'UTF-16', 'UTF-16')).assertEqual('UTF-16');
      expect(prolog('<?xml encoding="CP1047"?>', 'CP1047', 'CP1047')).assertEqual('CP1047');
      expect(prolog('<?xml>', 'UTF-8', 'UTF-8')).assertEqual('null');
      expect(prolog('<?xml encoding="UTF-8"?>', 'UTF-8', null)).assertEqual('null');
      expect(prolog('<?xml encoding="utf-8"?>', 'UTF-8', 'UTF-8')).assertEqual('UTF-8');
      expect(prolog('<?xml encoding="TEST"?>', 'ISO-8859-1', 'UTF-8')).assertEqual('TEST');
      expect(prolog('<?xml encoding="TEST"?>', 'UTF-16BE', 'UTF-16LE')).assertEqual('Error: Unexpected end of XML stream');
      expect(prolog('<?xml encoding="TEST"', 'UTF-8', 'UTF-8')).assertEqual('Error: Unexpected end of XML stream');
      expect(prolog('', 'UTF-8', 'UTF-8')).assertEqual('Error: Unexpected end of XML stream');
      expect(prolog(`<?xml encoding="TEST"?${' '.repeat(5000)}>`, 'UTF-8', 'UTF-8')).assertEqual('Error: XML prolog or ROOT element not found on first 4096 bytes');
    });

    it('prologBufferBoundary', 0, () => {
      const head = (size: number): string => `<?xml encoding="TEST"${' '.repeat(size - 21)}`;
      expect(raw4096(head(4095), false)).assertEqual('Error: Unexpected end of XML stream');
      expect(raw4096(head(4096), false)).assertEqual('Error: XML prolog or ROOT element not found on first 4096 bytes');
      expect(raw4096(head(4096), true)).assertEqual('Error: XML prolog or ROOT element not found on first 4096 bytes');
      expect(raw4096(head(4097), false)).assertEqual('Error: XML prolog or ROOT element not found on first 4096 bytes');
    });

    it('moreRomeBehavior', 0, () => {
      expect(raw('UTF-8-bom', XML3, 'ISO-8859-1', 'ISO-8859-1', true)).assertEqual('ISO-8859-1');
      expect(raw('UTF-16BE-bom', XML3, 'UTF-16LE', 'UTF-16LE', true)).assertEqual('Error: Invalid encoding, BOM [UTF-16BE] XML guess [UTF-16LE] XML prolog [UTF-16LE] encoding mismatch');
      expect(raw('no-bom', XML3, 'UTF-16LE', 'UTF-16', false)).assertEqual('UTF-16LE');
      expect(raw('no-bom', XML2, 'UTF-8', null, false)).assertEqual('UTF-8');
      expect(http('application/json', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [application/json] CT-Enc [null] BOM [null] XML guess [UTF-8] XML prolog [null], Invalid MIME');
      expect(http('application/json', 'no-bom', XML2, 'UTF-8', null, true, null)).assertEqual('UTF-8');
      expect(http('text/html', 'UTF-8-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/html] CT-Enc [null] BOM [UTF-8] XML guess [UTF-8] XML prolog [null], Invalid MIME');
      expect(http('application/atom+xml', 'no-bom', XML3, 'UTF-8', 'WINDOWS-1254', false, null)).assertEqual('WINDOWS-1254');
      expect(http('text/xml; charset=iso-8859-1 x', 'no-bom', XML1, 'UTF-8', null, false, null)).assertEqual('ISO-8859-1');
      expect(http('text/xml; xcharset=utf-8', 'no-bom', XML1, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('text/xml; charset="', 'no-bom', XML1, 'UTF-8', null, false, null)).assertEqual('Error: begin 1, end 0, length 1');
      expect(prolog('<?xml version="1.0" encoding="a" x encoding = \'b\'?>', 'UTF-8', 'UTF-8')).assertEqual('B');
      expect(prolog('<?xml version="1.0"\u0085 encoding="x"?>', 'UTF-8', 'UTF-8')).assertEqual('null');
      expect(prolog('<?xml version="1.0"\u00A0encoding=\u00A0"x"?>', 'UTF-8', 'UTF-8')).assertEqual('null');
      expect(prolog('<?xml encoding="stra\u00DFe"?>', 'UTF-8', 'UTF-8')).assertEqual('STRASSE');
      expect(prolog('<?xml encoding="\u00E9"?>', 'ISO-8859-1', 'UTF-8')).assertEqual('\uFFFD');
      const doubleBom = new Uint8Array([0xEF, 0xBB, 0xBF, 0xEF, 0xBB, 0xBF, 0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x3E]);
      expect(new XmlReader(doubleBom, 'text/html').encoding).assertEqual('US-ASCII');
    });

    it('readsSingleByteEncodingsWithoutTextDecoder', 0, () => {
      const ascii = new XmlReader(new Uint8Array([0x3C, 0x61, 0x3E, 0xE9]), 'text/xml', false);
      expect(ascii.encoding).assertEqual('US-ASCII');
      expect(ascii.read()).assertEqual('<a>\uFFFD');
      const latin1 = new XmlReader(new Uint8Array([0x3C, 0x61, 0x3E, 0xE9, 0x80]), 'text/xml', false, 'ISO-8859-1');
      expect(latin1.read()).assertEqual('<a>\u00E9\u0080');
      const ebcdic = '<?xml version="1.0" encoding="CP1047"?><a>Hello</a>';
      const cp1047 = new XmlReader(bytes(ebcdic, 'CP1047'), null, false);
      expect(cp1047.encoding).assertEqual('CP1047');
      expect(cp1047.read()).assertEqual(ebcdic);
    });

    it('httpMimeRules', 0, () => {
      expect(http('text/rss+xml', 'no-bom', XML1, 'US-ASCII', null, false, null)).assertEqual('US-ASCII');
      expect(http('text/xml-external-parsed-entity', 'no-bom', XML1, 'US-ASCII', null, false, null)).assertEqual('US-ASCII');
      expect(http('application/xml-external-parsed-entity', 'no-bom', XML3, 'UTF-8', 'UTF-8', false, null)).assertEqual('UTF-8');
      expect(http('application/xml-dtd', 'no-bom', XML3, 'UTF-8', 'UTF-8', false, null)).assertEqual('UTF-8');
      expect(http('text/xml;charset=UTF-16LE', 'UTF-16LE-bom', XML2, 'UTF-16LE', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml] CT-Enc [UTF-16LE] BOM [UTF-16LE] XML guess [UTF-16LE] XML prolog [null], BOM must be NULL');
      expect(http('application/xml;charset=UTF-16LE', 'UTF-16LE-bom', XML3, 'UTF-16LE', 'UTF-16LE', false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [application/xml] CT-Enc [UTF-16LE] BOM [UTF-16LE] XML guess [UTF-16LE] XML prolog [UTF-16LE], BOM must be NULL');
      expect(http('text/xml;charset=UTF-16', 'UTF-8-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml] CT-Enc [UTF-16] BOM [UTF-8] XML guess [UTF-8] XML prolog [null], encoding mismatch');
      expect(http('text/xml;charset=UTF-16', 'UTF-16LE-bom', XML2, 'UTF-16LE', null, false, null)).assertEqual('UTF-16LE');
      expect(http(' text/xml', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('US-ASCII');
      expect(http('text/xml ', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('US-ASCII');
      expect(http('\ttext/xml\r\n', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('US-ASCII');
      expect(http('text/xml ;charset=UTF-8', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('UTF-8');
      expect(http('\u00A0text/xml', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [\u00A0text/xml] CT-Enc [null] BOM [null] XML guess [UTF-8] XML prolog [null], Invalid MIME');
      expect(http('text/xml\u00A0', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml\u00A0] CT-Enc [null] BOM [null] XML guess [UTF-8] XML prolog [null], Invalid MIME');
      expect(http('text/xml\u3000', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml\u3000] CT-Enc [null] BOM [null] XML guess [UTF-8] XML prolog [null], Invalid MIME');
      expect(http('\uFEFFtext/xml', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [\uFEFFtext/xml] CT-Enc [null] BOM [null] XML guess [UTF-8] XML prolog [null], Invalid MIME');
      expect(http('text/xml\u2028', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('XmlReaderException: Invalid encoding, CT-MIME [text/xml\u2028] CT-Enc [null] BOM [null] XML guess [UTF-8] XML prolog [null], Invalid MIME');
      expect(http('text/xml\u0001', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('US-ASCII');
      expect(http('\u001Ftext/xml\u001F', 'no-bom', XML2, 'UTF-8', null, false, null)).assertEqual('US-ASCII');
    });

    it('decodesLikeInputStreamReader', 0, () => {
      expect(decode([0x3C, 0x61, 0x3E], '')).assertEqual('Error: ');
      expect(decode([0x3C, 0x61, 0x3E], '"UTF-8')).assertEqual('Error: "UTF-8');
      expect(decode([0x3C, 0x61, 0x3E], 'UTF-8\n')).assertEqual('Error: UTF-8\n');
      expect(decode([0x3C, 0x61, 0x3E], ' UTF-8')).assertEqual('Error:  UTF-8');
      expect(decode([0x3C, 0x61, 0x3E], 'UTF-16 ')).assertEqual('Error: UTF-16 ');
      expect(decode([0x3C, 0x61, 0x3E], '\u0005UTF-8')).assertEqual('Error: \u0005UTF-8');
      expect(decode([0x3C, 0x61, 0x3E], 'macintosh')).assertEqual('Error: macintosh');
      expect(decode([0x3C, 0x61, 0x3E], 'MACINTOSH')).assertEqual('Error: MACINTOSH');
      expect(decode([0x3C, 0x61, 0x3E], 'SS')).assertEqual('Error: SS');
      expect(decode([0x3C, 0x61, 0x3E], 'STRASSE')).assertEqual('Error: STRASSE');
      expect(decode([0x3C, 0x61, 0x3E], 'X-UNKNOWN')).assertEqual('Error: X-UNKNOWN');
      expect(decode([0x3C, 0x61, 0x3E], '\u212Aoi8-r')).assertEqual('Error: \u212Aoi8-r');
      expect(decode([0x80, 0x81, 0x8D, 0x8F, 0x90, 0x9D, 0x9F], 'windows-1252')).assertEqual('\u20AC\uFFFD\uFFFD\uFFFD\uFFFD\uFFFD\u0178');
      expect(decode([0x80, 0x81, 0x8D, 0x8F, 0x90, 0x9D, 0x9F], 'CP1252')).assertEqual('\u20AC\uFFFD\uFFFD\uFFFD\uFFFD\uFFFD\u0178');
      expect(decode([0x80, 0x8E, 0x9E, 0xD0, 0xDD, 0xDE, 0xF0, 0xFD, 0xFE], 'windows-1254')).assertEqual('\u20AC\uFFFD\uFFFD\u011E\u0130\u015E\u011F\u0131\u015F');
      expect(decode([0x3C, 0xE9, 0x80], 'ISO-8859-1')).assertEqual('<\u00E9\u0080');
      expect(decode([0x3C, 0xE9, 0x80], 'latin1')).assertEqual('<\u00E9\u0080');
      expect(decode([0x41, 0xE9], 'US-ASCII')).assertEqual('A\uFFFD');
      expect(decode([0x41, 0xE9], 'ascii')).assertEqual('A\uFFFD');
      expect(decode([0xC1, 0xE2, 0xF7, 0x9F], 'KOI8-R')).assertEqual('\u0430\u0411\u0412\u00F7');
      expect(decode([0x4C, 0x6F, 0xA7, 0x94, 0x15], 'ibm-1047')).assertEqual('<?xm\n');
      expect(decode([0x80, 0xA5, 0xF0], 'x-MacRoman')).assertEqual('\u00C4\u2022\uF8FF');
      expect(decode([0xA1, 0xBF, 0xE0, 0xFB], 'ISO-8859-8')).assertEqual('\uFFFD\uFFFD\u05D0\uFFFD');
      expect(decode([0x80, 0xB0, 0xFF], 'IBM437')).assertEqual('\u00C7\u2591\u00A0');
      expect(decode([0xA4, 0xBE], 'ISO-8859-15')).assertEqual('\u20AC\u0178');
      expect(decode([0xD8, 0x3D, 0x00, 0x3C], 'UTF-16BE')).assertEqual('\uFFFD');
      expect(decode([0xD8, 0x3D, 0xDE, 0x00, 0xDC, 0x00, 0x00, 0x41], 'UTF-16BE')).assertEqual('\uD83D\uDE00\uFFFDA');
      expect(decode([0xFF, 0xFE, 0x00, 0x41, 0xFE, 0xFF], 'UTF-16BE')).assertEqual('\uFFFEA\uFEFF');
      expect(decode([0x00, 0x41, 0xD8, 0x3D], 'UTF-16BE')).assertEqual('A\uFFFD');
      expect(decode([0x00, 0x41, 0xD8, 0x3D, 0x00], 'UTF-16BE')).assertEqual('A\uFFFD');
      expect(decode([0x00, 0x41, 0x00], 'UTF-16BE')).assertEqual('A\uFFFD');
      expect(decode([0x3D, 0xD8, 0x3C, 0x00], 'UTF-16LE')).assertEqual('\uFFFD');
      expect(decode([0xFE, 0xFF, 0x00, 0x41], 'UTF-16LE')).assertEqual('\uFFFE\u4100');
      expect(decode([0xFE, 0xFF, 0x00, 0x41, 0xFE, 0xFF], 'UTF-16')).assertEqual('A\uFEFF');
      expect(decode([0xFF, 0xFE, 0x41, 0x00, 0xFF, 0xFE], 'UTF-16')).assertEqual('A\uFEFF');
      expect(decode([0x00, 0x41, 0xFF, 0xFE], 'UTF-16')).assertEqual('A\uFFFE');
      expect(decode([0xFE], 'UTF-16')).assertEqual('\uFFFD');
      expect(decode([0x00, 0x00, 0xFE, 0xFF, 0x00, 0x01, 0xF6, 0x00], 'UTF-32')).assertEqual('\uD83D\uDE00');
      expect(decode([0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00], 'UTF-32')).assertEqual('A');
      expect(decode([0x00, 0x00, 0x00, 0x41, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0xD8, 0x00, 0x00], 'UTF-32')).assertEqual('A\uFFFD\uD800\uFFFD');
      expect(decode([0x00, 0x00, 0xFE, 0xFF, 0x00, 0x00, 0x00, 0x41], 'UTF-32BE')).assertEqual('A');
      expect(decode([0xFF, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41], 'UTF-32BE')).assertEqual('\uFFFDA');
      expect(decode([0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00], 'UTF-32LE')).assertEqual('A');
      expect(decode([0x00, 0x00, 0xFE, 0xFF, 0x41, 0x00, 0x00, 0x00], 'UTF-32LE')).assertEqual('\uFFFDA');
      expect(decode([0x00, 0x00, 0x00], 'UTF-32')).assertEqual('\uFFFD');
      expect(decode([0x3C, 0x61, 0x3E], 'windows-31j')).assertEqual('Error: windows-31j: charset windows-31j is not supported by this port');
      expect(decode([0x3C, 0x61, 0x3E], 'x-windows-949')).assertEqual('Error: x-windows-949: charset x-windows-949 is not supported by this port');
      expect(decode([0x3C, 0x61, 0x3E], 'Big5-HKSCS')).assertEqual('Error: Big5-HKSCS: charset Big5-HKSCS is not supported by this port');
      expect(decode([0x3C, 0x61, 0x3E], 'ISO-2022-KR')).assertEqual('Error: ISO-2022-KR: charset ISO-2022-KR is not supported by this port');
      expect(decode([0x3C, 0x61, 0x3E], 'CESU-8')).assertEqual('Error: CESU-8: charset CESU-8 is not supported by this port');
      expect(decode([0x3C, 0x61, 0x3E], 'x-UTF-16LE-BOM')).assertEqual('Error: x-UTF-16LE-BOM: charset x-UTF-16LE-BOM is not supported by this port');
    });

    // Expected values from tools/xmlreader-oracle/CjkSplit.java; [..] is a segment left to util.TextDecoder.
    it('cjkAsciiLikeJava', 0, () => {
      expect(cjk([0x41, 0x1A, 0x42], 'Shift_JIS')).assertEqual('[41]\u001A[42]');
      expect(cjk([0x41, 0x1C, 0x42], 'Shift_JIS')).assertEqual('[41]\u001C[42]');
      expect(cjk([0x41, 0x7F, 0x42], 'Shift_JIS')).assertEqual('[41]\u007F[42]');
      expect(cjk([0x93, 0xFA, 0x1A, 0x93, 0xFA], 'Shift_JIS')).assertEqual('[93 FA]\u001A[93 FA]');
      expect(cjk([0x3C, 0x61, 0x3E], 'Shift_JIS')).assertEqual('<[61]>');
      expect(cjk([0x81, 0x40, 0x3C, 0x85, 0x41, 0x7F, 0x80], 'Shift_JIS')).assertEqual('[81 40]<[85 41]\u007F[80]');
      expect(cjk([0xC6, 0xFC, 0x1A, 0x41], 'EUC-JP')).assertEqual('[C6 FC]\u001AA');
      expect(cjk([0x8F, 0xB0, 0xA1, 0x1A], 'EUC-JP')).assertEqual('[8F B0 A1]\u001A');
      expect(cjk([0xB0, 0x1A, 0x42], 'EUC-JP')).assertEqual('[B0 1A]B');
      expect(cjk([0x8E, 0xB1, 0x3C, 0x8F, 0x41], 'EUC-JP')).assertEqual('[8E B1]<[8F 41]');
      expect(cjk([0xC8, 0xD5, 0x1A, 0x7F, 0x41], 'GBK')).assertEqual('[C8 D5]\u001A\u007F[41]');
      expect(cjk([0x81, 0x40, 0x3E, 0x80], 'GBK')).assertEqual('[81 40]>[80]');
      expect(cjk([0x81, 0x30, 0x87, 0x30, 0x1A], 'GB18030')).assertEqual('[81 30 87 30]\u001A');
      expect(cjk([0x81, 0x30, 0x1A, 0x42, 0x43], 'GB18030')).assertEqual('[81 30 1A]BC');
      expect(cjk([0x81, 0x3C, 0x41, 0x81, 0x1A], 'GB18030')).assertEqual('[81 3C]A[81]\u001A');
      expect(cjk([0xC8, 0xD5, 0x1A], 'GB18030')).assertEqual('[C8 D5]\u001A');
      expect(cjk([0x80, 0x1A, 0xFF, 0x41], 'GB18030')).assertEqual('[80]\u001A[FF]A');
      expect(cjk([0xC8, 0xD5, 0x41, 0x1A], 'GB2312')).assertEqual('[C8 D5]A\u001A');
      expect(cjk([0xB0, 0x41, 0x7F], 'GB2312')).assertEqual('[B0]A\u007F');
      expect(cjk([0xA4, 0xE9, 0x1A, 0x41, 0x7F], 'Big5')).assertEqual('[A4 E9]\u001A[41]\u007F');
      expect(cjk([0xC0, 0xCF, 0x41, 0x1A], 'EUC-KR')).assertEqual('[C0 CF]A\u001A');
    });

    it('utf8LikeJava', 0, () => {
      expect(utf8([0xED, 0xA0, 0x80])).assertEqual('\uFFFD');
      expect(utf8([0xED, 0xA0, 0x80, 0x3C])).assertEqual('\uFFFD<');
      expect(utf8([0xED, 0xBF, 0xBF])).assertEqual('\uFFFD');
      expect(utf8([0xC0, 0xAF])).assertEqual('\uFFFD\uFFFD');
      expect(utf8([0xC1, 0xBF])).assertEqual('\uFFFD\uFFFD');
      expect(utf8([0xC2])).assertEqual('\uFFFD');
      expect(utf8([0xC2, 0x3C])).assertEqual('\uFFFD<');
      expect(utf8([0xE2, 0x82])).assertEqual('\uFFFD');
      expect(utf8([0xE2, 0x82, 0x3C])).assertEqual('\uFFFD<');
      expect(utf8([0xE2, 0x28, 0xA1])).assertEqual('\uFFFD(\uFFFD');
      expect(utf8([0xE0, 0x80, 0x80])).assertEqual('\uFFFD\uFFFD\uFFFD');
      expect(utf8([0xE0, 0xA0])).assertEqual('\uFFFD');
      expect(utf8([0xE0, 0x9F, 0x80])).assertEqual('\uFFFD\uFFFD\uFFFD');
      expect(utf8([0xF0, 0x90, 0x80])).assertEqual('\uFFFD');
      expect(utf8([0xF0, 0x90, 0x80, 0x3C])).assertEqual('\uFFFD<');
      expect(utf8([0xF0, 0x80, 0x80, 0x80])).assertEqual('\uFFFD\uFFFD\uFFFD\uFFFD');
      expect(utf8([0xF0, 0x8F])).assertEqual('\uFFFD\uFFFD');
      expect(utf8([0xF4, 0x90, 0x80, 0x80])).assertEqual('\uFFFD\uFFFD\uFFFD\uFFFD');
      expect(utf8([0xF4, 0x8F, 0xBF, 0xBF])).assertEqual('\uDBFF\uDFFF');
      expect(utf8([0xF5, 0x80, 0x80, 0x80])).assertEqual('\uFFFD\uFFFD\uFFFD\uFFFD');
      expect(utf8([0xF7, 0xBF])).assertEqual('\uFFFD\uFFFD');
      expect(utf8([0xF8, 0x88, 0x80, 0x80, 0x80])).assertEqual('\uFFFD\uFFFD\uFFFD\uFFFD\uFFFD');
      expect(utf8([0x80, 0xBF])).assertEqual('\uFFFD\uFFFD');
      expect(utf8([0xF0, 0x28, 0x8C, 0xBC])).assertEqual('\uFFFD(\uFFFD\uFFFD');
      expect(utf8([0xF0, 0x90, 0x28, 0xBC])).assertEqual('\uFFFD(\uFFFD');
      expect(utf8([0xF0, 0x90, 0x8C, 0x28])).assertEqual('\uFFFD(');
      expect(utf8([0xF1, 0x80, 0x80])).assertEqual('\uFFFD');
      expect(utf8([0xF1, 0x80])).assertEqual('\uFFFD');
      expect(utf8([0xEF, 0xBF, 0xBD])).assertEqual('\uFFFD');
      expect(utf8([0xF0, 0x9F, 0x98, 0x80])).assertEqual('\uD83D\uDE00');
      expect(utf8([0xC3, 0xA9, 0x3C])).assertEqual('\u00E9<');
      expect(utf8([0xFF, 0xFE])).assertEqual('\uFFFD\uFFFD');
      expect(utf8([0xE2, 0x82, 0xAC, 0x41])).assertEqual('\u20ACA');
      expect(result(() => getXmlProlog(new Uint8Array([0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x65, 0x6E, 0x63, 0x6F, 0x64, 0x69, 0x6E, 0x67, 0x3D, 0x22, 0xED, 0xA0, 0x80, 0x22, 0x3F, 0x3E]), 'UTF-8'))).assertEqual('\uFFFD');
    });
  });
}
