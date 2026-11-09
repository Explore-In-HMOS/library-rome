// Ported from ROME rome-modules/src/test/java/com/rometools/modules/thr/io/ThreadingModuleTest.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Format } from '../main/ets/xml/Format';
import { parseXml } from '../main/ets/xml/XmlParser';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { fixXml } from '../main/ets/io/impl/XmlFixerReader';
import { SyndEntry } from '../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { Atom10Generator } from '../main/ets/io/impl/Atom10Generator';
import { Atom10Parser } from '../main/ets/io/impl/Atom10Parser';
import { ThreadingModule } from '../main/ets/modules/thr/ThreadingModule';
import { assertGolden, fixture, serialize } from './golden/Golden';

const FIXTURE: string = 'modules/thr/threading-main.xml';

function read(xml: string): SyndFeed {
  return new SyndFeed(new Atom10Parser().parse(parseXml(fixXml(xml))));
}

// SyndFeedOutput: the Atom 1.0 generator, pretty printed.
function write(feed: SyndFeed): string {
  return new XMLOutputter(Format.getPrettyFormat()).outputString(new Atom10Generator().generate(feed.createWireFeed()));
}

export default function thrTest() {
  describe('Thr', () => {
    it('fullGoldens', 0, () => {
      for (const kind of ['wire', 'synd', 'roundtrip.xml', 'roundtrip', 'convert.atom_1.0', 'convert.rss_2.0']) {
        assertGolden(FIXTURE, 'full', kind);
      }
    });

    it('ThreadingModuleTest.testReadMainSpec', 0, () => {
      const entries = read(fixture(FIXTURE).xml).entries;
      expect(entries[0].title).assertEqual('My original entry');
      expect(entries[0].getModule(ThreadingModule.URI)).assertNull();
      expect(entries[1].title).assertEqual('A response to the original');
      const module = entries[1].getModule(ThreadingModule.URI) as ThreadingModule;
      expect(module.ref).assertEqual('tag:example.org,2005:1');
      expect(module.type).assertEqual('application/xhtml+xml');
      expect(module.href).assertEqual('http://www.example.org/entries/1');
      expect(module.source).assertNull();
    });

    it('ThreadingModuleTest.testGenerate', 0, () => {
      const feed = read(fixture(FIXTURE).xml);
      const newRootEntry = new SyndEntry();
      newRootEntry.title = 'New, 2nd root entry';
      newRootEntry.uri = 'tag:example.org,2005:2';
      newRootEntry.link = 'http://www.example.org/entries/2';
      feed.entries.push(newRootEntry);
      const newReplyEntry = new SyndEntry();
      newReplyEntry.title = 'New test reply entry';
      newReplyEntry.uri = 'tag:example.org,2005:2,1';
      const threadingModule = new ThreadingModule();
      threadingModule.ref = 'tag:example.org,2005:2';
      threadingModule.type = 'application/xhtml+xml';
      threadingModule.href = 'http://www.example.org/entries/2';
      threadingModule.source = 'http://example.org/entries/2';
      newReplyEntry.modules.push(threadingModule);
      feed.entries.push(newReplyEntry);

      const generated = read(write(feed)).entries[3].getModule(ThreadingModule.URI) as ThreadingModule;
      expect(generated.ref).assertEqual('tag:example.org,2005:2');
      expect(generated.type).assertEqual('application/xhtml+xml');
      expect(generated.href).assertEqual('http://www.example.org/entries/2');
      expect(generated.source).assertEqual('http://example.org/entries/2');
    });

    it('ThreadingModuleTest.testEnd2End', 0, () => {
      const feed = read(fixture(FIXTURE).xml);
      const feedOut = read(write(feed));
      const moduleSrc = feed.entries[1].getModule(ThreadingModule.URI) as ThreadingModule;
      const moduleOut = feedOut.entries[1].getModule(ThreadingModule.URI) as ThreadingModule;
      expect(serialize(moduleOut).toJson()).assertEqual(serialize(moduleSrc).toJson());
      expect(moduleSrc.ref).assertEqual('tag:example.org,2005:1');
      expect(moduleOut.ref).assertEqual('tag:example.org,2005:1');
    });
  });
}
