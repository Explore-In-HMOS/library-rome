// Ported from ROME rome-modules/src/test/java/com/rometools/modules/opensearch/OpenSearchModuleTest.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Element } from '../main/ets/xml/Dom';
import { Format } from '../main/ets/xml/Format';
import { parseXml } from '../main/ets/xml/XmlParser';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { fixXml } from '../main/ets/io/impl/XmlFixerReader';
import { Link } from '../main/ets/feed/atom/Link';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { Atom10Generator } from '../main/ets/io/impl/Atom10Generator';
import { Atom10Parser } from '../main/ets/io/impl/Atom10Parser';
import { OpenSearchModule } from '../main/ets/modules/opensearch/OpenSearchModule';
import { OSQuery } from '../main/ets/modules/opensearch/entity/OSQuery';
import { OpenSearchModuleGenerator } from '../main/ets/modules/opensearch/impl/OpenSearchModuleGenerator';
import { OpenSearchModuleParser } from '../main/ets/modules/opensearch/impl/OpenSearchModuleParser';
import { assertGolden, fixture, serialize } from './golden/Golden';

const NS: string = 'xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"';

function parse(xml: string): OpenSearchModule | null {
  return new OpenSearchModuleParser().parse(parseXml(xml).getRootElement()) as OpenSearchModule | null;
}

function readAtom(xml: string): SyndFeed {
  return new SyndFeed(new Atom10Parser().parse(parseXml(fixXml(xml))));
}

function thrown(action: () => void): string {
  try {
    action();
  } catch (e) {
    return `${(e as Error).name}: ${(e as Error).message}`;
  }
  return 'nothing thrown';
}

export default function openSearchTest() {
  describe('OpenSearch', () => {
    // sample1 is RSS: its synd, convert.* and roundtrip* kinds need A5 and A6. convert.rss_2.0 needs A6 too.
    it('fullGoldens', 0, () => {
      assertGolden('modules/os/sample1.xml', 'full', 'wire');
      for (const kind of ['wire', 'synd', 'roundtrip.xml', 'roundtrip', 'convert.atom_1.0']) {
        assertGolden('modules/os/sample2.xml', 'full', kind);
      }
    });

    // ROME runs every os/ fixture through SyndFeedOutput and back; sample1 (RSS) needs A5 and A6.
    it('OpenSearchModuleTest.testEndToEnd', 0, () => {
      const feed = readAtom(fixture('modules/os/sample2.xml').xml);
      const m = feed.getModule(OpenSearchModule.URI)!;
      const xml = new XMLOutputter(Format.getPrettyFormat()).outputString(new Atom10Generator().generate(feed.createWireFeed()));
      const m2 = readAtom(xml).getModule(OpenSearchModule.URI)!;
      expect(serialize(m2).toJson()).assertEqual(serialize(m).toJson());
      expect((m2 as OpenSearchModule).totalResults).assertEqual(4230000);
    });

    // Expected values below are ROME 6b4a7e8's on Temurin 17.0.17+10.
    it('relativeHrefResolvesEmptyStringAgainstXmlBase', 0, () => {
      expect(parse(`<feed ${NS} xml:base="http://x.com/a/b"><opensearch:totalResults>1</opensearch:totalResults>` +
        '<opensearch:link href="rel"/></feed>')!.link!.href).assertEqual('http://x.com/a/');
      expect(parse(`<channel ${NS}><opensearch:totalResults>1</opensearch:totalResults>` +
        '<opensearch:link xml:base="/foo/" href="rel"/><opensearch:link href="http://example.com:8080/x"/></channel>')!
        .link!.href).assertEqual('http://example.com:8080/foo/');
    });

    it('detachedRootResolvesAgainstNullBase', 0, () => {
      const root = parseXml(`<rss><channel ${NS}><opensearch:totalResults>1</opensearch:totalResults>` +
        '<opensearch:link href="rel"/></channel></rss>').getRootElement().getChildren()[0];
      root.detach();
      expect((new OpenSearchModuleParser().parse(root) as OpenSearchModule).link!.href).assertEqual('null');
    });

    it('badNumbersAreIgnored', 0, () => {
      expect(parse(`<channel ${NS}><opensearch:totalResults> 5</opensearch:totalResults></channel>`)).assertNull();
      const m = parse(`<channel ${NS}><opensearch:totalResults> 5</opensearch:totalResults>` +
        '<opensearch:itemsPerPage>2</opensearch:itemsPerPage><opensearch:Query role="r" totalResults="x" startPage="3"/>' +
        '<opensearch:Query role="s" totalResults="7" startPage="3"/></channel>')!;
      expect(m.totalResults).assertEqual(-1);
      expect(m.queries.map((q: OSQuery) => `${q.role} ${q.totalResults} ${q.startPage}`).join('|'))
        .assertEqual('r -1 -1|s 7 3');
    });

    it('linkWithoutHrefThrows', 0, () => {
      expect(thrown(() => parse(`<channel ${NS}><opensearch:totalResults>1</opensearch:totalResults>` +
        '<opensearch:link rel="search"/></channel>'))).assertContain('TypeError');
    });

    it('generator', 0, () => {
      const noRole = new OpenSearchModule();
      noRole.addQuery(new OSQuery());
      expect(thrown(() => new OpenSearchModuleGenerator().generate(noRole, new Element('channel')))).assertEqual(
        'RequiredAttributeMissingException: If declaring a Query element, the field \'role\' must be be specified');
      const q = new OSQuery();
      q.role = 'request';
      q.startPage = 0;
      const m = new OpenSearchModule();
      m.startIndex = 0;
      m.addQuery(q);
      const link = new Link();
      link.rel = 'self';
      link.href = 'h';
      link.title = 't';
      m.link = link;
      const channel = new Element('channel');
      new OpenSearchModuleGenerator().generate(m, channel);
      const ns = 'xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/"';
      expect(new XMLOutputter().outputString(channel)).assertEqual(
        `<channel><opensearch:startIndex ${ns}>1</opensearch:startIndex><opensearch:Query ${ns} role="request" ` +
          `startPage="1" /><opensearch:link ${ns} rel="search" href="h" /></channel>`);
    });

    it('cloneDeepCopiesCopyFromSharesLink', 0, () => {
      const m = parse(`<channel ${NS}><opensearch:totalResults>1</opensearch:totalResults>` +
        '<opensearch:Query role="r"/><opensearch:link href="http://a/"/></channel>')!;
      const copy = m.clone();
      expect(copy.link === m.link).assertFalse();
      expect(copy.link!.href).assertEqual('http://a/');
      expect(copy.queries[0] === m.queries[0]).assertFalse();
      expect(serialize(copy.queries).toJson()).assertEqual(serialize(m.queries).toJson());
      expect(copy.totalResults).assertEqual(1);
      const target = new OpenSearchModule();
      target.copyFrom(m);
      expect(target.link === m.link).assertTrue();
      expect(target.queries[0] === m.queries[0]).assertFalse();
    });
  });
}
