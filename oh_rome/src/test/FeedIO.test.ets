import { describe, it, expect } from '@ohos/hypium';
import { WireFeed } from '../main/ets/feed/WireFeed';
import { Channel } from '../main/ets/feed/rss/Channel';
import { Item } from '../main/ets/feed/rss/Item';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { FeedException, ParsingFeedException } from '../main/ets/io/FeedException';
import { SyndFeedInput } from '../main/ets/io/SyndFeedInput';
import { SyndFeedOutput } from '../main/ets/io/SyndFeedOutput';
import { WireFeedInput } from '../main/ets/io/WireFeedInput';
import { WireFeedOutput } from '../main/ets/io/WireFeedOutput';
import { IllegalArgumentException } from '../main/ets/utils/Exceptions';
import { DocType, ProcessingInstruction } from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';

// The expect lines are pasted from tools/io-oracle/IoOracle.java, which runs ROME 6b4a7e8; the constants match its own.

const RSS20 = '<rss version="2.0"><channel><title>T</title><link>http://x/</link>' +
  '<description>D</description></channel></rss>';
const UNKNOWN_ROOT = '<foo/>';
const MALFORMED = '<rss version="2.0">\n<channel>\n  <title>T</title>\n</rss>';
const BAD_NS_URI = '<rss xmlns:p="2005" version="2.0"><channel/></rss>';
const NO_CHANNEL = '<rss version="2.0"/>';
const BAD_HOUR = '<rss version="0.91"><channel><skipHours><hour>x</hour></skipHours></channel></rss>';
const SELF_NO_HREF = '<feed xmlns="http://www.w3.org/2005/Atom"><link rel="self"/></feed>';
const NBSP = '<rss version="2.0"><channel><title>a&nbsp;b</title></channel></rss>';
const LEADING_COMMENT = '<!-- c --> <?xml version="1.0"?><rss version="2.0"><channel/></rss>';
const DOCTYPE = '<?xml version="1.0"?><!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN" ' +
  '"http://my.netscape.com/publish/formats/rss-0.91.dtd"><rss version="0.91"><channel><title>T</title></channel></rss>';
const DOCTYPE_IN_ELEMENT = '<rss><!DOCTYPE x></rss>';
const LATIN1 = '<?xml version="1.0" encoding="ISO-8859-1"?><rss version="2.0"><channel><title>caf\u00E9</title></channel></rss>';

function outcome(run: () => string | null): string {
  try {
    return `ok ${run()}`;
  } catch (e) {
    let s = `${(e as Error).name}: ${(e as Error).message}`;
    if (e instanceof ParsingFeedException) {
      const p = e as ParsingFeedException;
      s += ` @${p.getLineNumber()}:${p.getColumnNumber()}`;
    }
    return s;
  }
}

function causeOf(run: () => void): string {
  try {
    run();
    return 'no error';
  } catch (e) {
    const cause = e instanceof FeedException ? (e as FeedException).rootCause : null;
    return cause === null ? 'no cause' : cause.message;
  }
}

function input(healer: boolean, doctypes: boolean): WireFeedInput {
  const wireInput = new WireFeedInput();
  wireInput.xmlHealerOn = healer;
  wireInput.allowDoctypes = doctypes;
  return wireInput;
}

function typeAndTitle(f: WireFeed): string {
  return `${f.feedType} ${(f as Channel).title}`;
}

function read(xml: string, healer: boolean = true, doctypes: boolean = false): string {
  return outcome(() => typeAndTitle(input(healer, doctypes).build(xml)));
}

function readWire(xml: string): void {
  new WireFeedInput().build(xml);
}

function latin1(): Uint8Array {
  const bytes = new Uint8Array(LATIN1.length);
  for (let i = 0; i < LATIN1.length; i++) {
    bytes[i] = LATIN1.charCodeAt(i);
  }
  return bytes;
}

function errorOf(xml: string): Error {
  try {
    readWire(xml);
  } catch (e) {
    return e as Error;
  }
  throw new Error('no error');
}

// XmlParser reports this error at the start of the DOCTYPE token, Xerces after it (A1 PR, deviation 13).
function withoutColumn(outcome: string): string {
  return outcome.replace(new RegExp(':-?\\d+$'), '');
}

function sample(type: string | null, encoding: string | null, styleSheet: string | null): Channel {
  const c = type === null ? new Channel() : new Channel(type);
  c.title = 'caf\u00E9 \u20AC';
  c.link = 'http://x/';
  c.description = 'D';
  c.language = 'en';
  c.encoding = encoding;
  c.styleSheet = styleSheet;
  const item = new Item();
  item.title = 'I';
  item.link = 'http://x/i';
  c.items = [item];
  return c;
}

function write(c: Channel, pretty: boolean): string {
  return outcome(() => new WireFeedOutput().outputString(c, pretty));
}

function sorted(types: string[]): string {
  return types.slice().sort().join(',');
}

export default function feedIOTest() {
  describe('FeedIO', () => {
    it('defaults', 0, () => {
      expect(new WireFeedInput().xmlHealerOn).assertTrue();
      expect(new WireFeedInput().allowDoctypes).assertFalse();
      expect(new SyndFeedInput().xmlHealerOn).assertTrue();
      expect(new SyndFeedInput().allowDoctypes).assertFalse();
      expect(new SyndFeedInput().preserveWireFeed).assertFalse();
      expect(sorted(WireFeedInput.getSupportedFeedTypes())).assertEqual('atom_0.3,atom_1.0,opml_1.0,opml_2.0,rss_0.9,rss_0.91N,rss_0.91U,rss_0.92,rss_0.93,rss_0.94,rss_1.0,rss_2.0,rss_2.0wNS,rss_2.0yahoo');
      expect(sorted(WireFeedOutput.getSupportedFeedTypes())).assertEqual('atom_0.3,atom_1.0,opml_1.0,opml_2.0,rss_0.9,rss_0.91N,rss_0.91U,rss_0.92,rss_0.93,rss_0.94,rss_1.0,rss_2.0');
    });

    it('wireFeedInput', 0, () => {
      expect(read(RSS20)).assertEqual('ok rss_2.0 T');
      expect(read(UNKNOWN_ROOT)).assertEqual('IllegalArgumentException: Invalid document');
      expect(read(MALFORMED)).assertEqual('ParsingFeedException: Invalid XML: Error on line 4: The element type "channel" must be terminated by the matching end-tag "</channel>". @4:3');
      expect(read(BAD_NS_URI)).assertEqual('IllegalNameException: The name "2005" is not legal for JDOM/XML Namespace URIs: Namespace URIs cannot begin with a number.');
      expect(read(BAD_HOUR)).assertEqual('NumberFormatException: For input string: "x"');
      expect(read(NO_CHANNEL)).assertEqual('ParsingFeedException: Invalid XML @-1:-1');
      expect(read(SELF_NO_HREF)).assertEqual('ParsingFeedException: Invalid XML @-1:-1');
      expect(causeOf(() => readWire(SELF_NO_HREF))).assertEqual('ERROR while finding base URI of feed');
      // ROME rethrows IllegalArgumentException and its subclasses raw and wraps everything else (WireFeedInput.java:228-241).
      expect(errorOf(UNKNOWN_ROOT) instanceof IllegalArgumentException).assertTrue();
      expect(errorOf(BAD_NS_URI) instanceof IllegalArgumentException).assertTrue();
      expect(errorOf(BAD_HOUR) instanceof IllegalArgumentException).assertTrue();
      expect(errorOf(NO_CHANNEL) instanceof ParsingFeedException).assertTrue();
      expect((errorOf(SELF_NO_HREF) as ParsingFeedException).rootCause instanceof FeedException).assertTrue();
      expect(read(NBSP)).assertEqual('ok rss_2.0 a\u00A0b');
      expect(read(NBSP, false)).assertEqual('ParsingFeedException: Invalid XML: Error on line 1: The entity "nbsp" was referenced, but not declared. @1:43');
      expect(read(LEADING_COMMENT)).assertEqual('ok rss_2.0 null');
      expect(read(LEADING_COMMENT, false)).assertEqual('ParsingFeedException: Invalid XML: Error on line 1: The processing instruction target matching "[xX][mM][lL]" is not allowed. @1:17');
      expect(withoutColumn(read(DOCTYPE))).assertEqual('ParsingFeedException: Invalid XML: Error on line 1: DOCTYPE is disallowed when the feature "http://apache.org/xml/features/disallow-doctype-decl" set to true. @1');
      expect(read(DOCTYPE, true, true)).assertEqual('ok rss_0.91N T');
      expect(read(DOCTYPE_IN_ELEMENT)).assertEqual('ParsingFeedException: Invalid XML: Error in building: Scanner State 24 not Recognized  @-1:-1');
      expect(read(DOCTYPE_IN_ELEMENT, true, true)).assertEqual('ParsingFeedException: Invalid XML: Error in building: Scanner State 24 not Recognized  @-1:-1');
      expect(read('')).assertEqual('ParsingFeedException: Invalid XML: Error on line 1: Premature end of file. @1:1');
      expect(outcome(() => typeAndTitle(new WireFeedInput().build(latin1())))).assertEqual('ok rss_2.0 caf\u00E9');
      expect(outcome(() => typeAndTitle(new WireFeedInput().build(parseXml(UNKNOWN_ROOT))))).assertEqual('IllegalArgumentException: Invalid document');
      expect(outcome(() => typeAndTitle(new WireFeedInput().build(parseXml(RSS20))))).assertEqual('ok rss_2.0 T');
    });

    it('wireFeedOutput', 0, () => {
      expect(write(sample('rss_2.0', null, null), true)).assertEqual('ok <?xml version="1.0" encoding="UTF-8"?>\r\n<rss version="2.0">\r\n  <channel>\r\n    <title>caf\u00E9 \u20AC</title>\r\n    <link>http://x/</link>\r\n    <description>D</description>\r\n    <language>en</language>\r\n    <item>\r\n      <title>I</title>\r\n      <link>http://x/i</link>\r\n    </item>\r\n  </channel>\r\n</rss>\r\n');
      expect(write(sample('rss_2.0', null, null), false)).assertEqual('ok <?xml version="1.0" encoding="UTF-8"?>\r\n<rss version="2.0"><channel><title>caf\u00E9 \u20AC</title><link>http://x/</link><description>D</description><language>en</language><item><title>I</title><link>http://x/i</link></item></channel></rss>\r\n');
      expect(outcome(() => new WireFeedOutput().outputString(sample('rss_2.0', null, null)))).assertEqual('ok <?xml version="1.0" encoding="UTF-8"?>\r\n<rss version="2.0">\r\n  <channel>\r\n    <title>caf\u00E9 \u20AC</title>\r\n    <link>http://x/</link>\r\n    <description>D</description>\r\n    <language>en</language>\r\n    <item>\r\n      <title>I</title>\r\n      <link>http://x/i</link>\r\n    </item>\r\n  </channel>\r\n</rss>\r\n');
      expect(write(sample('rss_2.0', 'ISO-8859-1', null), false)).assertEqual('ok <?xml version="1.0" encoding="ISO-8859-1"?>\r\n<rss version="2.0"><channel><title>caf\u00E9 &#x20ac;</title><link>http://x/</link><description>D</description><language>en</language><item><title>I</title><link>http://x/i</link></item></channel></rss>\r\n');
      expect(write(sample('rss_2.0', 'US-ASCII', 'a.xsl'), false)).assertEqual('ok <?xml version="1.0" encoding="US-ASCII"?>\r\n<?xml-stylesheet type="text/xsl" href="a.xsl"?><rss version="2.0"><channel><title>caf&#xe9; &#x20ac;</title><link>http://x/</link><description>D</description><language>en</language><item><title>I</title><link>http://x/i</link></item></channel></rss>\r\n');
      expect(write(sample('rss_0.91N', null, 'a"b.xsl'), true)).assertEqual('ok <?xml version="1.0" encoding="UTF-8"?>\r\n<?xml-stylesheet type="text/xsl" href="a"b.xsl"?>\r\n<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN" "http://my.netscape.com/publish/formats/rss-0.91.dtd">\r\n<rss version="0.91">\r\n  <channel>\r\n    <title>caf\u00E9 \u20AC</title>\r\n    <link>http://x/</link>\r\n    <description>D</description>\r\n    <language>en</language>\r\n    <item>\r\n      <title>I</title>\r\n      <link>http://x/i</link>\r\n    </item>\r\n  </channel>\r\n</rss>\r\n');
      expect(write(sample('rss_2.0', null, 'a?>b'), false)).assertEqual('IllegalDataException: The data "type="text/xsl" href="a?>b"" is not legal for a JDOM Processing instructions cannot contain the string "?>".');
      expect(write(sample('foo', null, null), false)).assertEqual('IllegalArgumentException: Invalid feed type [foo]');
      expect(write(sample(null, null, null), false)).assertEqual('IllegalArgumentException: Invalid feed type [null]');
      const doc = new WireFeedOutput().outputJDom(sample('rss_0.91N', null, 'a.xsl'));
      const pi = doc.getContent()[0] as ProcessingInstruction;
      expect(pi.getTarget()).assertEqual('xml-stylesheet');
      expect(pi.getData()).assertEqual('type="text/xsl" href="a.xsl"');
      expect(doc.getContent()[1] instanceof DocType).assertTrue();
    });

    it('syndFeedInputOutput', 0, () => {
      const synd: SyndFeed = new SyndFeedInput().build(RSS20);
      expect(synd.originalWireFeed() === null).assertTrue();
      const preserving = new SyndFeedInput();
      preserving.preserveWireFeed = true;
      const preserved = preserving.build(RSS20);
      expect(preserved.originalWireFeed()!.feedType).assertEqual('rss_2.0');
      expect(preserved.isPreservingWireFeed()).assertTrue();
      expect(outcome(() => new SyndFeedInput().build(UNKNOWN_ROOT).feedType)).assertEqual('IllegalArgumentException: Invalid document');
      const noHealer = new SyndFeedInput();
      noHealer.xmlHealerOn = false;
      expect(outcome(() => noHealer.build(NBSP).feedType)).assertEqual('ParsingFeedException: Invalid XML: Error on line 1: The entity "nbsp" was referenced, but not declared. @1:43');
      const doctypes = new SyndFeedInput();
      doctypes.allowDoctypes = true;
      expect(outcome(() => doctypes.build(DOCTYPE).feedType)).assertEqual('ok rss_0.91N');
      expect(outcome(() => new SyndFeedOutput().outputString(synd, false))).assertEqual('ok <?xml version="1.0" encoding="UTF-8"?>\r\n<rss version="2.0"><channel><title>T</title><link>http://x/</link><description>D</description></channel></rss>\r\n');
      expect(new SyndFeedOutput().outputString(synd) === new WireFeedOutput().outputString(synd.createWireFeed())).assertTrue();
      expect(new SyndFeedOutput().outputJDom(synd).getRootElement().getName()).assertEqual('rss');
    });
  });
}
