// Ported from ROME rome/src/test/java/com/rometools/rome/io/impl/RSS20ParserTest.java and unittest/DublinCoreTest.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Document, Element } from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';
import { DCModule } from '../main/ets/feed/module/DCModule';
import { Channel } from '../main/ets/feed/rss/Channel';
import { WireFeedParser } from '../main/ets/io/WireFeedParser';
import { RSS092Parser } from '../main/ets/io/impl/RSS092Parser';
import { RSS20Parser } from '../main/ets/io/impl/RSS20Parser';
import { assertGolden, fixture, fixtureIds } from './golden/Golden';

// The core RSS fixtures, also used by RssGenerators.test.ets and RssConverters.test.ets.
export const FIXTURES: string[] = ['rome/rss_0.9.xml', 'rome/rss_0.91N.xml', 'rome/rss_0.91U.xml', 'rome/rss_0.92.xml',
  'rome/rss_0.92_alt.xml', 'rome/rss_0.93.xml', 'rome/rss_0.94.xml', 'rome/rss_1.0-ns-on-channel.xml', 'rome/rss_1.0.xml',
  'rome/rss_1.0_DC_multi.xml', 'rome/rss_1.0_DC_Sy.xml', 'rome/rss_2.0.xml', 'rome/CDATATestFeed.xml',
  'rome/dublin-core-date.xml', 'rome/issue131-rss.xml', 'rome/issue137-rss.xml', 'rome/jira_issue1.xml'];

function rssDocument(version: string | null): Document {
  const root = new Element('rss');
  if (version !== null) {
    root.setAttribute('version', version);
  }
  return new Document(root);
}

function thrown(action: () => void): string {
  try {
    action();
  } catch (e) {
    const error = e as Error;
    return `${error.name}: ${error.message}`;
  }
  return 'nothing thrown';
}

export default function rssParsersTest() {
  describe('RSS20ParserTest', () => {
    const parser: WireFeedParser = new RSS20Parser();

    it('testIsMyType', 0, () => {
      expect(parser.isMyType(rssDocument('2.0'))).assertTrue();
    });

    it('testIsMyTypeNotMyType', 0, () => {
      expect(parser.isMyType(rssDocument('1.0'))).assertFalse();
    });

    it('testIsMyTypeVersionWithSpaces', 0, () => {
      expect(parser.isMyType(rssDocument(' 2.0 '))).assertTrue();
    });

    it('testIsMyTypeVersionWithTrailingText', 0, () => {
      expect(parser.isMyType(rssDocument('2.0test'))).assertTrue();
    });

    it('testIsMyTypeVersionAbsent', 0, () => {
      expect(parser.isMyType(rssDocument(null))).assertTrue();
    });
  });

  describe('DublinCoreTest', () => {
    // ROME asserts this on the SyndEntry; the RSS-to-Synd converter is A6, so this checks the wire item it reads.
    it('testPubDateDoesNotOverrideDublinCoreDate', 0, () => {
      const document = parseXml(fixture('rome/dublin-core-date.xml').xml);
      const item = (new RSS20Parser().parse(document) as Channel).items[0];
      const dublinCore = item.getModule(DCModule.URI) as DCModule;
      expect(dublinCore.date!.getTime()).assertEqual(1000);
      expect(item.pubDate!.getTime()).assertEqual(0);
    });
  });

  describe('RssParsersNumbers', () => {
    // RSS091UserlandParser and RSS092Parser call Integer.parseInt on the trimmed text, which throws.
    it('badSkipHourAndCloudPortThrowNumberFormatException', 0, () => {
      const hour = '<rss version="0.92"><channel><skipHours><hour> 2x </hour></skipHours></channel></rss>';
      expect(thrown(() => new RSS092Parser().parse(parseXml(hour))))
        .assertEqual('NumberFormatException: For input string: "2x"');
      const port = '<rss version="0.92"><channel><cloud port=" 80a "/></channel></rss>';
      expect(thrown(() => new RSS092Parser().parse(parseXml(port))))
        .assertEqual('NumberFormatException: For input string: "80a"');
    });
  });

  describe('RssParsersGolden', () => {
    FIXTURES.concat(fixtureIds('repo/rss-wire/')).forEach((id: string) => {
      it(`wire ${id}`, 0, () => {
        assertGolden(id, 'core', 'wire');
      });
    });

    it('wire.default rome/rss_0.91N.xml', 0, () => {
      assertGolden('rome/rss_0.91N.xml', 'core', 'wire.default');
    });
  });
}
