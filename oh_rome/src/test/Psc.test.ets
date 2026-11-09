// Ported from ROME rome-modules/src/test/java/com/rometools/modules/psc/{PodloveSimpleChapterParserTest,PodloveSimpleChapterGeneratorTest}.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Element } from '../main/ets/xml/Dom';
import { Format } from '../main/ets/xml/Format';
import { parseXml } from '../main/ets/xml/XmlParser';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { fixXml } from '../main/ets/io/impl/XmlFixerReader';
import { Channel } from '../main/ets/feed/rss/Channel';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { Atom10Generator } from '../main/ets/io/impl/Atom10Generator';
import { Atom10Parser } from '../main/ets/io/impl/Atom10Parser';
import { RSS20Parser } from '../main/ets/io/impl/RSS20Parser';
import { PodloveSimpleChapterGenerator } from '../main/ets/modules/psc/io/PodloveSimpleChapterGenerator';
import { PodloveSimpleChapterParser } from '../main/ets/modules/psc/io/PodloveSimpleChapterParser';
import { PodloveSimpleChapterModule } from '../main/ets/modules/psc/modules/PodloveSimpleChapterModule';
import { SimpleChapter } from '../main/ets/modules/psc/types/SimpleChapter';
import { assertGolden, fixture } from './golden/Golden';

const CHAPTER: string = '<psc:chapter start="00:00:00.000" title="Lorem Ipsum" href="http://example.org" ' +
  'image="http://example.org/cover" />';

function assertChapters(module: PodloveSimpleChapterModule | null): void {
  expect(module).not().assertNull();
  expect(module!.chapters.length).assertEqual(3);
  for (const c of module!.chapters) {
    expect(c.start).assertEqual('00:00:00.000');
    expect(c.title).assertEqual('Lorem Ipsum');
    expect(c.href).assertEqual('http://example.org');
    expect(c.image).assertEqual('http://example.org/cover');
  }
}

function atomFeed(): SyndFeed {
  return new SyndFeed(new Atom10Parser().parse(parseXml(fixXml(fixture('modules/psc/atom.xml').xml))));
}

function rssItemModule(): PodloveSimpleChapterModule | null {
  const channel = new RSS20Parser().parse(parseXml(fixXml(fixture('modules/psc/rss.xml').xml))) as Channel;
  return channel.items[0].getModule(PodloveSimpleChapterModule.URI) as PodloveSimpleChapterModule | null;
}

export default function pscTest() {
  describe('Psc', () => {
    it('fullGoldens', 0, () => {
      for (const id of ['modules/psc/rss.xml', 'modules/psc/atom.xml']) {
        for (const kind of ['wire', 'synd', 'roundtrip.xml', 'roundtrip', 'convert.atom_1.0', 'convert.rss_2.0']) {
          assertGolden(id, 'full', kind);
        }
      }
    });

    // ROME reads the SyndEntry; the RSS-to-Synd converter only clones the wire item's modules.
    it('PodloveSimpleChapterParserTest.testParseRss', 0, () => {
      assertChapters(rssItemModule());
    });

    it('PodloveSimpleChapterParserTest.testParseAtom', 0, () => {
      assertChapters(atomFeed().entries[0].getModule(PodloveSimpleChapterModule.URI) as PodloveSimpleChapterModule | null);
    });

    it('PodloveSimpleChapterParserTest.testGetNamespaceUri', 0, () => {
      expect(new PodloveSimpleChapterParser().getNamespaceUri()).assertEqual(PodloveSimpleChapterModule.URI);
    });

    // ROME writes the RSS feed with SyndFeedOutput (needs A5, A6); this runs the module generator on the parsed module.
    it('PodloveSimpleChapterGeneratorTest.testGenerateRss', 0, () => {
      const item = new Element('item');
      new PodloveSimpleChapterGenerator().generate(rssItemModule()!, item);
      const xml = new XMLOutputter().outputString(item);
      expect(xml).assertContain('xmlns:psc="http://podlove.org/simple-chapters"');
      expect(xml).assertContain('<psc:chapters xmlns:psc="http://podlove.org/simple-chapters" version="1.2">');
      expect(xml).assertContain(CHAPTER);
    });

    it('PodloveSimpleChapterGeneratorTest.testGenerateAtom', 0, () => {
      const feed = atomFeed();
      const xml = new XMLOutputter(Format.getPrettyFormat()).outputString(new Atom10Generator().generate(feed.createWireFeed()));
      expect(xml).assertContain('xmlns:psc="http://podlove.org/simple-chapters"');
      expect(xml).assertContain('<psc:chapters version="1.2">');
      expect(xml).assertContain(CHAPTER);
    });

    it('PodloveSimpleChapterGeneratorTest.testGetNamespaceUri', 0, () => {
      expect(new PodloveSimpleChapterGenerator().getNamespaceUri()).assertEqual(PodloveSimpleChapterModule.URI);
    });

    it('cloneCopiesChapters', 0, () => {
      const m = rssItemModule()!;
      const copy = m.clone();
      expect(copy.chapters[0] === m.chapters[0]).assertFalse();
      expect(copy.chapters.map((c: SimpleChapter) => c.title).join()).assertEqual('Lorem Ipsum,Lorem Ipsum,Lorem Ipsum');
    });

    it('emptyChaptersGiveNoModule', 0, () => {
      const xml = '<item xmlns:psc="http://podlove.org/simple-chapters"><psc:chapters version="1.2"/></item>';
      expect(new PodloveSimpleChapterParser().parse(parseXml(xml).getRootElement())).assertNull();
    });
  });
}
