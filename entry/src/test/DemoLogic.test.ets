import { describe, expect, it } from '@ohos/hypium';
import { SyndEntry, SyndFeed } from '@explore-in-hmos/oh_rome';
import { convertTo, generateFeed, outputTypes, readBack } from '../main/ets/logic/Convert';
import { DetailRow, entrySections, entrySummary, feedSections, Section } from '../main/ets/logic/Describe';
import { describeError, ErrorKind } from '../main/ets/logic/Errors';
import { exportOpml, outlineRows, parseOpml, Subscription, subscriptionsOf } from '../main/ets/logic/Opml';
import { PRESETS_OPML } from '../main/ets/logic/Presets';
import { FeedSource, parseSource } from '../main/ets/logic/Source';
import { formatDate, plainText } from '../main/ets/logic/Text';
import { Sample, SAMPLES } from '../main/ets/samples/Samples';

function sample(name: string): FeedSource {
  const found = SAMPLES.find((s: Sample) => s.name === name);
  if (found === undefined) {
    throw new Error(`No sample ${name}`);
  }
  return FeedSource.ofText(name, found.xml);
}

function firstEntry(name: string): SyndEntry {
  return parseSource(sample(name)).entries[0];
}

// "<section>.<label>=<value>" for every row, so a test can check one value without depending on the others.
function flatten(sections: Section[]): string[] {
  const out: string[] = [];
  sections.forEach((s: Section) => {
    s.rows.forEach((r: DetailRow) => {
      out.push(`${s.title}.${r.label}=${r.value}`);
    });
  });
  return out;
}

function goodSamples(): Sample[] {
  return SAMPLES.filter((s: Sample) => s.name !== 'Broken');
}

export default function demoLogicTest() {
  describe('DemoLogic', () => {
    it('presetsAreAnOpmlDocument', 0, () => {
      const opml = parseOpml(PRESETS_OPML);
      expect(opml.feedType).assertEqual('opml_2.0');
      const subscriptions = subscriptionsOf(opml);
      expect(subscriptions.length).assertEqual(9);
      expect(subscriptions.every((s: Subscription) => s.url.startsWith('https://') && s.group !== '')).assertTrue();
      expect(outlineRows(opml).length).assertEqual(12);
    });

    it('everySampleButBrokenParses', 0, () => {
      const types = goodSamples().map((s: Sample) => `${s.name}=${parseSource(sample(s.name)).feedType}`);
      expect(types.join(', ')).assertEqual('RSS 2.0=rss_2.0, RSS 0.91=rss_0.91U, RSS 1.0=rss_1.0, Atom 1.0=atom_1.0, ' +
        'Atom 0.3=atom_0.3, iTunes=rss_2.0, Media + Geo=rss_2.0');
    });

    it('brokenSampleIsAParseErrorWithItsPosition', 0, () => {
      let message = 'nothing thrown';
      try {
        parseSource(sample('Broken'));
      } catch (e) {
        const error = describeError(ErrorKind.PARSE, e as Object);
        message = `${error.title}: ${error.message}`;
      }
      expect(message.startsWith('Parse error: ParsingFeedException: Invalid XML')).assertTrue();
      expect(message.includes('(line 7, column')).assertTrue();
    });

    it('itunesSampleShowsDuration', 0, () => {
      const entry = firstEntry('iTunes');
      expect(flatten(entrySections(entry)).includes('iTunes.Duration=00:42:15')).assertTrue();
      expect(entrySummary(entry)).assertEqual('2026-11-03 06:00 UTC · 00:42:15');
    });

    it('mediaAndGeoSampleShowsBothModules', 0, () => {
      const rows = flatten(entrySections(firstEntry('Media + Geo')));
      expect(rows.includes('Media RSS.First URL=https://example.com/photos/sunrise.jpg')).assertTrue();
      expect(rows.includes('Media RSS.Size=470.8 KB')).assertTrue();
      expect(rows.includes('GeoRSS.Latitude=50.3664')).assertTrue();
      expect(rows.includes('GeoRSS.Longitude=-4.1427')).assertTrue();
    });

    it('rss10SampleShowsDublinCoreAndSlash', 0, () => {
      const rows = flatten(entrySections(firstEntry('RSS 1.0')));
      expect(rows.includes('Slash.Comments=12')).assertTrue();
      expect(rows.includes('Dublin Core.Creator=Harbour Master')).assertTrue();
      expect(flatten(feedSections(parseSource(sample('RSS 1.0')))).includes('Feed.Type=rss_1.0')).assertTrue();
    });

    // Every bundled sample to every output type: each either converts, or fails with ROME's FeedException, never with
    // anything else. Converted output must read back.
    it('everySampleConvertsToEveryTypeOrFailsLikeRome', 0, () => {
      const problems: string[] = [];
      let converted = 0;
      goodSamples().forEach((s: Sample) => {
        outputTypes().forEach((type: string) => {
          const result = convertTo(sample(s.name), type);
          if (result.xml !== null) {
            converted++;
            if (!readBack(result.xml).startsWith('Read back as')) {
              problems.push(`${s.name}->${type}: ${readBack(result.xml)}`);
            }
          } else if (result.error === null || result.error.name !== 'FeedException') {
            problems.push(`${s.name}->${type}: ${result.error?.title ?? 'no error'} ${result.error?.message ?? ''}`);
          }
        });
      });
      expect(problems.join(' ;; ')).assertEqual('');
      expect(converted > 0).assertTrue();
    });

    it('generatesEveryOutputType', 0, () => {
      const problems: string[] = [];
      outputTypes().forEach((type: string) => {
        const result = generateFeed(type, 'Demo', 'First', new Date(Date.UTC(2026, 10, 6, 8, 0, 0)));
        if (result.xml === null) {
          problems.push(`${type}: ${result.error?.title ?? ''} ${result.error?.message ?? ''}`);
        } else if (!readBack(result.xml).includes('"Demo"')) {
          problems.push(`${type}: ${readBack(result.xml)}`);
        }
      });
      expect(problems.join(' ;; ')).assertEqual('');
    });

    it('exportedOpmlReadsBack', 0, () => {
      const subscriptions = subscriptionsOf(parseOpml(PRESETS_OPML));
      const back = parseOpml(exportOpml('Export', subscriptions));
      expect(back.feedType).assertEqual('opml_2.0');
      expect(subscriptionsOf(back).map((s: Subscription) => s.url).join())
        .assertEqual(subscriptions.map((s: Subscription) => s.url).join());
    });

    it('feedSectionsListOnlyWhatTheFeedHas', 0, () => {
      const feed: SyndFeed = parseSource(sample('RSS 2.0'));
      const rows = flatten(feedSections(feed));
      expect(rows.includes('Feed.Title=Harbour News')).assertTrue();
      expect(rows.some((r: string) => r.startsWith('Feed.Copyright='))).assertFalse();
    });

    it('textHelpers', 0, () => {
      expect(plainText('<p>A &amp; B</p>\n  <b>c</b>', 100)).assertEqual('A & B c');
      expect(plainText('abcdef', 4)).assertEqual('abc…');
      expect(formatDate(new Date(Date.UTC(2026, 10, 6, 7, 5, 0)))).assertEqual('2026-11-06 07:05 UTC');
      expect(formatDate(null)).assertEqual('No date');
    });
  });
}
