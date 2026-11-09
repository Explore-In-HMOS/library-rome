// Ported from ROME rome/src/test/java/com/rometools/rome/io/impl/Atom10ParserTest.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Entry } from '../main/ets/feed/atom/Entry';
import { Link } from '../main/ets/feed/atom/Link';
import { Atom10Parser } from '../main/ets/io/impl/Atom10Parser';
import { XmlParseException } from '../main/ets/xml/Dom';

// The expect lines are pasted from tools/parse-entry-oracle/ParseEntryOracle.java, which runs ROME 6b4a7e8; the constants
// match its own.
const NS = 'xmlns="http://www.w3.org/2005/Atom"';
const XXE = '<?xml  version="1.0" encoding="ISO-8859-1"?><!DOCTYPE foo [\n   <!ELEMENT foo ANY >\n   ' +
  `<!ENTITY xxe SYSTEM  "file:///etc/passwd" >]><entry ${NS}>  <title>Hello &xxe;</title></entry>`;
const RELATIVE = `<entry ${NS} xml:base="sub/"><title>T</title><id>i</id>` +
  '<link href="a.html"/><link rel="enclosure" href="/b.mp3" length="3"/><content src="c.txt"/></entry>';
const ABSOLUTE_BASE = `<entry ${NS} xml:base="http://y/"><link href="a.html"/></entry>`;
const NO_BASE = `<entry ${NS}><link href="a.html"/></entry>`;
const NOT_ENTRY = `<foo ${NS}/>`;
const NO_NS = '<entry><title>T</title></entry>';
const TWO = `<feed ${NS}><entry><title>inner</title></entry></feed>`;
const MALFORMED = `<entry ${NS}>\n<title>T</entry>`;
const BAD_NS_URI = `<entry ${NS} xmlns:p="2005"/>`;
const BASE = 'http://x/base/';
const RELATIVE_BASE = 'rel/';
const FILE_BASE = 'http://x/base/f.xml';

function links(list: Link[]): string {
  return `[${list.map((link: Link) => `${link.href}=${link.hrefResolved}`).join(',')}]`;
}

function run(xml: string, base: string | null): string {
  try {
    const e: Entry = Atom10Parser.parseEntry(xml, base);
    const src = e.contents.length === 0 ? null : e.contents[0].src;
    return `ok ${e.title} ${e.id} ${e.xmlBase} ${links(e.alternateLinks)} ${links(e.otherLinks)} ${src}`;
  } catch (e) {
    const error = e as Error;
    if (error.name === 'XmlParseException') {
      return `XmlParseException: ${error.message} @${(e as XmlParseException).lineNumber}`;
    }
    // A plain Error is Java's IndexOutOfBoundsException from getEntries().get(0).
    return `${error.name === 'Error' ? 'IndexOutOfBoundsException' : error.name}: ${error.message}`;
  }
}

export default function atomParseEntryTest() {
  describe('Atom10ParserTest', () => {
    it('parseEntryLikeRome', 0, () => {
      Atom10Parser.setResolveURIs(false);
      expect(run(XXE, null)).assertEqual('ok Hello  null null [] [] null');
      expect(run(RELATIVE, null)).assertEqual('ok T i sub/ [a.html=a.html] [/b.mp3=/b.mp3] c.txt');
      expect(run(RELATIVE, BASE)).assertEqual('ok T i sub/ [a.html=a.html] [/b.mp3=/b.mp3] c.txt');
      expect(run(RELATIVE, RELATIVE_BASE)).assertEqual('ok T i sub/ [a.html=a.html] [/b.mp3=/b.mp3] c.txt');
      expect(run(ABSOLUTE_BASE, BASE)).assertEqual('ok null null http://y/ [a.html=a.html] [] null');
      expect(run(NO_BASE, FILE_BASE)).assertEqual('ok null null null [a.html=a.html] [] null');
      expect(run(NO_BASE, null)).assertEqual('ok null null null [a.html=a.html] [] null');
      expect(run(NOT_ENTRY, null)).assertEqual('IndexOutOfBoundsException: Index 0 out of bounds for length 0');
      expect(run(NO_NS, null)).assertEqual('IndexOutOfBoundsException: Index 0 out of bounds for length 0');
      expect(run(TWO, null)).assertEqual('IndexOutOfBoundsException: Index 0 out of bounds for length 0');
      expect(run(MALFORMED, null)).assertEqual('XmlParseException: The element type "title" must be terminated by the matching end-tag "</title>". @2');
      expect(run(BAD_NS_URI, null)).assertEqual('IllegalNameException: The name "2005" is not legal for JDOM/XML Namespace URIs: Namespace URIs cannot begin with a number.');
    });

    it('parseEntryResolvesAgainstBaseUri', 0, () => {
      Atom10Parser.setResolveURIs(true);
      try {
        expect(run(XXE, null)).assertEqual('ok Hello  null null [] [] null');
        expect(run(RELATIVE, null)).assertEqual('ok T i sub/ [a.html=null/sub/a.html] [/b.mp3=null/sub/b.mp3] c.txt');
        expect(run(RELATIVE, BASE)).assertEqual('ok T i sub/ [a.html=http://x/base/sub/a.html] [/b.mp3=http://x/base/sub/b.mp3] c.txt');
        expect(run(RELATIVE, RELATIVE_BASE)).assertEqual('ok T i sub/ [a.html=null/rel/sub/a.html] [/b.mp3=null/rel/sub/b.mp3] c.txt');
        expect(run(ABSOLUTE_BASE, BASE)).assertEqual('ok null null http://y/ [a.html=http://y/a.html] [] null');
        expect(run(NO_BASE, FILE_BASE)).assertEqual('ok null null null [a.html=http://x/base/a.html] [] null');
        expect(run(NO_BASE, null)).assertEqual('ok null null null [a.html=null/a.html] [] null');
        expect(run(NOT_ENTRY, null)).assertEqual('IndexOutOfBoundsException: Index 0 out of bounds for length 0');
        expect(run(NO_NS, null)).assertEqual('IndexOutOfBoundsException: Index 0 out of bounds for length 0');
        expect(run(TWO, null)).assertEqual('IndexOutOfBoundsException: Index 0 out of bounds for length 0');
        expect(run(MALFORMED, null)).assertEqual('XmlParseException: The element type "title" must be terminated by the matching end-tag "</title>". @2');
        expect(run(BAD_NS_URI, null)).assertEqual('IllegalNameException: The name "2005" is not legal for JDOM/XML Namespace URIs: Namespace URIs cannot begin with a number.');
      } finally {
        Atom10Parser.setResolveURIs(false);
      }
    });
  });
}
