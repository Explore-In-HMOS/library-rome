// Ported from ROME rome/src/test/java/com/rometools/rome/unittest/issues/Issue131Test.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { parseXml } from '../main/ets/xml/XmlParser';
import { SyndCategory } from '../main/ets/feed/synd/SyndCategory';
import { SyndEntry } from '../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { RSS20Parser } from '../main/ets/io/impl/RSS20Parser';
import { assertGolden, fixture, fixtureIds } from './golden/Golden';
import { FIXTURES } from './RssParsers.test';

function checkCategories(categories: SyndCategory[], names: string[]): void {
  expect(categories.length).assertEqual(names.length);
  categories.forEach((category: SyndCategory, i: number) => {
    expect(category.taxonomyUri).assertEqual('http://somewhere.org/taxonomy');
    expect(category.name).assertEqual(names[i]);
  });
}

export default function rssConvertersTest() {
  describe('Issue131Test', () => {
    it('testOriginalCategories', 0, () => {
      const feed = new SyndFeed(new RSS20Parser().parse(parseXml(fixture('rome/issue131-rss.xml').xml)));
      checkCategories(feed.categories, ['Channel Category 1', 'Channel Category 2']);
      expect(feed.entries.length > 0).assertTrue();
      feed.entries.forEach((entry: SyndEntry) => {
        checkCategories(entry.categories, ['Entry Category 1', 'Entry Category 2']);
      });
    });
  });

  describe('RssConverterCategories', () => {
    const feedWith = (categories: string): SyndFeed => new SyndFeed(new RSS20Parser().parse(parseXml(
      `<rss version="2.0"><channel><item>${categories}</item></channel></rss>`)));

    it('duplicateCategoriesKeepFirstOccurrence', 0, () => {
      const entry = feedWith('<category>b</category><category domain="d">a</category><category>b</category>' +
        '<category>a</category><category domain="d">a</category>').entries[0];
      expect(entry.categories.map((c: SyndCategory) => `${c.taxonomyUri}|${c.name}`).join(','))
        .assertEqual('null|b,d|a,null|a');
    });

    it('distinctCategoriesAreLinear', 0, () => {
      const time = (n: number): number => {
        const parts: string[] = [];
        for (let i = 0; i < n; i++) {
          parts.push(`<category>c${i}</category>`);
        }
        const xml = parts.join('');
        const start = Date.now();
        expect(feedWith(xml).entries[0].categories.length).assertEqual(n);
        return Date.now() - start;
      };
      const small = time(2000);
      const large = time(8000);
      expect(large < small * 8 + 200).assertTrue();
    });
  });

  describe('RssConvertersGolden', () => {
    FIXTURES.concat(fixtureIds('repo/rss-convert/')).forEach((id: string) => {
      it(`synd ${id}`, 0, () => {
        assertGolden(id, 'core', 'synd');
      });
      fixture(id).kinds('core').filter((kind: string) => kind.startsWith('convert.')).forEach((kind: string) => {
        it(`${kind} ${id}`, 0, () => {
          assertGolden(id, 'core', kind);
        });
      });
    });
  });
}
