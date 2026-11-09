// Ported from ROME rome-modules/src/test/java/com/rometools/modules/content/{ContentItemTest,ContentModuleImplTest,ContentModuleParserTest,ContentModuleGeneratorTest}.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { parseXml } from '../main/ets/xml/XmlParser';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { RSS10Parser } from '../main/ets/io/impl/RSS10Parser';
import { plugins, usePluginRegistry } from '../main/ets/io/impl/PluginRegistry';
import { ContentItem } from '../main/ets/modules/content/ContentItem';
import { ContentModule } from '../main/ets/modules/content/ContentModule';
import { assertGolden, fixture, profileRegistry } from './golden/Golden';

// The fixtures with content: or slash: elements. Not here until their modules land: modules/data/YahooTopSongs.xml
// (mediarss, atom). modules/data/geo-rss-issue-27.rss runs in GeoRSS.test.ets.
const FIXTURES: string[] = ['modules/org/rometools/feed/module/content/test-rdf.xml', 'modules/xml/slashdot.xml',
  'modules/xml/test-rdf.xml', 'modules/xml/totsp.xml', 'rome/jira_issue1.xml', 'rome/rss_1.0-ns-on-channel.xml',
  'rome/rss_1.0.xml', 'rome/rss_1.0_DC_multi.xml', 'rome/rss_1.0_DC_Sy.xml', 'rome/rss_2.0.xml'];

function contentItems(): ContentItem[] {
  let item = new ContentItem();
  item.contentFormat = 'http://www.w3.org/1999/xhtml';
  item.contentEncoding = 'http://www.w3.org/TR/REC-xml#dt-wellformed';
  item.contentValue = '<em>This is <strong>very</strong></em> <strong>cool</strong>.';
  item.contentValueParseType = 'Literal';
  const items: ContentItem[] = [item];
  item = new ContentItem();
  item.contentFormat = 'http://www.w3.org/TR/html4/';
  item.contentValue = '<em>This is<strong>very</em> cool</strong>.';
  items.push(item);
  item = new ContentItem();
  item.contentAbout = 'http://example.org/item/content-here.txt';
  item.contentFormat = 'http://www.isi.edu/in-notes/iana/assignments/media-types/text/plain';
  item.contentValue = 'This is &gt;very cool&lt;.';
  items.push(item);
  item = new ContentItem();
  item.contentAbout = 'http://example.org/item/content.svg';
  item.contentResource = 'http://www.w3.org/2000/svg';
  items.push(item);
  return items;
}

function testRdfFeed(): SyndFeed {
  usePluginRegistry(profileRegistry('full'));
  try {
    return new SyndFeed(new RSS10Parser().parse(parseXml(fixture('modules/xml/test-rdf.xml').xml)));
  } finally {
    usePluginRegistry(null);
  }
}

export default function contentSlashTest() {
  describe('ContentItemTest', () => {
    const item = new ContentItem();

    it('testContentFormat', 0, () => {
      item.contentFormat = 'application/xhtml';
      expect(item.contentFormat).assertEqual('application/xhtml');
    });

    it('testContentEncoding', 0, () => {
      item.contentFormat = 'http://www.w3.org/TR/REC-xml#dt-wellformed';
      expect(item.contentFormat).assertEqual('http://www.w3.org/TR/REC-xml#dt-wellformed');
    });

    it('testContentValue', 0, () => {
      item.contentFormat = '<em>This is<strong>very</em> cool</strong>.';
      expect(item.contentFormat).assertEqual('<em>This is<strong>very</em> cool</strong>.');
    });

    it('testContentAbout', 0, () => {
      item.contentFormat = 'http://example.org/item/content.svg';
      expect(item.contentFormat).assertEqual('http://example.org/item/content.svg');
    });

    it('testContentValueParseType', 0, () => {
      item.contentFormat = 'Literal';
      expect(item.contentFormat).assertEqual('Literal');
    });

    it('testContentValueNamespace', 0, () => {
      item.contentFormat = 'http://www.w3.org/1999/xhtml';
      expect(item.contentFormat).assertEqual('http://www.w3.org/1999/xhtml');
    });

    it('testContentResource', 0, () => {
      item.contentResource = 'http://www.w3.org/2000/svg';
      expect(item.contentResource).assertEqual('http://www.w3.org/2000/svg');
    });

    it('testEquals', 0, () => {
      const item2 = new ContentItem();
      item2.contentFormat = 'http://www.w3.org/1999/xhtml';
      item2.contentEncoding = 'http://www.w3.org/TR/REC-xml#dt-wellformed';
      item2.contentValue = '<em>This is <strong>very</strong></em> <strong>cool</strong>.';
      item2.contentValueParseType = 'Literal';
      expect(contentItems()[0].equals(item2)).assertTrue();
      item2.contentValueParseType = null;
      expect(contentItems()[0].equals(item2)).assertFalse();
    });
  });

  // testInterface is not ported: there is no getInterface() (CONTRIBUTING.md, one class per module).
  describe('ContentModuleImplTest', () => {
    const module = new ContentModule();

    it('testEncodeds', 0, () => {
      const encodeds = ['Foo', 'Bar', 'Baz'];
      module.encodeds = encodeds;
      expect(module.encodeds).assertDeepEquals(encodeds);
    });

    it('testContentItems', 0, () => {
      const items = contentItems();
      module.contentItems = items;
      expect(module.contentItems).assertDeepEquals(items);
    });

    it('testContents', 0, () => {
      const contents = ['Foo', 'Bar', 'Baz'];
      module.contents = contents;
      expect(module.contents).assertDeepEquals(contents);
    });

    it('testCopyFrom', 0, () => {
      const test = new ContentModule();
      test.copyFrom(module);
      expect(test.contentItems).assertDeepEquals(module.contentItems);
      expect(test.contents).assertDeepEquals(module.contents);
      expect(test.encodeds).assertDeepEquals(module.encodeds);
    });
  });

  describe('ContentModuleParserTest', () => {
    // ROME's loop body is a FIXME; this checks the items it would iterate.
    it('testParse', 0, () => {
      const module = testRdfFeed().entries[0].getModule(ContentModule.URI) as ContentModule;
      expect(module.contentItems.length).assertEqual(4);
      expect(module.contentItems[1].contentValue).assertEqual('<em>This is<strong>very</em> cool</strong>.');
    });
  });

  describe('ContentModuleGeneratorTest', () => {
    // As SyndFeedOutput does: the feed is converted back to a wire feed and generated with the rss_1.0 generator.
    it('testGenerate', 0, () => {
      const feed = testRdfFeed();
      usePluginRegistry(profileRegistry('full'));
      try {
        const wire = feed.createWireFeed(feed.feedType!);
        const xml = new XMLOutputter().outputString(plugins().getFeedGenerator('rss_1.0')!.generate(wire));
        expect(xml.includes('<content:items><rdf:Bag><rdf:li><content:item>')).assertTrue();
      } finally {
        usePluginRegistry(null);
      }
    });
  });

  describe('ContentSlashGolden', () => {
    FIXTURES.forEach((id: string) => {
      ['wire', 'synd', 'roundtrip'].filter((kind: string) => fixture(id).has('full', kind)).forEach((kind: string) => {
        it(`${kind} ${id}`, 0, () => {
          assertGolden(id, 'full', kind);
        });
      });
    });
  });
}
