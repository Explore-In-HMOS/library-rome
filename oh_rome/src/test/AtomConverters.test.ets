import { afterEach, describe, expect, it } from '@ohos/hypium';
import { parseXml } from '../main/ets/xml/XmlParser';
import { fixXml } from '../main/ets/io/impl/XmlFixerReader';
import { Entry } from '../main/ets/feed/atom/Entry';
import { Feed } from '../main/ets/feed/atom/Feed';
import { Link } from '../main/ets/feed/atom/Link';
import { SyndEnclosure } from '../main/ets/feed/synd/SyndEnclosure';
import { SyndEntry } from '../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { SyndLink } from '../main/ets/feed/synd/SyndLink';
import { ConverterForAtom03 } from '../main/ets/feed/synd/impl/ConverterForAtom03';
import { Atom03Parser } from '../main/ets/io/impl/Atom03Parser';
import { Atom10Parser } from '../main/ets/io/impl/Atom10Parser';
import { PluginRegistry } from '../main/ets/io/impl/PluginRegistry';
import { registerCorePlugins } from '../main/ets/io/impl/DefaultPlugins';
import { assertGolden, fixture } from './golden/Golden';

const ATOM_FIXTURES: string[] = ['rome/atom_0.3.xml', 'rome/atom_0.3_DC_Sy.xml', 'rome/atom_1.0.xml', 'rome/atom_1.0_b.xml',
  'rome/atom_1.0_bray.xml', 'rome/atom_1.0_prefix.xml', 'rome/atom_1.0_ruby.xml'];

// Atom feeds among the module fixtures whose full/wire golden passes (see AtomParsers.test.ets).
const MODULE_ATOM_FIXTURES: string[] = [
  'modules/base/courses-atombase.xml',
  'modules/base/custom-tags-examplebase.xml',
  'modules/base/events-atombase.xml',
  'modules/base/housing-atombase.xml',
  'modules/base/jobs-atombase.xml',
  'modules/base/news-atom.xml',
  'modules/base/personals-atom.xml',
  'modules/base/products-atom.xml',
  'modules/base/research-atom.xml',
  'modules/base/reviews-atom.xml',
  'modules/base/services-atom.xml',
  'modules/base/travel-atom.xml',
  'modules/base/vehicles-atom.xml',
  'modules/base/wanted-atom.xml',
  'modules/xml/courses-atom.xml',
  'modules/xml/custom-tags-example.xml',
  'modules/xml/events-atom.xml',
  'modules/xml/housing-atom.xml',
  'modules/xml/jobs-atom.xml',
  'modules/xml/news-atom.xml',
  'modules/xml/personals-atom.xml',
  'modules/xml/products-atom.xml',
  'modules/xml/research-atom.xml',
  'modules/xml/reviews-atom.xml',
  'modules/xml/services-atom.xml',
  'modules/xml/travel-atom.xml',
  'modules/xml/vehicles-atom.xml',
  'modules/xml/wanted-atom.xml'
];

function readFixture(id: string, preserveWireFeed: boolean): SyndFeed {
  const document = parseXml(fixXml(fixture(id).xml));
  const parser = new Atom10Parser();
  const wire = parser.isMyType(document) ? parser.parse(document) : new Atom03Parser().parse(document);
  return new SyndFeed(wire, preserveWireFeed);
}

function convertKinds(id: string, profile: string): string[] {
  return fixture(id).kinds(profile).filter((kind: string) => kind.startsWith('convert.'));
}

function link(rel: string | null, href: string): SyndLink {
  const l = new SyndLink();
  l.rel = rel;
  l.href = href;
  return l;
}

function entryWithEnclosure(links: SyndLink[]): SyndFeed {
  const feed = new SyndFeed();
  const entry = new SyndEntry();
  entry.links = links;
  const enclosure = new SyndEnclosure();
  enclosure.url = 'http://e/enc.mp3';
  enclosure.length = 7;
  entry.enclosures = [enclosure];
  feed.entries = [entry];
  return feed;
}

function describeLinks(links: Link[]): string {
  return links.map((l: Link) => `${l.rel}:${l.href}:${l.length}`).join(' ');
}

export default function atomConvertersTest() {
  describe('AtomConverters', () => {
    afterEach(() => {
      Atom10Parser.setResolveURIs(false);
    });

    it('coreSyndGoldens', 0, () => {
      for (const id of ATOM_FIXTURES) {
        assertGolden(id, 'core', 'synd');
      }
    });

    it('fullSyndGoldens', 0, () => {
      for (const id of ATOM_FIXTURES.concat(MODULE_ATOM_FIXTURES)) {
        assertGolden(id, 'full', 'synd');
      }
    });

    it('coreConvertGoldens', 0, () => {
      for (const id of ATOM_FIXTURES) {
        convertKinds(id, 'core').forEach((kind: string) => assertGolden(id, 'core', kind));
      }
    });

    it('fullConvertGoldens', 0, () => {
      for (const id of ATOM_FIXTURES.concat(MODULE_ATOM_FIXTURES)) {
        convertKinds(id, 'full').forEach((kind: string) => assertGolden(id, 'full', kind));
      }
    });

    it('registeredFirstInPropertiesOrder', 0, () => {
      const registry = new PluginRegistry();
      registerCorePlugins(registry);
      expect(registry.getConverterTypes().slice(0, 2).join()).assertEqual('atom_1.0,atom_0.3');
    });

    // TestSyndFeedAtom10.testPreservedWireItems and SyndFeedTest.testPreserveWireFeed.
    it('preservesWireFeedAndEntries', 0, () => {
      const feed = readFixture('rome/atom_1.0.xml', true);
      expect(feed.originalWireFeed() instanceof Feed).assertTrue();
      const wireEntry = feed.entries[0].wireEntry;
      expect(wireEntry instanceof Entry).assertTrue();
      expect((wireEntry as Entry).rights).assertEqual('atom_1.0.feed.entry[0].rights');
      const feed03 = readFixture('rome/atom_0.3.xml', true);
      expect(feed03.originalWireFeed() instanceof Feed).assertTrue();
      expect(feed03.entries[0].wireEntry instanceof Entry).assertTrue();
      expect(readFixture('rome/atom_1.0.xml', false).entries[0].wireEntry).assertNull();
    });

    // TestSyndFeedAtom10b.testXmlBaseConformance, TestSyndFeedAtom10Bray and TestSyndFeedAtom10Ruby (resolveURIs on).
    it('resolvedLinksWithResolveURIs', 0, () => {
      Atom10Parser.setResolveURIs(true);
      const b = readFixture('rome/atom_1.0_b.xml', false);
      expect(b.entries.length > 0).assertTrue();
      for (const entry of b.entries) {
        expect(entry.link).assertEqual('http://example.org/tests/base/result.html');
      }
      const bray = readFixture('rome/atom_1.0_bray.xml', false);
      expect(bray.uri).assertEqual('http://www.example.com/blog');
      expect(bray.entries[0].link).assertEqual('http://www.example.com/blog/2006-11-05/entry1');
      expect(bray.entries[1].link).assertEqual('http://www.example.com/blog/2006-11-02/entry2');
      const ruby = readFixture('rome/atom_1.0_ruby.xml', false);
      expect(ruby.uri).assertEqual('http://www.example.com/blog');
      expect(ruby.entries[0].link).assertEqual('http://www.example.com/blog/bloggy-blog');
      expect(ruby.entries[1].link).assertEqual('http://www.example.com/frog/froggy-frog');
    });

    it('atom10EnclosuresNotDuplicatedByEnclosureLinks', 0, () => {
      const withLink = entryWithEnclosure([link('enclosure', 'http://e/link.mp3')]);
      withLink.feedType = 'atom_1.0';
      const entry = (withLink.createWireFeed() as Feed).entries[0];
      expect(describeLinks(entry.otherLinks)).assertEqual('enclosure:http://e/link.mp3:0');
      expect(describeLinks(entry.alternateLinks)).assertEqual('');

      const without = entryWithEnclosure([link(null, 'http://e/a'), link('related', 'http://e/r')]);
      const entry2 = (without.createWireFeed('atom_1.0') as Feed).entries[0];
      expect(describeLinks(entry2.alternateLinks)).assertEqual('null:http://e/a:0');
      expect(describeLinks(entry2.otherLinks)).assertEqual('related:http://e/r:0 enclosure:http://e/enc.mp3:7');
      expect(entry2.authors.length).assertEqual(1);
      expect(entry2.authors[0].name).assertEqual('');
    });

    it('atom03AlwaysAddsEnclosuresAndRejectsNullContentMode', 0, () => {
      const feed = entryWithEnclosure([link('enclosure', 'http://e/link.mp3')]);
      const entry = (feed.createWireFeed('atom_0.3') as Feed).entries[0];
      expect(describeLinks(entry.otherLinks)).assertEqual('enclosure:http://e/link.mp3:0 enclosure:http://e/enc.mp3:7');

      const withContent = readFixture('rome/atom_1.0.xml', false);
      let message = '';
      try {
        withContent.createWireFeed('atom_0.3');
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Invalid mode [null]');
    });

    it('atom03NullLinkRelThrowsLikeJava', 0, () => {
      const wire = new Feed('atom_0.3');
      const l = new Link();
      l.rel = null;
      l.href = 'x';
      wire.otherLinks = [l];
      let threw = false;
      try {
        new ConverterForAtom03().copyInto(wire, new SyndFeed());
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });
  });
}
