import { describe, it, expect } from '@ohos/hypium';
import { CDATA, Comment, Element, Namespace, ProcessingInstruction, Text } from '../main/ets/xml/Dom';
import { SyndCategory } from '../main/ets/feed/synd/SyndCategory';
import { SyndContent } from '../main/ets/feed/synd/SyndContent';
import { SyndEnclosure } from '../main/ets/feed/synd/SyndEnclosure';
import { SyndEntry } from '../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { SyndImage } from '../main/ets/feed/synd/SyndImage';
import { SyndLink } from '../main/ets/feed/synd/SyndLink';
import { SyndPerson } from '../main/ets/feed/synd/SyndPerson';
import { DCModule } from '../main/ets/feed/module/DCModule';
import { ModuleParser } from '../main/ets/io/ModuleParser';
import { compareJson, GoldenDiff } from './golden/Compare';
import { assertGolden, fixture, fixtureIds, profileRegistry, runGolden, runGoldenOn, serialize } from './golden/Golden';
import { FIXTURES } from './golden/Fixtures';
import { GoldenFixture } from './golden/GoldenFixture';
import { JsonKind, JsonNode } from './golden/Json';
import { SELF_TEST_SYND_FEED } from './golden/SelfTestGoldens';

// Same object as tools/golden/src/main/java/romeharmony/golden/SelfTest.java builds with ROME.
function selfTestFeed(): SyndFeed {
  const feed = new SyndFeed();
  feed.feedType = 'rss_2.0';
  feed.title = 'Feed & title';
  feed.description = 'Feed description';
  feed.link = 'http://example.com/';
  feed.uri = 'urn:feed';
  feed.publishedDate = new Date(1700000000123);
  feed.language = 'tr';
  feed.author = 'Feed author';
  feed.copyright = '(c) 2026';
  const feedCategory = new SyndCategory();
  feedCategory.name = 'news';
  feedCategory.taxonomyUri = 'urn:tax';
  feed.categories = [feedCategory];
  const image = new SyndImage();
  image.title = 'Logo';
  image.url = 'http://example.com/logo.png';
  image.width = 88;
  feed.image = image;

  const entry = new SyndEntry();
  entry.title = 'Entry title';
  entry.link = 'http://example.com/1';
  entry.uri = 'urn:entry:1';
  entry.publishedDate = new Date(1700000001000);
  entry.updatedDate = new Date(1700000002000);
  const description = new SyndContent();
  description.type = 'text/html';
  description.value = '<b>bold</b>';
  entry.description = description;
  const content = new SyndContent();
  content.type = 'text/plain';
  content.value = 'Body';
  entry.contents = [content];
  const enclosure = new SyndEnclosure();
  enclosure.url = 'http://example.com/a.mp3';
  enclosure.type = 'audio/mpeg';
  enclosure.length = 12345;
  entry.enclosures = [enclosure];
  const person = new SyndPerson();
  person.name = 'Ada';
  person.email = 'ada@example.com';
  entry.authors = [person];
  const link = new SyndLink();
  link.href = 'http://example.com/alt';
  link.rel = 'alternate';
  link.length = 7;
  entry.links = [link];
  const entryCategory = new SyndCategory();
  entryCategory.name = 'tech';
  entry.categories = [entryCategory];
  const markup = new Element('extra', Namespace.getNamespace('x', 'urn:x'));
  markup.setAttribute('a', '1 < 2');
  markup.setText('text & more');
  entry.foreignMarkup = [markup];
  feed.entries = [entry];
  return feed;
}

function diffOf(expected: string, actual: string): string[] {
  const diff = new GoldenDiff();
  compareJson(JsonNode.parse(expected), JsonNode.parse(actual), '', diff);
  return diff.lines;
}

class Rates {
  bitrate: number = NaN;
  framerate: number = Infinity;
  samplingrate: number = -Infinity;
  duration: number = 1.5;
}

export default function goldenHarnessTest() {
  describe('GoldenHarness', () => {
    it('jsonParserReadsTheGoldenFormat', 0, () => {
      const node = JsonNode.parse('{"a":[1,-2.5e1,true,null,"x\\"\\\\\\n\\u00e9\\ud83d\\ude00"],"b":{}}');
      expect(node.get('a')!.items.length).assertEqual(5);
      expect(node.get('a')!.items[1].num).assertEqual(-25);
      expect(node.get('a')!.items[3].kind).assertEqual(JsonKind.NULL);
      expect(node.get('a')!.items[4].str).assertEqual('x"\\\né😀');
      expect(node.get('b')!.fields.size).assertEqual(0);
      let threw = false;
      try {
        JsonNode.parse('{"a":1} x');
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    it('comparatorAcceptsEqualTrees', 0, () => {
      expect(diffOf('{"a":1.0,"b":["x",null],"c":{"d":false}}', '{"c":{"d":false},"b":["x",null],"a":1}').length)
        .assertEqual(0);
    });

    it('comparatorReportsEveryKindOfDifference', 0, () => {
      expect(diffOf('{"a":"x"}', '{"a":"y"}')[0]).assertContain('$.a: strings differ at 0');
      expect(diffOf('{"a":1}', '{"a":2}')[0]).assertEqual('$.a: expected 1 but was 2');
      expect(diffOf('{"a":1,"b":2}', '{"a":1}')[0]).assertEqual('$.b: missing, expected 2');
      expect(diffOf('{"a":1}', '{"a":1,"z":3}')[0]).assertEqual('$.z: not a ROME property (value 3)');
      expect(diffOf('{"a":[1,2]}', '{"a":[1]}')[0]).assertContain('$.a: expected 2 items but was 1');
      expect(diffOf('{"a":[{"b":null}]}', '{"a":[{"b":"x"}]}')[0]).assertEqual('$.a[0].b: expected null but was "x"');
      expect(diffOf('{"a":"x"}', '{"a":null}')[0]).assertEqual('$.a: expected "x" but was null');
    });

    it('comparatorKnownRepresentationGaps', 0, () => {
      expect(diffOf('{"titles":[null]}', '{"titles":[]}').length).assertEqual(0);
      expect(diffOf('{"titles":[null]}', '{"titles":["t"]}').length).assertEqual(1);
      expect(diffOf('{"tags":{"$set":["a","b"]}}', '{"tags":["b","a"]}').length).assertEqual(0);
      expect(diffOf('{"tags":{"$set":["a","b"]}}', '{"tags":["a","c"]}').length).assertEqual(1);
      expect(diffOf('{"modules":[]}', '{"moduleList":[],"wireFeed":null,"preserveWireFeed":false}').length).assertEqual(0);
      expect(diffOf('{"updatePeriod":"daily"}', '{"_updatePeriod":"daily"}').length).assertEqual(0);
      expect(diffOf('{"href":"a","hrefResolved":"a"}', '{"href":"a","_hrefResolved":null}').length).assertEqual(0);
      expect(diffOf('{"href":"a","hrefResolved":"b"}', '{"href":"a","_hrefResolved":null}').length).assertEqual(1);
      expect(diffOf('{"href":"a","hrefResolved":"b"}', '{"href":"a","_hrefResolved":"b"}').length).assertEqual(0);
      expect(diffOf('["node.#1","node.#2","node.#1"]', '["node.7","node.-3","node.7"]').length).assertEqual(0);
      expect(diffOf('["node.#1","node.#2","node.#1"]', '["node.7","node.7","node.7"]').length).assertEqual(1);
      expect(diffOf('["node.#1","node.#2","node.#1"]', '["node.7","node.3","node.4"]').length).assertEqual(1);
      expect(diffOf('["node.#1","parent.#1","node.#2"]', '["node.7","parent.7","node.3"]').length).assertEqual(0);
      expect(diffOf('["node.#1","parent.#1","node.#2"]', '["node.7","parent.3","node.3"]').length).assertEqual(1);
      expect(diffOf('["node.#1"]', '["parent.7"]').length).assertEqual(1);
    });

    it('selfTestFeedMatchesRome', 0, () => {
      const diff = new GoldenDiff();
      compareJson(JsonNode.parse(SELF_TEST_SYND_FEED), serialize(selfTestFeed()), '', diff);
      expect(diff.lines.join('\n')).assertEqual('');
    });

    it('selfTestFeedDifferenceIsCaught', 0, () => {
      const feed = selfTestFeed();
      feed.entries[0].enclosures[0].length = 12346;
      (feed.getModule(DCModule.URI) as DCModule).language = 'en';
      const diff = new GoldenDiff();
      compareJson(JsonNode.parse(SELF_TEST_SYND_FEED), serialize(feed), '', diff);
      expect(diff.lines.join('\n')).assertContain('$.entries[0].enclosures[0].length: expected 12345 but was 12346');
      expect(diff.lines.join('\n')).assertContain('$.modules[0].languages[0]');
    });

    // ROME 6b4a7e8 on Temurin 17.0.17+10: new SyndFeedImpl() with an entry, read through getters, has a DC module on
    // both.
    it('syndModulesGetTheirDcModuleAsInRome', 0, () => {
      const feed = new SyndFeed();
      feed.entries = [new SyndEntry()];
      const json = serialize(feed);
      expect(json.get('moduleList')!.items.length).assertEqual(1);
      expect(json.get('moduleList')!.items[0].get('uri')!.str).assertEqual(DCModule.URI);
      expect(json.get('entries')!.items[0].get('moduleList')!.items.length).assertEqual(1);
    });

    // BeanJson.value writes a NaN or infinite Float/Double as String.valueOf (a JSON string), finite ones as numbers.
    it('nonFiniteNumbersSerializeAsJavaStrings', 0, () => {
      const diff = new GoldenDiff();
      compareJson(JsonNode.parse('{"bitrate":"NaN","framerate":"Infinity","samplingrate":"-Infinity","duration":1.5}'),
        serialize(new Rates()), '', diff);
      expect(diff.lines.join('\n')).assertEqual('');
    });

    it('elementsSerializeAsRawXml', 0, () => {
      const e = new Element('a');
      e.setText('<&>');
      expect(serialize([e]).items[0].str).assertEqual('<a>&lt;&amp;&gt;</a>');
    });

    // BeanJson's XMLOutputter(Format.getRawFormat()).outputString(List.of(content)), JDOM 2.0.6.1 on Temurin 17.0.17+10.
    it('otherContentSerializesAsRawXml', 0, () => {
      const items = serialize([new Text('\r\n  a<&>"\''), new CDATA('x<&>y'), new Comment(' c '),
        new ProcessingInstruction('t', 'd')]).items;
      expect(JSON.stringify(items.map((n: JsonNode) => n.str)))
        .assertEqual(JSON.stringify(['&#xD;\r\n  a&lt;&amp;&gt;"\'', '<![CDATA[x<&>y]]>', '<!-- c -->', '<?t d?>']));
    });

    // ROME 6b4a7e8 WireFeedInput.build on this input throws org.jdom2.IllegalNameException unwrapped.
    it('jdomIllegalArgumentExceptionPassesThrough', 0, () => {
      const f = new GoldenFixture('test/illegal-name', '<rss xmlns:p="2005" version="2.0"><channel/></rss>',
        ['core/wire'], [0], ['{"$exception":"IllegalNameException"}']);
      expect(runGoldenOn(f, 'core', 'wire').lines.join('\n')).assertEqual('');
    });

    it('missingGoldenFailsLoudly', 0, () => {
      let message = '';
      try {
        fixture('rome/rss_2.0.xml').golden('core', 'no-such-kind');
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertContain('No golden core/no-such-kind for rome/rss_2.0.xml');
      message = '';
      try {
        fixture('rome/no-such-fixture.xml');
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertContain('Unknown golden fixture rome/no-such-fixture.xml');
    });

    it('everyFixtureHasParsableGoldens', 0, () => {
      expect(FIXTURES.length).assertEqual(190);
      expect(fixtureIds('rome/').length).assertEqual(24);
      expect(fixtureIds('opml/').length).assertEqual(3);
      expect(fixtureIds('repo/').length).assertEqual(34);
      let goldens = 0;
      for (const f of FIXTURES) {
        const profiles = f.id.startsWith('rome/') || f.id.startsWith('repo/') ? ['core', 'full'] :
          f.id.startsWith('opml/') ? ['opml'] : ['full'];
        for (const profile of profiles) {
          expect(f.kinds(profile).includes('wire')).assertTrue();
          for (const kind of f.kinds(profile)) {
            f.golden(profile, kind);
            goldens++;
          }
        }
      }
      expect(goldens > 1000).assertTrue();
    });

    it('profilesRegisterOnlyTheirPlugins', 0, () => {
      const uris = (profile: string): string =>
        profileRegistry(profile).getModuleParsers('rss_1.0.feed').map((p: ModuleParser) => p.getNamespaceUri()).join(' ');
      expect(uris('core')).assertEqual('http://purl.org/rss/1.0/modules/syndication/ http://purl.org/dc/elements/1.1/');
      let threw = false;
      try {
        profileRegistry('nope');
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
    });

    // End to end on fixtures whose goldens need no feed parser: XML that ROME rejects.
    it('rejectedFixturesMatchRome', 0, () => {
      assertGolden('modules/2.rss', 'full', 'wire');
      assertGolden('modules/2.rss', 'full', 'wire.default');
      assertGolden('modules/2.rss', 'full', 'synd');
    });

    // Deliberately wrong goldens, so the outcome stays a difference whichever parsers are registered.
    it('wrongOutcomeIsReported', 0, () => {
      const xml = '<rss version="2.0"><channel><title>t</title></channel></rss>';
      const expectsException = new GoldenFixture('test/expects-exception', xml, ['core/wire'], [0],
        ['{"$exception":"FeedException","message":"never thrown"}']);
      expect(runGoldenOn(expectsException, 'core', 'wire').lines.join('\n')).assertContain('expected FeedException');
      const expectsResult = new GoldenFixture('test/expects-result', '<not-a-feed/>', ['core/wire'], [0],
        ['{"feedType":"rss_2.0"}']);
      expect(runGoldenOn(expectsResult, 'core', 'wire').lines.join('\n')).assertContain('threw IllegalArgumentException: Invalid document');
    });
  });
}
