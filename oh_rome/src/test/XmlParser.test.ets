import { describe, it, expect } from '@ohos/hypium';
import {
  Attribute, CDATA, Comment, Content, DocType, Document, Element, EntityRef, Namespace, ProcessingInstruction, Text,
  XmlParseException
} from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';
import { XML_PARSER_CASES, XmlParserCase } from './XmlParserCases';

// Same format as dump() in tools/xml-oracle/XmlOracle.java.
function q(s: string): string {
  return JSON.stringify(s);
}

function dump(c: Content): string {
  if (c instanceof Element) {
    const ns = c.getAdditionalNamespaces().map((n: Namespace) => `${q(n.getPrefix())}=${q(n.getURI())}`);
    const attrs = c.getAttributes().map((a: Attribute) =>
      `${q(a.getNamespacePrefix())}:${q(a.getName())}{${q(a.getNamespaceURI())}}=${q(a.getValue())}`);
    const kids = c.getContent().map((k: Content) => dump(k));
    return `E${q(c.getNamespacePrefix())}:${q(c.getName())}{${q(c.getNamespaceURI())}}ns[${ns.join(',')}]a[${attrs.join(',')}]c[${kids.join(',')}]`;
  }
  if (c instanceof CDATA) {
    return `C${q(c.getText())}`;
  }
  if (c instanceof Text) {
    return `T${q(c.getText())}`;
  }
  if (c instanceof Comment) {
    return `M${q(c.getText())}`;
  }
  if (c instanceof ProcessingInstruction) {
    return `P${q(c.getTarget())}${q(c.getData())}`;
  }
  if (c instanceof DocType) {
    return `D${q(c.getElementName())}${q(String(c.getPublicID()))}${q(String(c.getSystemID()))}`;
  }
  if (c instanceof EntityRef) {
    return `R${q(c.getName())}`;
  }
  return '?';
}

function run(xml: string, allowDoctypes: boolean): string {
  try {
    const doc: Document = parseXml(xml, allowDoctypes);
    return `doc[${doc.getContent().map((c: Content) => dump(c)).join(',')}]`;
  } catch (e) {
    if (e instanceof XmlParseException) {
      return `ERR L${e.lineNumber} ${e.message}`;
    }
    return `EXC ${(e as Error).name}: ${(e as Error).message}`;
  }
}

export default function xmlParserTest() {
  describe('XmlParser', () => {
    it('matchesJdomOnEveryOracleCase', 0, () => {
      const failures: string[] = [];
      XML_PARSER_CASES.forEach((c: XmlParserCase) => {
        const actual = run(c.xml, c.allowDoctypes);
        if (actual !== c.expected) {
          failures.push(`${c.name}\n  expected: ${c.expected}\n  actual:   ${actual}`);
        }
      });
      expect(failures.join('\n')).assertEqual('');
      expect(XML_PARSER_CASES.length > 100).assertTrue();
    });

    // Port of rome/src/test/java/com/rometools/rome/unittest/TestXmlBomb.java at the parser level:
    // the DOCTYPE is rejected before any entity is declared.
    it('xmlBombIsRejected', 0, () => {
      const lol = (n: number): string => `<!ENTITY lol${n} "${`&lol${n - 1};`.repeat(10)}">\n`;
      let subset = ' <!ENTITY lol0 "lol">\n';
      for (let n = 1; n <= 9; n++) {
        subset += lol(n);
      }
      const content = `<?xml version="1.0"?>\n<!DOCTYPE lolz [\n${subset}]>\n<feed>\n    <title>&lol9;</title>\n</feed>`;
      let thrown: XmlParseException | null = null;
      try {
        parseXml(content);
      } catch (e) {
        thrown = e as XmlParseException;
      }
      expect(thrown !== null && thrown.lineNumber === 2).assertTrue();
      let limited = '';
      try {
        parseXml(content.replace('<title>&lol9;</title>', '<title t="&lol9;"/>'), true);
      } catch (e) {
        limited = (e as XmlParseException).message;
      }
      expect(limited.startsWith('JAXP00010001')).assertTrue();
    });

    it('errorPositionIsLineAndColumn', 0, () => {
      let error: XmlParseException | null = null;
      try {
        parseXml('<a>\n  <b></c>\n</a>');
      } catch (e) {
        error = e as XmlParseException;
      }
      expect(error!.lineNumber).assertEqual(2);
      expect(error!.columnNumber).assertEqual(8);
    });

    it('treeWorksWithDomApi', 0, () => {
      const doc = parseXml('<rss xmlns:dc="http://purl.org/dc/elements/1.1/"><channel><title> T </title>' +
        '<dc:creator>me</dc:creator><description><![CDATA[<p>x</p>]]> tail</description></channel></rss>');
      const channel = doc.getRootElement().getChild('channel')!;
      expect(channel.getChildTextTrim('title')).assertEqual('T');
      expect(channel.getChildText('creator', Namespace.getNamespace('http://purl.org/dc/elements/1.1/'))).assertEqual('me');
      expect(channel.getChildText('creator')).assertNull();
      expect(channel.getChildText('description')).assertEqual('<p>x</p> tail');
      expect(doc.getRootElement().getNamespace('dc')!.getURI()).assertEqual('http://purl.org/dc/elements/1.1/');
    });

    it('largeInputIsLinear', 0, () => {
      const item = '<item><title>A &amp; B</title><description><![CDATA[<p>html</p>]]></description></item>';
      const time = (items: number): number => {
        const xml = `<rss><channel>${item.repeat(items)}</channel></rss>`;
        const start = Date.now();
        const doc = parseXml(xml);
        expect(doc.getRootElement().getChild('channel')!.getChildren('item').length).assertEqual(items);
        return Date.now() - start;
      };
      // Local tests run coverage-instrumented in an interpreter, so only the growth rate is meaningful here:
      // 4x the input must take well under the 16x a quadratic parser would.
      const small = time(2000);
      const large = time(8000);
      expect(large < small * 8 + 200).assertTrue();
    });

    it('rssItemsAreLinear', 0, () => {
      const names = ['title', 'link', 'description', 'guid', 'pubDate'];
      const time = (items: number): number => {
        let xml = '<rss version="2.0"><channel><title>T</title>';
        for (let k = 0; k < items; k++) {
          xml += `<item>${names.map((name: string) => `<${name}>${name} ${k}</${name}>`).join('')}</item>`;
        }
        xml += '</channel></rss>';
        const start = Date.now();
        let found = 0;
        for (const item of parseXml(xml).getRootElement().getChild('channel')!.getChildren('item')) {
          found += names.filter((name: string) => item.getChild(name) !== null).length;
        }
        expect(found).assertEqual(items * names.length);
        return Date.now() - start;
      };
      const small = time(2000);
      const large = time(8000);
      expect(large < small * 8 + 200).assertTrue();
    });

    it('nestedPrefixScopesAreLinear', 0, () => {
      const time = (depth: number): number => {
        const xml = `<r>${'<e xmlns:p="urn:p">'.repeat(depth)}${'</e>'.repeat(depth)}</r>`;
        const start = Date.now();
        parseXml(xml);
        return Date.now() - start;
      };
      const small = time(5000);
      const large = time(20000);
      expect(large < small * 8 + 200).assertTrue();
    });
  });
}
