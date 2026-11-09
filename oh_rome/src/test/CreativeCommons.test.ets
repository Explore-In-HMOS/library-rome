// Ported from ROME rome-modules/src/test/java/com/rometools/modules/cc/{types/LicenseTest,io/CCModuleGeneratorTest}.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Element, Namespace } from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { fixXml } from '../main/ets/io/impl/XmlFixerReader';
import { Channel } from '../main/ets/feed/rss/Channel';
import { RSS20Parser } from '../main/ets/io/impl/RSS20Parser';
import { CreativeCommons } from '../main/ets/modules/cc/CreativeCommons';
import { CCModuleGenerator } from '../main/ets/modules/cc/io/CCModuleGenerator';
import { ModuleParserRSS2 } from '../main/ets/modules/cc/io/ModuleParserRSS2';
import { License, LicenseBehaviour } from '../main/ets/modules/cc/types/License';
import { JavaConcurrentHashMap } from '../main/ets/utils/JavaConcurrentHashMap';
import { assertGolden, fixture } from './golden/Golden';

function testLicense(): License {
  return new License('http://example.org/l', [LicenseBehaviour.ATTRIBUTION],
    [LicenseBehaviour.REPRODUCTION, LicenseBehaviour.DISTRIBUTION]);
}

// The cc module parse of every item of an RSS 2.0 feed whose n items all carry the same license.
function licenseParseMillis(n: number): number {
  const license = License.SHARE_ALIKE_NONCOMMERCIAL_ATTRIBUTION.value;
  const items = `<item><title>i</title><cc:license>${license}</cc:license></item>`.repeat(n);
  const channel = parseXml(`<rss version="2.0" xmlns:cc="${CreativeCommons.RSS2_URI}"><channel>${items}` +
    '</channel></rss>').getRootElement().getChild('channel')!;
  const parser = new ModuleParserRSS2();
  const start = Date.now();
  channel.getChildren('item').forEach((item: Element) => {
    parser.parse(item);
  });
  return Date.now() - start;
}

export default function creativeCommonsTest() {
  describe('CreativeCommons', () => {
    // License.findByValue depends on every license looked up before: AllFixtures.test.ets, first in the bundle, ran
    // these in tools/golden's order. rss1sample.xml registers example1 and example2.
    it('fullGoldensInGoldenOrder', 0, () => {
      for (const id of ['modules/xml/rss1sample.xml', 'modules/xml/rssCreativeCommonsExample.xml']) {
        for (const kind of ['wire', 'roundtrip.xml', 'roundtrip', 'synd', 'convert.atom_1.0', 'convert.rss_2.0']) {
          assertGolden(id, 'full', kind);
        }
      }
    });

    // Matched in ROME's ConcurrentHashMap order: "by" before "by-nc", "by-nd" before "by".
    it('unknownLicenseTakesFirstMatchingBehaviours', 0, () => {
      const byNc = License.findByValue('http://www.creativecommons.org/licenses/by-nc/1.0');
      expect(byNc.requires!.join()).assertEqual(LicenseBehaviour.ATTRIBUTION);
      const byNd = License.findByValue('http://www.creativecommons.org/licenses/by-nd/1.0');
      expect(byNd.permits!.join()).assertEqual([LicenseBehaviour.DISTRIBUTION, LicenseBehaviour.REPRODUCTION].join());
      expect(License.findByValue('http://creativecommons.org/licenses/by/2.5')).assertEqual(License.ATTRIBUTION);
      expect(License.findByValue('http://example.org/other').permits).assertNull();
    });

    // ROME writes the feed with SyndFeedOutput as rss_2.0 (needs A5, A6); this runs the module generator on the parsed
    // channel module and on an RSS 1.0 tree. Expected strings are ROME 6b4a7e8's on Temurin 17.0.17+10.
    it('CCModuleGeneratorTest.testGenerate', 0, () => {
      const feed = new RSS20Parser().parse(parseXml(fixXml(fixture('modules/xml/rssCreativeCommonsExample.xml').xml)));
      const module = (feed as Channel).getModule(CreativeCommons.URI)!;
      const rss = new Element('rss');
      const channel = new Element('channel');
      rss.addContent(channel);
      new CCModuleGenerator().generate(module, channel);
      expect(new XMLOutputter().outputString(rss)).assertEqual('<rss><channel><creativeCommons:license ' +
        'xmlns:creativeCommons="http://backend.userland.com/creativeCommonsRssModule">' +
        'http://www.creativecommons.org/licenses/by-nd/1.0</creativeCommons:license></channel></rss>');
    });

    it('generatesRss1LicensesWithRequiresRepeatingPermits', 0, () => {
      const m = new CreativeCommons();
      const l = testLicense();
      m.allLicenses = [l];
      m.licenses = [l, License.ATTRIBUTION];
      const rdf = new Element('RDF', Namespace.getNamespace('rdf', CreativeCommons.RDF_URI));
      const channel = new Element('channel', Namespace.getNamespace('http://purl.org/rss/1.0/'));
      rdf.addContent(channel);
      new CCModuleGenerator().generate(m, channel);
      const cc = 'xmlns:cc="http://web.resource.org/cc/"';
      expect(new XMLOutputter().outputString(rdf)).assertEqual(
        '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><channel xmlns="http://purl.org/rss/1.0/">' +
          `<cc:license ${cc} rdf:resource="http://example.org/l" /><cc:license ${cc} ` +
          'rdf:resource="http://creativecommons.org/licenses/by/2.5/" /></channel>' +
          `<cc:License ${cc} rdf:about="http://example.org/l">` +
          '<cc:permits rdf:resource="http://web.resource.org/cc/Reproduction" />' +
          '<cc:permits rdf:resource="http://web.resource.org/cc/Distribution" />' +
          '<cc:requires rdf:resource="http://web.resource.org/cc/Reproduction" />' +
          '<cc:requires rdf:resource="http://web.resource.org/cc/Distribution" /></cc:License></rdf:RDF>');
    });

    it('cloneCopiesAllLicensesArraySharesLicenses', 0, () => {
      const m = new CreativeCommons();
      m.allLicenses = [License.ATTRIBUTION];
      m.licenses = [License.SHARE_ALIKE];
      const copy = m.clone();
      expect(copy.allLicenses === m.allLicenses).assertFalse();
      expect(copy.allLicenses![0]).assertEqual(License.ATTRIBUTION);
      expect(copy.licenses === m.licenses).assertTrue();
    });

    // Iteration order of a JDK 17 ConcurrentHashMap after 9 colliding keys (presize) and 40 more (resizes), and after
    // clear, printed by Temurin 17.0.17+10.
    it('concurrentHashMapIterationOrder', 0, () => {
      const m = new JavaConcurrentHashMap<number>();
      const parts = ['Aa', 'BB'];
      let c = 0;
      for (let i = 0; i < 9; i++) {
        let s = '';
        for (let b = 3; b >= 0; b--) {
          s += parts[(i >> b) & 1];
        }
        m.put(s, c++);
      }
      for (let i = 0; i < 40; i++) {
        m.put('k' + i, c++);
      }
      m.put('k5', 99);
      expect(m.keys().join()).assertEqual('k31,k30,k33,k32,k35,k34,k37,k36,k39,k38,k0,k1,k2,k3,k4,k5,k6,k7,k8,k9,' +
        'AaAaAaAa,AaAaAaBB,AaAaBBAa,AaAaBBBB,AaBBAaAa,AaBBAaBB,AaBBBBAa,AaBBBBBB,BBAaAaAa,k11,k10,k13,k12,k15,k14,k17,' +
        'k16,k19,k18,k20,k22,k21,k24,k23,k26,k25,k28,k27,k29');
      expect(m.get('k5')).assertEqual(99);
      const m2 = new JavaConcurrentHashMap<number>();
      for (let i = 0; i < 30; i++) {
        m2.put('http://x/' + i, i);
      }
      m2.clear();
      for (let i = 0; i < 5; i++) {
        m2.put('y' + i, i);
      }
      expect(m2.keys().join()).assertEqual('y0,y1,y2,y3,y4');
    });

    // Every item has the same, already registered, license, so the registry is left as it was. ROME rescans all items
    // for each item: 8x the items cost 64x (measured 75-78x). Copying the list per item made it cubic, 512x (measured
    // 293-441x). The bound, about n^2.4, sits 2x from both, with and without coverage.
    it('repeatedLicenseParseIsQuadratic', 0, () => {
      const small = Math.min(licenseParseMillis(100), licenseParseMillis(100), licenseParseMillis(100));
      const large = licenseParseMillis(800);
      expect(large < small * 150 ? '' : `800 items: ${large} ms, 100 items: ${small} ms`).assertEqual('');
    });

    // ROME races two threads; ArkTS runs the same lookups in turn. Clears the registry, so it runs last.
    it('LicenseTest.testConcurrent', 0, () => {
      License.clear();
      let problems = 0;
      for (let type = 1; type <= 300; type++) {
        if (License.findByValue(`http://creativecommons.org/licenses/${type}/1`) === null) {
          problems++;
        }
        if (License.findByValue(`http://creativecommons.org/licenses/${Math.floor(Math.random() * type)}/1`) === null) {
          problems++;
        }
      }
      expect(problems).assertEqual(0);
    });
  });
}
