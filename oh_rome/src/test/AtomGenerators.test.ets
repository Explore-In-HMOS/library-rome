import { describe, expect, it } from '@ohos/hypium';
import { Element, Namespace } from '../main/ets/xml/Dom';
import { Format } from '../main/ets/xml/Format';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { DCModule } from '../main/ets/feed/module/DCModule';
import { Category } from '../main/ets/feed/atom/Category';
import { Content } from '../main/ets/feed/atom/Content';
import { Entry } from '../main/ets/feed/atom/Entry';
import { Feed } from '../main/ets/feed/atom/Feed';
import { Generator } from '../main/ets/feed/atom/Generator';
import { Link } from '../main/ets/feed/atom/Link';
import { Person } from '../main/ets/feed/atom/Person';
import { WireFeed } from '../main/ets/feed/WireFeed';
import { WireFeedGenerator } from '../main/ets/io/WireFeedGenerator';
import { Atom03Generator } from '../main/ets/io/impl/Atom03Generator';
import { Atom10Generator } from '../main/ets/io/impl/Atom10Generator';
import { PluginRegistry, usePluginRegistry } from '../main/ets/io/impl/PluginRegistry';
import { registerCorePlugins } from '../main/ets/io/impl/DefaultPlugins';
import { assertGolden } from './golden/Golden';

const ATOM_FIXTURES: string[] = ['rome/atom_0.3.xml', 'rome/atom_0.3_DC_Sy.xml', 'rome/atom_1.0.xml', 'rome/atom_1.0_b.xml',
  'rome/atom_1.0_bray.xml', 'rome/atom_1.0_prefix.xml', 'rome/atom_1.0_ruby.xml'];

// The Atom module fixtures whose full/wire golden passes (see AtomParsers.test.ets).
const MODULE_ATOM_FIXTURES: string[] = [
  'modules/base/courses-atombase.xml', 'modules/base/custom-tags-examplebase.xml', 'modules/base/events-atombase.xml',
  'modules/base/housing-atombase.xml', 'modules/base/jobs-atombase.xml', 'modules/base/news-atom.xml',
  'modules/base/personals-atom.xml', 'modules/base/products-atom.xml', 'modules/base/research-atom.xml',
  'modules/base/reviews-atom.xml', 'modules/base/services-atom.xml', 'modules/base/travel-atom.xml',
  'modules/base/vehicles-atom.xml', 'modules/base/wanted-atom.xml', 'modules/xml/courses-atom.xml',
  'modules/xml/custom-tags-example.xml', 'modules/xml/events-atom.xml', 'modules/xml/housing-atom.xml',
  'modules/xml/jobs-atom.xml', 'modules/xml/news-atom.xml', 'modules/xml/personals-atom.xml',
  'modules/xml/products-atom.xml', 'modules/xml/research-atom.xml', 'modules/xml/reviews-atom.xml',
  'modules/xml/services-atom.xml', 'modules/xml/travel-atom.xml', 'modules/xml/vehicles-atom.xml',
  'modules/xml/wanted-atom.xml'
];

// Expected strings below are ROME 6b4a7e8's WireFeedOutput.outputString (Temurin 17.0.17+10) for the feeds the
// functions below build.
const TEST_ATOM_CONTENT_XML = '<?xml version="1.0" encoding="UTF-8"?>\r\n<feed xmlns="http://www.w3.org/2005/Atom">\r\n' +
  '  <title type="application/xml">\r\n    <test xmlns="">Hello Hello</test>\r\n  </title>\r\n</feed>\r\n';

const ATOM_03_XML = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<feed xmlns="http://purl.org/atom/ns#" version="0.3">',
  '  <title type="text/plain" mode="escaped">&lt;b&gt;T&lt;/b&gt;</title>',
  '  <link rel="alternate" type="text/html" href="a" />',
  '  <link rel="self" href="s" />',
  '  <author>',
  '    <name>n1</name>',
  '    <url>u1</url>',
  '    <email>e1</email>',
  '  </author>',
  '  <contributor>',
  '    <name>n2</name>',
  '  </contributor>',
  '  <contributor>',
  '    <name>n1</name>',
  '    <url>u1</url>',
  '    <email>e1</email>',
  '  </contributor>',
  '  <tagline type="text/html" mode="base64">SGVsbG8g4pyT</tagline>',
  '  <id>id0</id>',
  '  <generator url="http://g" version="1">gen</generator>',
  '  <copyright>c</copyright>',
  '  <info type="application/xhtml+xml" mode="xml">',
  '    <div xmlns="http://www.w3.org/1999/xhtml">',
  '      i',
  '      <b>j</b>',
  '    </div>',
  '    &amp;x',
  '  </info>',
  '  <modified>2006-01-02T15:04:05Z</modified>',
  '  <entry>',
  '    <title>et</title>',
  '    <id>eid</id>',
  '    <modified>2006-01-02T15:04:05Z</modified>',
  '    <issued>2006-01-02T15:04:06Z</issued>',
  '    <created>2006-01-02T15:04:07Z</created>',
  '    <summary type="text/plain">s &amp; t</summary>',
  '    <content type="text/html" mode="escaped">&lt;p&gt;1&lt;/p&gt;</content>',
  '    <content mode="xml">',
  '      <x xmlns="">2</x>',
  '    </content>',
  '  </entry>',
  '</feed>'
].join('\r\n') + '\r\n';

const ATOM_10_XML = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<feed xmlns="http://www.w3.org/2005/Atom" xml:base="http://example.org/">',
  '  <title type="text">&lt;T&gt;</title>',
  '  <link rel="alternate" type="text/html" href="a" hreflang="en" title="tt" length="42" />',
  '  <link rel="self" href="s" />',
  '  <category term="t" label="L" scheme="sch" />',
  '  <author>',
  '    <name>n1</name>',
  '    <uri>u1</uri>',
  '    <email>e1</email>',
  '  </author>',
  '  <author>',
  '    <name>n2</name>',
  '  </author>',
  '  <contributor>',
  '    <name>n2</name>',
  '  </contributor>',
  '  <subtitle type="xhtml">',
  '    <div xmlns="http://www.w3.org/1999/xhtml">',
  '      s',
  '      <i>t</i>',
  '    </div>',
  '  </subtitle>',
  '  <id>hid</id>',
  '  <generator uri="http://g" version="2">gen</generator>',
  '  <rights>r</rights>',
  '  <icon>i.png</icon>',
  '  <logo>l.png</logo>',
  '  <updated>2006-01-02T15:04:05Z</updated>',
  '  <entry xml:base="sub/">',
  '    <title type="html">&lt;b&gt;x&lt;/b&gt;</title>',
  '    <category term="t" label="L" scheme="sch" />',
  '    <author>',
  '      <name>n1</name>',
  '      <uri>u1</uri>',
  '      <email>e1</email>',
  '    </author>',
  '    <contributor>',
  '      <name>n1</name>',
  '      <uri>u1</uri>',
  '      <email>e1</email>',
  '    </contributor>',
  '    <contributor>',
  '      <name>n2</name>',
  '    </contributor>',
  '    <id>e1</id>',
  '    <updated>2006-01-02T15:04:05Z</updated>',
  '    <published>2006-01-02T15:04:06Z</published>',
  '    <content type="text/xml">',
  '      <x xmlns="" a="1">y</x>',
  '      z',
  '    </content>',
  '    <summary type="xhtml">',
  '      <p xmlns="http://www.w3.org/1999/xhtml">p</p>',
  '    </summary>',
  '    <source>',
  '      <title>src</title>',
  '      <id>sid</id>',
  '      <updated>2006-01-02T15:04:07Z</updated>',
  '    </source>',
  '    <rights>er</rights>',
  '  </entry>',
  '  <entry>',
  '    <content type="image/png" src="http://img" />',
  '    <summary type="application/atom+xml">',
  '      <q xmlns="">1</q>',
  '    </summary>',
  '  </entry>',
  '</feed>'
].join('\r\n') + '\r\n';

const SERIALIZE_ENTRY_XML = '<entry xmlns="http://www.w3.org/2005/Atom"><title>t</title><id>x</id>' +
  '<updated>2006-01-02T15:04:05Z</updated></entry>';

const MODULES_AND_FOREIGN_03_XML = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<feed xmlns="http://purl.org/atom/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" version="0.3">',
  '  <id>f</id>',
  '  <dc:title>dt</dc:title>',
  '  <x:a xmlns:x="urn:x">1</x:a>',
  '  <entry>',
  '    <id>e</id>',
  '    <x:b xmlns:x="urn:x" />',
  '    <dc:creator>c</dc:creator>',
  '  </entry>',
  '</feed>'
].join('\r\n') + '\r\n';

const MODULES_AND_FOREIGN_10_XML = [
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/">',
  '  <id>f</id>',
  '  <x:a xmlns:x="urn:x">1</x:a>',
  '  <dc:title>dt</dc:title>',
  '  <entry>',
  '    <id>e</id>',
  '    <x:b xmlns:x="urn:x" />',
  '    <dc:creator>c</dc:creator>',
  '  </entry>',
  '</feed>'
].join('\r\n') + '\r\n';

const D1 = new Date(1136214245000);
const D2 = new Date(1136214246000);
const D3 = new Date(1136214247000);

function content(type: string | null, mode: string | null, value: string | null): Content {
  const c = new Content();
  if (type !== null) {
    c.type = type;
  }
  if (mode !== null) {
    c.mode = mode;
  }
  c.value = value;
  return c;
}

function person(name: string, uri: string | null, email: string | null): Person {
  const p = new Person();
  p.name = name;
  p.uri = uri;
  p.email = email;
  return p;
}

function link(rel: string | null, href: string, type: string | null): Link {
  const l = new Link();
  if (rel !== null) {
    l.rel = rel;
  }
  l.href = href;
  l.type = type;
  return l;
}

function generator(version: string): Generator {
  const g = new Generator();
  g.url = 'http://g';
  g.version = version;
  g.value = 'gen';
  return g;
}

function output(feed: WireFeed, generator: WireFeedGenerator): string {
  return new XMLOutputter(Format.getPrettyFormat()).outputString(generator.generate(feed));
}

function generationError(feed: WireFeed, generator: WireFeedGenerator): string {
  try {
    generator.generate(feed);
  } catch (e) {
    return `${(e as Error).name}: ${(e as Error).message}`;
  }
  return 'no error';
}

function atom03Feed(): Feed {
  const f = new Feed('atom_0.3');
  f.titleEx = content('text/plain', 'escaped', '<b>T</b>');
  f.tagline = content('text/html', 'base64', 'Hello ✓');
  f.info = content('application/xhtml+xml', 'xml', '<div xmlns="http://www.w3.org/1999/xhtml">i<b>j</b></div>&amp;x');
  f.alternateLinks = [link(null, 'a', 'text/html')];
  const self = link('self', 's', null);
  self.hreflang = 'en';
  self.length = 5;
  f.otherLinks = [self];
  const p1 = person('n1', 'u1', 'e1');
  const p2 = person('n2', null, null);
  f.authors = [p1, p2];
  f.contributors = [p2, p1];
  f.id = 'id0';
  f.copyright = 'c';
  f.modified = D1;
  f.generator = generator('1');
  const e = new Entry();
  e.titleEx = content(null, null, 'et');
  e.modified = D1;
  e.issued = D2;
  e.created = D3;
  e.id = 'eid';
  e.summary = content('text/plain', null, 's & t');
  e.contents = [content('text/html', 'escaped', '<p>1</p>'), content(null, 'xml', '<x>2</x>')];
  f.entries = [e];
  return f;
}

function atom10Feed(): Feed {
  const h = new Feed('atom_1.0');
  h.xmlBase = 'http://example.org/';
  h.titleEx = content('text/plain', null, '<T>');
  h.subtitle = content('application/xhtml+xml', null, '<div xmlns="http://www.w3.org/1999/xhtml">s<i>t</i></div>');
  const m1 = link(null, 'a', 'text/html');
  m1.hreflang = 'en';
  m1.title = 'tt';
  m1.length = 42;
  h.alternateLinks = [m1];
  h.otherLinks = [link('self', 's', null)];
  const k1 = new Category();
  k1.term = 't';
  k1.label = 'L';
  k1.scheme = 'sch';
  h.categories = [k1];
  const p1 = person('n1', 'u1', 'e1');
  const p2 = person('n2', null, null);
  h.authors = [p1, p2];
  h.contributors = [p2];
  h.id = 'hid';
  h.rights = 'r';
  h.icon = 'i.png';
  h.logo = 'l.png';
  h.updated = D1;
  h.generator = generator('2');

  const e1 = new Entry();
  e1.xmlBase = 'sub/';
  e1.titleEx = content('text/html', null, '<b>x</b>');
  e1.categories = [k1];
  e1.authors = [p1];
  e1.contributors = [p1, p2];
  e1.id = 'e1';
  e1.updated = D1;
  e1.published = D2;
  e1.rights = 'er';
  e1.contents = [content('text/xml', null, '<x a="1">y</x> z'), content('text', null, 'ignored')];
  e1.summary = content('xhtml', null, '<p xmlns="http://www.w3.org/1999/xhtml">p</p>');
  const source = new Feed();
  source.titleEx = content(null, null, 'src');
  source.id = 'sid';
  source.updated = D3;
  e1.source = source;

  const e2 = new Entry();
  const src = content('image/png', null, null);
  src.src = 'http://img';
  e2.contents = [src];
  e2.summary = content('application/atom+xml', null, '<q>1</q>');
  h.entries = [e1, e2];
  return h;
}

// Feed and entry with both a DC module and foreign markup: the two generators emit them in different orders.
function modulesAndForeignFeed(type: string): Feed {
  const x = Namespace.getNamespace('x', 'urn:x');
  const f = new Feed(type);
  f.id = 'f';
  const dc = new DCModule();
  dc.title = 'dt';
  f.modules = [dc];
  const a = new Element('a', x);
  a.setText('1');
  f.foreignMarkup = [a];
  const e = new Entry();
  e.id = 'e';
  const dc2 = new DCModule();
  dc2.creator = 'c';
  e.modules = [dc2];
  e.foreignMarkup = [new Element('b', x)];
  f.entries = [e];
  return f;
}

export default function atomGeneratorsTest() {
  describe('AtomGenerators', () => {
    it('coreRoundtripXmlGoldens', 0, () => {
      for (const id of ATOM_FIXTURES) {
        assertGolden(id, 'core', 'roundtrip.xml');
      }
    });

    it('coreRoundtripGoldens', 0, () => {
      for (const id of ATOM_FIXTURES) {
        assertGolden(id, 'core', 'roundtrip');
      }
    });

    it('fullRoundtripXmlGoldens', 0, () => {
      for (const id of ATOM_FIXTURES.concat(MODULE_ATOM_FIXTURES)) {
        assertGolden(id, 'full', 'roundtrip.xml');
      }
    });

    it('fullRoundtripGoldens', 0, () => {
      for (const id of ATOM_FIXTURES.concat(MODULE_ATOM_FIXTURES)) {
        assertGolden(id, 'full', 'roundtrip');
      }
    });

    it('registeredInPropertiesOrder', 0, () => {
      const registry = new PluginRegistry();
      registerCorePlugins(registry);
      expect(registry.getFeedGeneratorTypes().slice(-2).join()).assertEqual('atom_1.0,atom_0.3');
    });

    // TestAtomContent.testXML: ROME writes the content of an XML-typed title as elements.
    it('testAtomContentXml', 0, () => {
      const feed = new Feed('atom_1.0');
      feed.titleEx = content('application/xml', null, '<test>Hello Hello</test>');
      const xml = output(feed, new Atom10Generator());
      expect(xml.includes('<test xmlns="">Hello Hello</test>')).assertTrue();
      expect(xml).assertEqual(TEST_ATOM_CONTENT_XML);
    });

    it('atom03ElementOrderAndContentModes', 0, () => {
      expect(output(atom03Feed(), new Atom03Generator())).assertEqual(ATOM_03_XML);
    });

    it('atom10ElementOrderAndContentTypes', 0, () => {
      expect(output(atom10Feed(), new Atom10Generator())).assertEqual(ATOM_10_XML);
    });

    it('modulesAndForeignMarkupOrder', 0, () => {
      const registry = new PluginRegistry();
      registerCorePlugins(registry);
      usePluginRegistry(registry);
      try {
        expect(output(modulesAndForeignFeed('atom_0.3'), new Atom03Generator())).assertEqual(MODULES_AND_FOREIGN_03_XML);
        expect(output(modulesAndForeignFeed('atom_1.0'), new Atom10Generator())).assertEqual(MODULES_AND_FOREIGN_10_XML);
      } finally {
        usePluginRegistry(null);
      }
    });

    it('invalidXmlContentThrowsFeedException', 0, () => {
      const f03 = new Feed('atom_0.3');
      f03.titleEx = content(null, 'xml', '<a>');
      expect(generationError(f03, new Atom03Generator())).assertEqual('FeedException: Invalid XML');
      const f10 = new Feed('atom_1.0');
      f10.titleEx = content('xhtml', null, '<div>');
      expect(generationError(f10, new Atom10Generator())).assertEqual('FeedException: Invalid XML');
    });

    it('serializeEntry', 0, () => {
      const registry = new PluginRegistry();
      registerCorePlugins(registry);
      usePluginRegistry(registry);
      try {
        const entry = new Entry();
        entry.titleEx = content(null, null, 't');
        entry.id = 'x';
        entry.updated = D1;
        expect(Atom10Generator.serializeEntry(entry)).assertEqual(SERIALIZE_ENTRY_XML);
      } finally {
        usePluginRegistry(null);
      }
    });
  });
}
