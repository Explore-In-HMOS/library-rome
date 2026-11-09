import { afterEach, describe, expect, it } from '@ohos/hypium';
import { Document, Element } from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';
import { Category } from '../main/ets/feed/atom/Category';
import { Entry } from '../main/ets/feed/atom/Entry';
import { Feed } from '../main/ets/feed/atom/Feed';
import { Link } from '../main/ets/feed/atom/Link';
import { Person } from '../main/ets/feed/atom/Person';
import { WireFeedParser } from '../main/ets/io/WireFeedParser';
import { Atom03Parser } from '../main/ets/io/impl/Atom03Parser';
import { Atom10Parser } from '../main/ets/io/impl/Atom10Parser';
import { PluginRegistry } from '../main/ets/io/impl/PluginRegistry';
import { registerCorePlugins } from '../main/ets/io/impl/DefaultPlugins';
import { assertGolden } from './golden/Golden';

const ATOM_FIXTURES: string[] = ['rome/atom_0.3.xml', 'rome/atom_0.3_DC_Sy.xml', 'rome/atom_1.0.xml', 'rome/atom_1.0_b.xml',
  'rome/atom_1.0_bray.xml', 'rome/atom_1.0_prefix.xml', 'rome/atom_1.0_ruby.xml'];

// Atom feeds among the module fixtures whose full/wire golden needs no in-scope module (the base module is out of
// scope, so its elements stay foreign markup).
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

// ROME's WireFeedOutput for the feed TestAtomContent.createFeed() builds (Atom10Generator is not ported yet).
const TEST_ATOM_CONTENT_XML = '<?xml version="1.0" encoding="UTF-8"?>\r\n<feed xmlns="http://www.w3.org/2005/Atom">\r\n' +
  '  <title type="application/xml">\r\n    <test xmlns="">Hello Hello</test>\r\n  </title>\r\n</feed>\r\n';

const RESOLVE_XML = [
  '<feed xmlns=\'http://www.w3.org/2005/Atom\' xml:base=\'http://example.org/dir/feed.xml\'>',
  ' <link rel=\'self\' href=\'http://example.org/feeds/atom.xml\'/>',
  ' <link href=\'alt.html\'/>',
  ' <link rel=\'\' href=\'/root.html\'/>',
  ' <category term=\'t\' scheme=\'schemes/s1\'/>',
  ' <author><name>A</name><uri>people/a</uri></author>',
  ' <entry xml:base=\'sub/\'>',
  '  <link href=\'../up.html\'/>',
  '  <link rel=\'related\' href=\'./x/y.html\' length=\'12\'/>',
  '  <link rel=\'enclosure\' href=\'http://other/abs\'/>',
  '  <category term=\'c\' scheme=\'../cat\'/>',
  ' </entry>',
  ' <entry xml:base=\'http://other.org/base/file\'>',
  '  <link href=\'rel.html\'/>',
  '  <link rel=\'x\' href=\'/host.html\'/>',
  ' </entry>',
  ' <entry><link href=\'.\'/></entry>',
  '</feed>'].join('\n');

function parse10(xml: string): Feed {
  return new Atom10Parser().parse(parseXml(xml)) as Feed;
}

function parse03(xml: string): Feed {
  return new Atom03Parser().parse(parseXml(xml)) as Feed;
}

function describeLinks(alternate: Link[], other: Link[]): string[] {
  const lines: string[] = [];
  for (const l of alternate) {
    lines.push(`alt ${l.rel} ${l.href} -> ${l.hrefResolved} len=${l.length}`);
  }
  for (const l of other) {
    lines.push(`other ${l.rel} ${l.href} -> ${l.hrefResolved} len=${l.length}`);
  }
  return lines;
}

// Expected lines below are what ROME 6b4a7e8 on Temurin 17.0.17+10 gives for RESOLVE_XML.
function describeResolved(feed: Feed): string[] {
  const lines: string[] = describeLinks(feed.alternateLinks, feed.otherLinks);
  lines.push(`cat ${feed.categories[0].schemeResolved}`);
  lines.push(`author ${(feed.authors[0] as Person).getUriResolved(null)}`);
  feed.entries.forEach((e: Entry, i: number) => {
    describeLinks(e.alternateLinks, e.otherLinks).forEach((l: string) => lines.push(`entry${i} ${l}`));
    e.categories.forEach((c: Category) => lines.push(`cat${i} ${c.schemeResolved}`));
  });
  return lines;
}

export default function atomParsersTest() {
  describe('AtomParsers', () => {
    afterEach(() => {
      Atom10Parser.setResolveURIs(false);
    });

    it('coreWireGoldens', 0, () => {
      for (const id of ATOM_FIXTURES) {
        assertGolden(id, 'core', 'wire');
      }
    });

    it('fullWireGoldens', 0, () => {
      for (const id of ATOM_FIXTURES) {
        assertGolden(id, 'full', 'wire');
      }
    });

    it('fullWireGoldensForModuleAtomFixtures', 0, () => {
      for (const id of MODULE_ATOM_FIXTURES) {
        assertGolden(id, 'full', 'wire');
      }
    });

    it('registeredAfterRssParsersInPropertiesOrder', 0, () => {
      const registry = new PluginRegistry();
      registerCorePlugins(registry);
      const types = registry.getFeedParsers().map((p: WireFeedParser) => p.getType());
      expect(types.indexOf('atom_1.0')).assertEqual(types.length - 2);
      expect(types.indexOf('atom_0.3')).assertEqual(types.length - 1);
    });

    it('isMyTypeChecksTheRootNamespace', 0, () => {
      const atom10 = parseXml('<feed xmlns="http://www.w3.org/2005/Atom"/>');
      const atom03 = parseXml('<a:feed xmlns:a="http://purl.org/atom/ns#"/>');
      const none = parseXml('<feed/>');
      expect(new Atom10Parser().isMyType(atom10)).assertTrue();
      expect(new Atom10Parser().isMyType(atom03)).assertFalse();
      expect(new Atom10Parser().isMyType(none)).assertFalse();
      expect(new Atom03Parser().isMyType(atom03)).assertTrue();
      expect(new Atom03Parser().isMyType(atom10)).assertFalse();
    });

    // TestAtomContent.testReadWrite, reading ROME's output. testXML checks Atom10Generator output: not ported here.
    it('testAtomContentReadWrite', 0, () => {
      const feed = parse10(TEST_ATOM_CONTENT_XML);
      expect(JSON.stringify(feed.titleEx!.value)).assertEqual(JSON.stringify('\r\n    <test>Hello Hello</test>\r\n  '));
      expect(feed.titleEx!.value!.trim()).assertEqual('<test>Hello Hello</test>');
      expect(feed.titleEx!.type).assertEqual('application/xml');
    });

    it('xhtmlContentMovesAtomElementsToNoNamespace', 0, () => {
      const feed = parse10('<feed xmlns="http://www.w3.org/2005/Atom"><entry>' +
        '<content type="xhtml"><div xmlns="http://www.w3.org/1999/xhtml">a<b>c</b></div></content>' +
        '<summary type="text/xml" src="s"><x>1</x>&amp;</summary><title type="html">&lt;i&gt;</title>' +
        '<rights>r</rights></entry></feed>');
      const entry = feed.entries[0];
      expect(entry.contents[0].value).assertEqual('<div xmlns="http://www.w3.org/1999/xhtml">a<b>c</b></div>');
      expect(entry.contents[0].type).assertEqual('xhtml');
      expect(entry.contents[0].mode).assertNull();
      expect(entry.summary!.value).assertEqual('<x>1</x>&amp;');
      expect(entry.summary!.src).assertEqual('s');
      expect(entry.titleEx!.value).assertEqual('<i>');
      expect(entry.rights).assertEqual('r');
    });

    it('linksWithoutOrWithBlankRelAreAlternate', 0, () => {
      Atom10Parser.setResolveURIs(false);
      expect(describeResolved(parse10(RESOLVE_XML)).join('\n')).assertEqual([
        'alt alternate alt.html -> alt.html len=0',
        'alt  /root.html -> /root.html len=0',
        'other self http://example.org/feeds/atom.xml -> http://example.org/feeds/atom.xml len=0',
        'other  /root.html -> /root.html len=0',
        'cat schemes/s1',
        'author people/a',
        'entry0 alt alternate ../up.html -> ../up.html len=0',
        'entry0 other related ./x/y.html -> ./x/y.html len=12',
        'entry0 other enclosure http://other/abs -> http://other/abs len=0',
        'cat0 ../cat',
        'entry1 alt alternate rel.html -> rel.html len=0',
        'entry1 other x /host.html -> /host.html len=0',
        'entry2 alt alternate . -> . len=0'].join('\n'));
    });

    it('resolvesXmlBaseWhenResolveURIsIsOn', 0, () => {
      Atom10Parser.setResolveURIs(true);
      const feed = parse10(RESOLVE_XML);
      expect(feed.xmlBase).assertEqual('http://example.org/dir/feed.xml');
      expect(feed.entries[0].xmlBase).assertEqual('sub/');
      expect(describeResolved(feed).join('\n')).assertEqual([
        'alt alternate alt.html -> http://example.org/dir/alt.html len=0',
        'alt  /root.html -> http://example.org/root.html len=0',
        'other self http://example.org/feeds/atom.xml -> http://example.org/feeds/atom.xml len=0',
        'other  /root.html -> http://example.org/root.html len=0',
        'cat http://example.org/dir/schemes/s1',
        'author http://example.org/dir/people/a',
        'entry0 alt alternate ../up.html -> http://example.org/dir/sub/../up.html len=0',
        'entry0 other related ./x/y.html -> http://example.org/dir/sub/./x/y.html len=12',
        'entry0 other enclosure http://other/abs -> http://other/abs len=0',
        'cat0 http://example.org/dir/sub/../cat',
        'entry1 alt alternate rel.html -> http://other.org/base/rel.html len=0',
        'entry1 other x /host.html -> http://example.org/host.html len=0',
        'entry2 alt alternate . -> http://example.org/dir/ len=0'].join('\n'));
    });

    it('uriHelpersMatchRome', 0, () => {
      const absolute: string[] = ['http://a/b', 'urn:x', 'mailto:x@y', 'a1:b', 'x:\n', 'x:a\n', ':a'];
      const relative: string[] = ['foo', '/foo', 'HTTP://a', 'x:a\nb', ''];
      Atom10Parser.setResolveURIs(false);
      for (const u of absolute) {
        expect(Atom10Parser.isAbsoluteURI(u)).assertTrue();
      }
      for (const u of relative) {
        expect(Atom10Parser.isRelativeURI(u)).assertTrue();
      }
      expect(Atom10Parser.resolveURI('http://h/a/b/', null, '../c')).assertEqual('../c');
      Atom10Parser.setResolveURIs(true);
      expect(Atom10Parser.getResolveURIs()).assertTrue();
      expect(Atom10Parser.resolveURI('http://h/a/b/', null, '../c')).assertEqual('http://h/a/c');
      expect(Atom10Parser.resolveURI('http://h/a/b', null, '../../c/../d')).assertEqual('http://./d');
      expect(Atom10Parser.resolveURI(null, null, 'x')).assertEqual('null/x');
      expect(Atom10Parser.resolveURI('http://h/', null, '/y')).assertEqual('http://h/y');
      let threw = false;
      try {
        Atom10Parser.resolveURI('http://h', null, '..');
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('atom03ContentModes', 0, () => {
      const feed = parse03('<feed xmlns="http://purl.org/atom/ns#"><title mode="escaped">&lt;b&gt;</title>' +
        '<tagline mode="base64" type="text/html">SGVsbG8g4pyT</tagline>' +
        '<info><a:div xmlns:a="http://purl.org/atom/ns#">x</a:div><p xmlns="urn:p"/></info>' +
        '<link rel="self" href="s"/><link href="o"/><link rel="alternate" href="a"/>' +
        '<author><name>n</name><url>u</url><email>e</email></author></feed>');
      expect(feed.titleEx!.value).assertEqual('<b>');
      expect(feed.titleEx!.type).assertEqual('text/plain');
      expect(feed.titleEx!.mode).assertEqual('escaped');
      expect(feed.tagline!.value).assertEqual('Hello \u2713');
      expect(feed.info!.value).assertEqual('<div>x</div><p xmlns="urn:p" />');
      expect(feed.info!.mode).assertEqual('xml');
      expect(feed.alternateLinks.map((l: Link) => l.href).join()).assertEqual('a');
      expect(feed.otherLinks.map((l: Link) => `${l.rel}:${l.href}`).join()).assertEqual('self:s,alternate:o');
      const author = feed.authors[0] as Person;
      expect(`${author.name} ${author.uri} ${author.email}`).assertEqual('n u e');
    });

    it('atom03InvalidModeThrows', 0, () => {
      let message = '';
      try {
        parse03('<feed xmlns="http://purl.org/atom/ns#"><title mode="Foo">t</title></feed>');
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Invalid mode [Foo]');
    });

    it('stylesheetAndForeignMarkup', 0, () => {
      const doc: Document = parseXml('<?xml-stylesheet type="text/xsl" href="s.xsl"?>' +
        '<feed xmlns="http://www.w3.org/2005/Atom" xmlns:x="urn:x"><x:a>1</x:a><entry><x:b/></entry></feed>');
      const feed = new Atom10Parser().parse(doc) as Feed;
      expect(feed.styleSheet).assertEqual('s.xsl');
      expect(feed.foreignMarkup.map((e: Element) => e.getName()).join()).assertEqual('a');
      expect(feed.foreignMarkup[0].getParent()).assertNull();
      expect(feed.entries[0].foreignMarkup.map((e: Element) => e.getName()).join()).assertEqual('b');
      expect(feed.entries[0].contents.length).assertEqual(0);
    });

  });
}

