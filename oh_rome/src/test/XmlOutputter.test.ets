import { describe, it, expect } from '@ohos/hypium';
import { Attribute, CDATA, Comment, Content, DocType, Document, Element, Namespace, ProcessingInstruction,
  Text } from '../main/ets/xml/Dom';
import { Format, TextMode } from '../main/ets/xml/Format';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { XML_OUTPUTTER_EXPECTED } from './XmlOutputterExpected';

const D: Namespace = Namespace.getNamespace('urn:d');
const P: Namespace = Namespace.getNamespace('p', 'urn:p');
const P2: Namespace = Namespace.getNamespace('p', 'urn:p2');
const Q: Namespace = Namespace.getNamespace('q', 'urn:q');
const XHTML: Namespace = Namespace.getNamespace('http://www.w3.org/1999/xhtml');
const ATOM: Namespace = Namespace.getNamespace('http://www.w3.org/2005/Atom');
const SPECIAL = '"\'<>& \r\t\n';
const CHARSET_SAMPLE = '\u00e9\u20ac\u0416\u4e2d\u00a5\\~\u00a0\u3042\uac00\ud83d\ude00';
const NON_ASCII = 'café € 中 😀 \u0081';

type Child = string | Content;
type Tree = (o: XMLOutputter) => string;
type FormatFactory = () => Format;

function el(name: string, ...children: Child[]): Element {
  const e = new Element(name);
  for (const c of children) {
    e.addContent(typeof c === 'string' ? new Text(c) : c);
  }
  return e;
}

function trees(): Map<string, Tree> {
  const t = new Map<string, Tree>();
  t.set('escapes', (o: XMLOutputter): string => {
    const e = el('a', SPECIAL + ']]>');
    e.setAttribute('attr', SPECIAL + ']]>');
    return o.outputString(e);
  });
  t.set('cdata', (o: XMLOutputter): string => o.outputString(el('a', new CDATA(' x <&> y '), ']]>', new CDATA(''))));
  t.set('empty', (o: XMLOutputter): string => {
    const c = el('c');
    c.setAttribute('attr', '1');
    return o.outputString(el('root', el('a'), el('b', ''), c, el('d', '  ')));
  });
  t.set('textOnly', (o: XMLOutputter): string => o.outputString(el('a', '  hello \n  world  ')));
  t.set('mixed', (o: XMLOutputter): string => o.outputString(el('p', '  Some ', el('b', 'bold'), ' and ',
    el('i', ' italic '), '\n text  ')));
  t.set('adjacentText', (o: XMLOutputter): string => o.outputString(el('a', 'one ', new CDATA(' two '), '  three',
    el('b'), '  ', el('c'), 'y ', '', new CDATA('  '))));
  t.set('whitespaceOnly', (o: XMLOutputter): string => o.outputString(el('root', '\n  ', el('x'), '\n  ',
    el('y', '  '), '\n', el('z', '\n   \n'))));
  t.set('nested', (o: XMLOutputter): string => o.outputString(el('root', el('a', el('b', el('c', 'deep'),
    new Comment(' c '), new ProcessingInstruction('pi', 'data')), el('e')))));
  t.set('namespaces', (o: XMLOutputter): string => {
    const root = new Element('root', D);
    root.addNamespaceDeclaration(Namespace.getNamespace('z', 'urn:z'));
    root.addNamespaceDeclaration(P);
    root.addNamespaceDeclaration(Namespace.getNamespace('m', 'urn:m'));
    const pChild = new Element('child', P);
    pChild.setAttribute(new Attribute('own', '1', P));
    pChild.setAttribute(new Attribute('q', '2', Q));
    pChild.setAttribute(new Attribute('lang', 'en', Namespace.XML_NAMESPACE));
    pChild.addNamespaceDeclaration(P);
    const redeclared = new Element('again', P2);
    redeclared.addContent(new Element('inner', P));
    const none = new Element('none');
    none.addContent(new Element('back', D));
    const q = new Element('q', Q);
    q.setAttribute('x', '1');
    q.addNamespaceDeclaration(Namespace.getNamespace('b', 'urn:b'));
    q.addNamespaceDeclaration(Namespace.getNamespace('a', 'urn:a'));
    root.addContent([pChild, redeclared, none, new Element('same', D), q]);
    return o.outputString(root);
  });
  t.set('document', (o: XMLOutputter): string => {
    const root = el('rss', el('channel', el('title', 'T')));
    root.setAttribute('version', '2.0');
    const doc = new Document(root);
    const dt = new DocType('rss', '-//Netscape Communications//DTD RSS 0.91//EN',
      'http://my.netscape.com/publish/formats/rss-0.91.dtd');
    dt.setInternalSubset('<!ENTITY e "x">');
    doc.setDocType(dt);
    doc.addContentAt(0, new ProcessingInstruction('xml-stylesheet', 'href="a.xsl" type="text/xsl"'));
    doc.addContentAt(1, new Comment(' top '));
    doc.addContent(new Comment(' end '));
    return o.outputString(doc);
  });
  t.set('documentSystemId', (o: XMLOutputter): string => {
    const doc = new Document(new Element('opml'));
    doc.setDocType(new DocType('opml', null, 'opml.dtd'));
    return o.outputString(doc);
  });
  t.set('documentNs', (o: XMLOutputter): string => {
    const feed = new Element('feed', ATOM);
    feed.addContent(new Element('title', ATOM).setText('a & b'));
    return o.outputString(new Document(feed));
  });
  t.set('documentEmpty', (o: XMLOutputter): string => o.outputString(new Document()));
  t.set('documentText', (o: XMLOutputter): string => {
    const doc = new Document();
    doc.addContent(new Text('\n  '));
    doc.addContent(new Comment(' c '));
    doc.addContent(new Text(' '));
    doc.addContent(el('root', ' x '));
    doc.addContent(new Text('\r\n\t'));
    doc.addContent(new Text(''));
    return o.outputString(doc);
  });
  t.set('docType', (o: XMLOutputter): string => {
    const dt = new DocType('html', '-//W3C//DTD XHTML 1.0 Strict//EN', null);
    dt.setInternalSubset('<!ENTITY nbsp "&#160;">\n');
    return o.outputString(dt);
  });
  t.set('nonAscii', (o: XMLOutputter): string => {
    const e = el('a', NON_ASCII, new CDATA(NON_ASCII));
    e.setAttribute('v', NON_ASCII);
    return o.outputString(e);
  });
  t.set('cp1252', (o: XMLOutputter): string =>
    o.outputString(el('a', '€“œŸ\u0080\u0081\u008d Ā')));
  t.set('contentList', (o: XMLOutputter): string => {
    const content = new Element('content', ATOM);
    content.setAttribute('type', 'xhtml');
    const div = new Element('div', XHTML);
    const p = new Element('p', XHTML);
    p.addContent('Hi & <bye>');
    div.addContent([new Text('\n  '), p, new Text('\n')]);
    content.addContent([new Text('\n    '), div, new Text('\n  ')]);
    return o.outputString(content.getContent());
  });
  t.set('contentListText', (o: XMLOutputter): string => {
    const desc = el('description', '  Hello ', el('b', 'world'), new Comment('c'), ' &amp; bye\n');
    return o.outputString(desc.getContent());
  });
  t.set('text', (o: XMLOutputter): string => o.outputString(new Text('  a\nb <&>\r\t"\'  ')));
  t.set('cdataNode', (o: XMLOutputter): string => o.outputString(new CDATA('  c <&> d  ')));
  t.set('comment', (o: XMLOutputter): string => o.outputString(new Comment(' note <&> ')));
  t.set('pi', (o: XMLOutputter): string => o.outputString(new ProcessingInstruction('target', '')) + '|'
    + o.outputString(new ProcessingInstruction('xml-stylesheet', 'href="a.xsl"')) + '|'
    + o.outputString(new ProcessingInstruction('javax.xml.transform.disable-output-escaping', '')));
  t.set('xmlSpace', (o: XMLOutputter): string => {
    const pre = el('pre', '  x  ', el('b', ' y '), el('c', el('d')));
    pre.setAttribute('space', 'preserve', Namespace.XML_NAMESPACE);
    const def = el('n', '  z  ', el('m', '  w '));
    def.setAttribute('space', 'default', Namespace.XML_NAMESPACE);
    pre.addContent(def);
    return o.outputString(el('root', pre, el('after', ' k ')));
  });
  t.set('trax', (o: XMLOutputter): string => {
    const x = el('x', '<i>');
    x.setAttribute('a', '<&>');
    return o.outputString(el('root', '<a>',
      new ProcessingInstruction('javax.xml.transform.disable-output-escaping', ''), '<b>&', x,
      new ProcessingInstruction('javax.xml.transform.enable-output-escaping', ''), '<c>'));
  });
  t.set('charsets', (o: XMLOutputter): string => {
    const e = el('a', CHARSET_SAMPLE);
    e.setAttribute('v', CHARSET_SAMPLE);
    return o.outputString(e);
  });
  return t;
}

function formats(): Map<string, FormatFactory> {
  const f = new Map<string, FormatFactory>();
  f.set('raw', (): Format => Format.getRawFormat());
  f.set('compact', (): Format => Format.getCompactFormat());
  f.set('pretty', (): Format => Format.getPrettyFormat());
  f.set('trimFullWhite', (): Format => Format.getRawFormat().setTextMode(TextMode.TRIM_FULL_WHITE));
  f.set('trimNoIndent', (): Format => Format.getRawFormat().setTextMode(TextMode.TRIM));
  f.set('prettyTabs', (): Format => Format.getPrettyFormat().setIndent('\t').setLineSeparator('\n')
    .setExpandEmptyElements(true));
  f.set('prettyNormalize', (): Format => Format.getPrettyFormat().setTextMode(TextMode.NORMALIZE)
    .setLineSeparator('\n'));
  f.set('prettyPreserve', (): Format => Format.getPrettyFormat().setTextMode(TextMode.PRESERVE));
  f.set('rawNoSeparator', (): Format => Format.getRawFormat().setLineSeparator('').setOmitEncoding(true));
  f.set('compactAscii', (): Format => Format.getCompactFormat().setEncoding('US-ASCII'));
  f.set('prettyLatin1', (): Format => Format.getPrettyFormat().setEncoding('ISO-8859-1').setOmitDeclaration(true));
  f.set('rawCp1252', (): Format => Format.getRawFormat().setEncoding('windows-1252'));
  f.set('rawUtf16le', (): Format => Format.getRawFormat().setEncoding('UTF-16LE'));
  f.set('rawUnknown', (): Format => Format.getRawFormat().setEncoding('x-no-such-encoding'));
  for (const encoding of ['windows-1251', 'KOI8-R', 'ISO-8859-5', 'GBK', 'Shift_JIS', 'Big5', 'IBM866', 'Cp866',
    'ISO8859_5', 'EUC-KR']) {
    f.set(`raw:${encoding}`, (): Format => Format.getRawFormat().setEncoding(encoding));
  }
  return f;
}

function expectAll(treeName: string): void {
  const tree = trees().get(treeName)!;
  formats().forEach((factory: FormatFactory, formatName: string) => {
    const key = `${treeName}/${formatName}`;
    const expected = XML_OUTPUTTER_EXPECTED.get(key);
    expect(expected !== undefined).assertTrue();
    const actual = tree(new XMLOutputter(factory()));
    if (actual !== expected) {
      expect(`${key}: ${JSON.stringify(actual)}`).assertEqual(`${key}: ${JSON.stringify(expected)}`);
    }
  });
}

export default function xmlOutputterTest() {
  describe('XmlOutputter', () => {
    it('everyTreeHasExpectedOutputForEveryFormat', 0, () => {
      expect(XML_OUTPUTTER_EXPECTED.size).assertEqual(trees().size * formats().size + 1);
    });

    trees().forEach((tree: Tree, name: string) => {
      it(name, 0, () => {
        expectAll(name);
      });
    });

    it('formatIsCloned', 0, () => {
      const format = Format.getRawFormat();
      const outputter = new XMLOutputter(format);
      format.setOmitDeclaration(true);
      expect(outputter.outputString(new Document(new Element('a'))))
        .assertEqual(XML_OUTPUTTER_EXPECTED.get('formatIsCloned'));
    });

    it('defaultsMatchJdom', 0, () => {
      const raw = Format.getRawFormat();
      expect(raw.getEncoding()).assertEqual('UTF-8');
      expect(raw.getLineSeparator()).assertEqual('\r\n');
      expect(raw.getIndent()).assertNull();
      expect(raw.getTextMode()).assertEqual(TextMode.PRESERVE);
      expect(Format.getPrettyFormat().getIndent()).assertEqual('  ');
      expect(Format.getPrettyFormat().getTextMode()).assertEqual(TextMode.TRIM);
      expect(Format.getCompactFormat().getTextMode()).assertEqual(TextMode.NORMALIZE);
      expect(new XMLOutputter().getFormat().getLineSeparator()).assertEqual('\r\n');
    });

    it('brokenSurrogatesThrowJdomMessages', 0, () => {
      const strategy = Format.getRawFormat().getEscapeStrategy();
      let message = '';
      try {
        Format.escapeText(strategy, null, 'a\ud83d');
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Surrogate pair 0xd83dtruncated');
      try {
        Format.escapeAttribute(strategy, '\ud83dx');
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Could not decode surrogate pair 0xd83d / 0x78');
    });
  });
}
