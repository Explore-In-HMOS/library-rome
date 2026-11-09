// Ported from ROME rome-modules/src/test/java/com/rometools/modules/atom/{AtomParserTest,AtomGeneratorTest,AtomLinkTest}.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Element, Namespace } from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { fixXml } from '../main/ets/io/impl/XmlFixerReader';
import { Link } from '../main/ets/feed/atom/Link';
import { Channel } from '../main/ets/feed/rss/Channel';
import { SyndPerson } from '../main/ets/feed/synd/SyndPerson';
import { RSS20Parser } from '../main/ets/io/impl/RSS20Parser';
import { AtomModuleGenerator } from '../main/ets/modules/atom/io/AtomModuleGenerator';
import { AtomModuleParser } from '../main/ets/modules/atom/io/AtomModuleParser';
import { AtomLinkModule } from '../main/ets/modules/atom/modules/AtomLinkModule';
import { assertGolden, fixture } from './golden/Golden';

const FIXTURE: string = 'modules/atom/rss.xml';

// ROME reads these through SyndFeedInput, but the RSS-to-Synd converter only clones the wire modules, so the tests
// read the wire channel and item.
function channel(): Channel {
  return new RSS20Parser().parse(parseXml(fixXml(fixture(FIXTURE).xml))) as Channel;
}

function assertLoremIpsum(persons: SyndPerson[]): void {
  expect(persons.length).assertEqual(1);
  for (const p of persons) {
    expect(p.name).assertEqual('Lorem Ipsum');
    expect(p.email).assertEqual('test@example.org');
    expect(p.uri).assertEqual('http://example.org');
  }
}

export default function atomModuleTest() {
  describe('AtomModule', () => {
    // synd, convert.* and roundtrip* need the RSS converters and generators (A5, A6).
    it('fullWireGolden', 0, () => {
      assertGolden(FIXTURE, 'full', 'wire');
    });

    it('AtomParserTest.testParse', 0, () => {
      const feed = channel();
      const feedModule = feed.getModule(AtomLinkModule.URI) as AtomLinkModule;
      assertLoremIpsum(feedModule.authors);
      assertLoremIpsum(feedModule.contributors);
      const entryModule = feed.items[0].getModule(AtomLinkModule.URI) as AtomLinkModule;
      assertLoremIpsum(entryModule.authors);
      assertLoremIpsum(entryModule.contributors);
    });

    it('AtomParserTest.testGetNamespaceUri', 0, () => {
      expect(new AtomModuleParser().getNamespaceUri()).assertEqual(AtomLinkModule.URI);
    });

    // ROME writes the whole feed with SyndFeedOutput (needs A5, A6); this runs the module generator on the parsed module,
    // under a root that declares the generator's namespaces as the feed generator does.
    it('AtomGeneratorTest.testGenerate', 0, () => {
      const generator = new AtomModuleGenerator();
      const rss = new Element('rss');
      generator.getNamespaces().forEach((ns: Namespace) => rss.addNamespaceDeclaration(ns));
      const element = new Element('channel');
      rss.addContent(element);
      generator.generate(channel().getModule(AtomLinkModule.URI)!, element);
      const xml = new XMLOutputter().outputString(rss);
      expect(xml).assertContain('xmlns:atom="http://www.w3.org/2005/Atom"');
      expect(xml).assertContain('<atom:author>');
      expect(xml).assertContain('<atom:contributor>');
      expect(xml).assertContain('<atom:name>Lorem Ipsum</atom:name>');
      expect(xml).assertContain('<atom:email>test@example.org</atom:email>');
      expect(xml).assertContain('<atom:uri>http://example.org</atom:uri>');
      expect(xml).assertContain('<atom:link href="http://test.com" type="application/rss+xml" rel="self" />');
    });

    it('AtomGeneratorTest.testGetNamespaceUri', 0, () => {
      expect(new AtomModuleGenerator().getNamespaceUri()).assertEqual(AtomLinkModule.URI);
      expect(new AtomModuleGenerator().getNamespaces()[0].getPrefix()).assertEqual('atom');
    });

    it('AtomLinkTest.test', 0, () => {
      const links = (channel().getModule(AtomLinkModule.URI) as AtomLinkModule).links;
      expect(links.map((l: Link) => `${l.href} ${l.rel} ${l.type}`).join('|'))
        .assertEqual('http://test.com self application/rss+xml|http://test.com/alt alternate application/rss+xml');
    });

    it('AtomLinkTest.testSetLinkShouldWork', 0, () => {
      const module = new AtomLinkModule();
      const link = new Link();
      module.link = link;
      expect(module.link).assertEqual(link);
      const second = new Link();
      module.link = second;
      expect(module.links.length).assertEqual(1);
      expect(module.link).assertEqual(second);
    });

    it('onlyChannelAndItemHaveTheModule', 0, () => {
      expect(new AtomModuleParser().parse(new Element('feed'))).assertNull();
    });

    it('cloneCopiesLinksAndPersons', 0, () => {
      const original = channel().getModule(AtomLinkModule.URI) as AtomLinkModule;
      const copy = original.clone();
      expect(copy.links[0] === original.links[0]).assertFalse();
      expect(copy.links[1].href).assertEqual('http://test.com/alt');
      expect(copy.authors[0] === original.authors[0]).assertFalse();
      expect(copy.contributors[0].uri).assertEqual('http://example.org');
    });
  });
}
