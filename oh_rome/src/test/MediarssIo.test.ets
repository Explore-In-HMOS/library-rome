// Ported from ROME rome-modules/src/test/java/com/rometools/modules/mediarss/{MediaModuleTest,io/MediaModuleParserTest}.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Element } from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { WireFeedParser } from '../main/ets/io/WireFeedParser';
import { ModuleParser } from '../main/ets/io/ModuleParser';
import { RSS20Parser } from '../main/ets/io/impl/RSS20Parser';
import { plugins, usePluginRegistry } from '../main/ets/io/impl/PluginRegistry';
import { MediaEntryModule } from '../main/ets/modules/mediarss/MediaEntryModule';
import { MediaModule } from '../main/ets/modules/mediarss/MediaModule';
import { javaFloatingString, MediaModuleGenerator } from '../main/ets/modules/mediarss/io/MediaModuleGenerator';
import { MediaModuleParser } from '../main/ets/modules/mediarss/io/MediaModuleParser';
import { RSS20YahooParser } from '../main/ets/modules/mediarss/io/RSS20YahooParser';
import { assertGolden, fixture, profileRegistry, serialize } from './golden/Golden';

const PREFIX = 'modules/org/rometools/feed/module/mediarss/';

// RSS fixtures with media elements. AllFixtures.test.ets runs every other fixture, including the Atom feed
// modules/data/YouTube-MostPopular.rss.
const GOLDEN_FIXTURES: string[] = ['modules/test1.xml', 'modules/test2.xml', 'modules/test1media.xml',
  'modules/test2media.xml', `${PREFIX}filesize-with-unit.xml`, `${PREFIX}issue-07.xml`, `${PREFIX}issue-08.xml`,
  `${PREFIX}issue-12.xml`, `${PREFIX}issue-20.xml`, `${PREFIX}issue-331.xml`, 'repo/mediarss/content-floats.xml',
  'repo/mediarss/community-tags.xml'];
const KINDS: string[] = ['wire', 'synd', 'roundtrip'];

function syndFeed(id: string): SyndFeed {
  usePluginRegistry(profileRegistry('full'));
  try {
    return new SyndFeed(new RSS20Parser().parse(parseXml(fixture(id).xml)));
  } finally {
    usePluginRegistry(null);
  }
}

function firstModule(id: string): MediaEntryModule {
  return syndFeed(id).entries[0].getModule(MediaModule.URI) as MediaEntryModule;
}

function fileSizeError(value: string): string {
  try {
    MediaModuleParser.parseFileSize(value);
    return 'no error';
  } catch (e) {
    return `${(e as Error).name}: ${(e as Error).message}`;
  }
}

const YAHOO_FEED = '<rss xmlns="urn:yahoo:yn" xmlns:media="http://search.yahoo.com/mrss/" version="2.0"><channel>' +
  '<title>Yahoo</title><link>http://video.search.yahoo.com</link><description>d</description>' +
  '<item><title>clip</title><media:content url="http://x.com/a.flv" bitrate="128.5"/></item></channel></rss>';

export default function mediarssIoTest() {
  describe('MediaModuleParserTest', () => {
    it('testParsesFileSizeWithoutUnit', 0, () => {
      expect(MediaModuleParser.parseFileSize('1234567')).assertEqual(1234567);
    });
    it('testParsesFileSizeWithByteUnit', 0, () => {
      expect(MediaModuleParser.parseFileSize('1B')).assertEqual(1);
    });
    it('testParsesFileSizeWithKiloByteUnit', 0, () => {
      expect(MediaModuleParser.parseFileSize('1KB')).assertEqual(1000);
    });
    it('testParsesFileSizeWithMegaByteUnit', 0, () => {
      expect(MediaModuleParser.parseFileSize('1MB')).assertEqual(1000000);
    });
    it('testParsesFileSizeWithGigaByteUnit', 0, () => {
      expect(MediaModuleParser.parseFileSize('1GB')).assertEqual(1000000000);
    });
    it('testParsesFileSizeWithTeraByteUnit', 0, () => {
      expect(MediaModuleParser.parseFileSize('1TB')).assertEqual(1000000000000);
    });
    it('testParsesFileSizeHandlesSpaces', 0, () => {
      expect(MediaModuleParser.parseFileSize(' 1 KB ')).assertEqual(1000);
    });
    it('testParsesFileSizeHandlesDecimals', 0, () => {
      expect(MediaModuleParser.parseFileSize('1.23KB')).assertEqual(1230);
    });
    it('testThrowsExceptionOnInvalidFileSize', 0, () => {
      expect(fileSizeError('reallybig')).assertEqual('NumberFormatException: Invalid file size: reallybig');
    });
    // ROME on Temurin 17 gives fileSize 8198552921648689607 for 5,000 and for 20,000 ones followed by B.
    it('longPriceAndFileSizeAreLinear', 0, () => {
      const time = (n: number): number => {
        const digits = '1'.repeat(n);
        const item = parseXml(`<item xmlns:media="http://search.yahoo.com/mrss/"><media:price price="${digits}"/>` +
          `<media:content url="http://x.com/a" fileSize="${digits}B"/></item>`).getRootElement();
        const start = Date.now();
        const module = new MediaModuleParser().parse(item) as MediaEntryModule;
        expect(module.metadata!.prices[0].price).assertEqual(digits);
        expect(module.mediaContents[0].fileSize).assertEqual(Number('8198552921648689607'));
        return Date.now() - start;
      };
      const small = time(5000);
      const large = time(20000);
      expect(large < small * 8 + 200).assertTrue();
    });
  });

  describe('MediaModuleTest', () => {
    it('testParseFileSizeWithUnits', 0, () => {
      expect(firstModule(`${PREFIX}filesize-with-unit.xml`).mediaContents[0].fileSize).assertEqual(1000000000);
    });
    it('testParseThumbnailWithEmptyDimensions', 0, () => {
      expect(firstModule(`${PREFIX}issue-07.xml`).metadata!.thumbnail.length > 0).assertTrue();
    });
    it('testParseDecimalDuration', 0, () => {
      expect(firstModule(`${PREFIX}issue-08.xml`).mediaContents[0].duration).assertEqual(174);
    });
    it('testParseRatingWithoutScheme', 0, () => {
      expect(firstModule(`${PREFIX}issue-12.xml`).metadata!.ratings.length > 0).assertTrue();
    });
    it('testParseMediaContentContainingURLWithSpaces', 0, () => {
      const mediaContents = firstModule(`${PREFIX}issue-20.xml`).mediaContents;
      expect(mediaContents.length).assertEqual(1);
      expect(mediaContents[0].reference.toString()).assertEqual('http://www.foo.com/path/containing%20spaces/trailer.mov');
    });
    it('testParseMediaRss15', 0, () => {
      const md = firstModule(`${PREFIX}issue-15.xml`).metadata!;
      expect(md.community!.starRating !== null && md.community!.statistics !== null).assertTrue();
      expect(md.community!.tags.length > 0).assertTrue();
      expect(md.comments.length).assertEqual(2);
      expect(md.responses.length).assertEqual(2);
      expect(md.backLinks.length).assertEqual(2);
      expect(md.status !== null).assertTrue();
      expect(md.prices.length).assertEqual(1);
      expect(md.embed!.params.length).assertEqual(5);
      expect(md.licenses.length).assertEqual(1);
      expect(md.subTitles.length).assertEqual(1);
      expect(md.peerLinks.length).assertEqual(1);
      expect(md.locations.length).assertEqual(1);
      expect(md.rights !== null).assertTrue();
      expect(md.scenes.length).assertEqual(1);
    });
    // ROME diffs the written XML with XMLUnit; here the written media elements must parse back to the same module.
    it('testMediaRss15Generator', 0, () => {
      const module = firstModule(`${PREFIX}issue-15.xml`);
      const item = new Element('item');
      new MediaModuleGenerator().generate(module, item);
      const reparsed = new MediaModuleParser().parse(item)!;
      expect(JSON.stringify(serialize(reparsed).toJson())).assertEqual(JSON.stringify(serialize(module).toJson()));
    });
    it('testParseRestrictionWithoutType', 0, () => {
      expect(firstModule(`${PREFIX}issue-331.xml`).metadata!.restrictions.length > 0).assertTrue();
    });
  });

  describe('MediarssGolden', () => {
    GOLDEN_FIXTURES.forEach((id: string) => {
      KINDS.filter((kind: string) => fixture(id).has('full', kind)).forEach((kind: string) => {
        it(`${kind} ${id}`, 0, () => {
          assertGolden(id, 'full', kind);
        });
      });
    });
  });

  describe('MediarssPlugins', () => {
    it('registeredAtRomePropertiesPositions', 0, () => {
      const registry = profileRegistry('full');
      const uris = (scope: string): string =>
        registry.getModuleParsers(scope).map((p: ModuleParser) => p.getNamespaceUri()).join(' ');
      expect(uris('rss_2.0.feed')).assertEqual('http://purl.org/dc/elements/1.1/ ' +
        'http://backend.userland.com/creativeCommonsRssModule ' +
        'http://purl.org/rss/1.0/modules/content/ http://www.itunes.com/dtds/podcast-1.0.dtd ' +
        'http://a9.com/-/spec/opensearch/1.1/ http://www.georss.org/georss http://www.w3.org/2003/01/geo/wgs84_pos# ' +
        'http://search.yahoo.com/mrss/ http://www.w3.org/2005/Atom ' +
        'http://www.itunes.com/DTDs/Podcast-1.0.dtd http://search.yahoo.com/mrss');
      expect(uris('rss_2.0.item')).assertEqual('http://purl.org/dc/elements/1.1/ ' +
        'http://backend.userland.com/creativeCommonsRssModule ' +
        'http://purl.org/rss/1.0/modules/content/ http://purl.org/rss/1.0/modules/slash/ ' +
        'http://www.itunes.com/dtds/podcast-1.0.dtd http://search.yahoo.com/mrss/ http://www.w3.org/2005/Atom ' +
        'http://a9.com/-/spec/opensearch/1.1/ http://www.georss.org/georss http://www.w3.org/2003/01/geo/wgs84_pos# ' +
        'http://www.itunes.com/DTDs/Podcast-1.0.dtd http://search.yahoo.com/mrss ' +
        'http://podlove.org/simple-chapters');
      expect(uris('rss_2.0yahoo.item')).assertEqual('http://search.yahoo.com/mrss/');
      const types = registry.getFeedParserTypes();
      expect(types[types.length - 1]).assertEqual('rss_2.0yahoo');
    });
  });

  describe('RSS20YahooParser', () => {
    it('isMyTypeChecksTheDefaultNamespace', 0, () => {
      const parser = new RSS20YahooParser();
      expect(parser.isMyType(parseXml(YAHOO_FEED))).assertTrue();
      expect(parser.isMyType(parseXml('<rss version="2.0"><channel/></rss>'))).assertFalse();
    });
    // RSS20Parser comes first in rome.properties and accepts any root named rss with version 2.0.
    it('rss20ParserClaimsAYahooRssRootFirst', 0, () => {
      usePluginRegistry(profileRegistry('full'));
      try {
        const document = parseXml(YAHOO_FEED);
        expect(plugins().getFeedParsers().find((p: WireFeedParser) => p.isMyType(document))!.getType())
          .assertEqual('rss_2.0');
      } finally {
        usePluginRegistry(null);
      }
    });
    it('parsesAsRss20WithMediaModules', 0, () => {
      usePluginRegistry(profileRegistry('full'));
      try {
        const feed = new SyndFeed(new RSS20YahooParser().parse(parseXml(YAHOO_FEED)));
        expect(feed.feedType).assertEqual('rss_2.0');
        expect(feed.title).assertEqual('Yahoo');
        const module = feed.entries[0].getModule(MediaModule.URI) as MediaEntryModule;
        expect(module.mediaContents[0].bitrate).assertEqual(128.5);
      } finally {
        usePluginRegistry(null);
      }
    });
  });

  describe('JavaFloatingString', () => {
    it('matchesFloatAndDoubleToString', 0, () => {
      expect(javaFloatingString(128, true)).assertEqual('128.0');
      expect(javaFloatingString(Math.fround(0.1), true)).assertEqual('0.1');
      expect(javaFloatingString(Math.fround(123456.7), true)).assertEqual('123456.7');
      expect(javaFloatingString(Math.fround(0.001), true)).assertEqual('0.001');
      expect(javaFloatingString(Math.fround(1e-4), true)).assertEqual('1.0E-4');
      expect(javaFloatingString(1e7, true)).assertEqual('1.0E7');
      expect(javaFloatingString(-2.5, true)).assertEqual('-2.5');
      expect(javaFloatingString(4.61, false)).assertEqual('4.61');
      expect(javaFloatingString(0.1 + 0.2, false)).assertEqual('0.30000000000000004');
    });
  });
}
