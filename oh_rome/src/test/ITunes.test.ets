// Ported from ROME rome-modules/src/test/java/com/rometools/modules/itunes/{ITunesParserTest,ITunesGeneratorTest}.java and types/DurationTest.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Element } from '../main/ets/xml/Dom';
import { Format } from '../main/ets/xml/Format';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { parseXml } from '../main/ets/xml/XmlParser';
import { fixXml } from '../main/ets/io/impl/XmlFixerReader';
import { WireFeed } from '../main/ets/feed/WireFeed';
import { Module } from '../main/ets/feed/module/Module';
import { SyndEntry } from '../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { WireFeedParser } from '../main/ets/io/WireFeedParser';
import { plugins } from '../main/ets/io/impl/PluginRegistry';
import { EntryInformation } from '../main/ets/modules/itunes/EntryInformation';
import { FeedInformation } from '../main/ets/modules/itunes/FeedInformation';
import { ITunes } from '../main/ets/modules/itunes/ITunes';
import { ITunesGenerator } from '../main/ets/modules/itunes/io/ITunesGenerator';
import { ITunesParser } from '../main/ets/modules/itunes/io/ITunesParser';
import { Category } from '../main/ets/modules/itunes/types/Category';
import { Duration } from '../main/ets/modules/itunes/types/Duration';
import { assertGolden, fixture, serialize } from './golden/Golden';

const GOLDEN_FIXTURES: string[] = ['modules/com/rometools/modules/itunes/duration.xml',
  'modules/com/rometools/modules/itunes/duration-bad.xml', 'modules/com/rometools/modules/itunes/duration-empty.xml',
  'modules/com/rometools/modules/itunes/explicitness-capital-yes.xml',
  'modules/com/rometools/modules/itunes/explicitness-clean.xml', 'modules/com/rometools/modules/itunes/explicitness-no.xml',
  'modules/com/rometools/modules/itunes/explicitness-yes.xml', 'modules/itunes/leshow.xml',
  'modules/itunes/no-http-uris.xml', 'modules/xml/at.xml', 'modules/xml/leshow.xml', 'modules/xml/lr.xml',
  'modules/xml/rsr.xml'];

// Same as the golden harness's reader for these fixtures (none has a DOCTYPE, all parse).
function readWire(xml: string): WireFeed {
  const document = parseXml(fixXml(xml), false);
  return plugins().getFeedParsers().find((p: WireFeedParser) => p.isMyType(document))!.parse(document);
}

function readSynd(id: string): SyndFeed {
  return new SyndFeed(readWire(fixture(id).xml));
}

function writeSynd(feed: SyndFeed): string {
  const wire = feed.createWireFeed();
  return new XMLOutputter(Format.getPrettyFormat()).outputString(plugins().getFeedGenerator(wire.feedType!)!.generate(wire));
}

function entryInfo(entry: SyndEntry): EntryInformation {
  return entry.getModule(ITunes.URI) as EntryInformation;
}

function feedInfo(feed: SyndFeed): FeedInformation {
  return feed.getModule(ITunes.URI) as FeedInformation;
}

function json(module: Module): string {
  return serialize(module).toJson();
}

function parseItem(itunesXml: string): EntryInformation {
  const item = parseXml(`<item xmlns:itunes="${ITunes.URI}">${itunesXml}</item>`).getRootElement();
  return new ITunesParser().parse(item) as EntryInformation;
}

function imageFeed(): SyndFeed {
  const feed = new SyndFeed();
  feed.feedType = 'rss_2.0';
  feed.title = 'title';
  feed.description = 'description';
  feed.link = 'https://example.org';
  return feed;
}

export default function itunesTest() {
  describe('DurationTest', () => {
    it('testToString', 0, () => {
      expect(new Duration(2 * Duration.HOUR + 3 * Duration.MINUTE + 20 * Duration.SECOND).toString()).assertEqual('02:03:20');
      expect(new Duration(12000 * Duration.HOUR + 61 * Duration.MINUTE + 61 * Duration.SECOND).toString())
        .assertEqual('12001:02:01');
    });

    it('testGetMilliseconds', 0, () => {
      expect(Duration.parse('1:20:01').milliseconds).assertEqual(Duration.HOUR + Duration.MINUTE * 20 + Duration.SECOND);
      expect(Duration.parse('1:02').milliseconds).assertEqual(Duration.MINUTE + Duration.SECOND * 2);
    });

    // Expected values from ROME 6b4a7e8 on Temurin 17.0.17+10, en_US.
    it('parseMatchesRome', 0, () => {
      const cases: string[][] = [['1', '1000'], ['61', '61000'], ['1.5', '1500'], ['0.0005', '0'], ['0.0015', '1'],
        ['::5', '5000'], ['5::', '5000'], ['a:b:c', '0'], ['-1:30', '-30000'], ['1:-30', '30000'], ['1e3', '1000000'],
        ['2.5:30', '30000'], [' 1 : 2 ', '62000'], ['1:2.9999999', '63000'], ['3600000000:0:0', '12960000000000000'],
        ['1e30', '9223372036854775807'], ['-1e30', '-9223372036854775808'], ['NaN', '0'], ['0x10', '0'],
        ['99999999999999999999:0', '0'], ['16777217', '16777216000'], ['0.1', '100'], ['12:34:56.789', '45296789']];
      cases.forEach((c: string[]) => {
        expect(`${c[0]} -> ${Duration.parse(c[0]).milliseconds}`).assertEqual(`${c[0]} -> ${Number(c[1])}`);
      });
      ['', ':', '1:2:3:4'].forEach((s: string) => {
        let message = '';
        try {
          Duration.parse(s);
        } catch (e) {
          message = (e as Error).message;
        }
        expect(message).assertEqual(`Illegal time value: ${s}`);
      });
      expect(Duration.of(1, 2, 3.5).milliseconds).assertEqual(3723500);
      expect(Duration.of(0, 0, 0.1).milliseconds).assertEqual(100);
    });

    it('toStringMatchesRome', 0, () => {
      const cases: string[][] = [['0', '00:00:00'], ['499', '00:00:00'], ['500', '00:00:01'], ['1499', '00:00:01'],
        ['1500', '00:00:02'], ['59499', '00:00:59'], ['59500', '00:00:60'], ['3599500', '00:59:60'], ['-1', '00:00:00'],
        ['-500', '00:00:00'], ['-501', '00:00:-01'], ['-1500', '00:00:-01'], ['-61000', '00:-01:-01'],
        ['-3600000', '-01:00:00'], ['7261000', '02:01:01'], ['43204861000', '12001:21:01'],
        ['7730941132800000', '-2147483648:00:2147483647'], ['9007199254740991', '-1792967504:59:2147483647'],
        ['16777217000', '4660:20:17'], ['123456789', '34:17:37']];
      cases.forEach((c: string[]) => {
        expect(`${c[0]} -> ${new Duration(Number(c[0])).toString()}`).assertEqual(`${c[0]} -> ${c[1]}`);
      });
    });
  });

  describe('ITunesParserTest', () => {
    it('testGetNamespaceUri', 0, () => {
      expect(new ITunesGenerator().getNamespaceUri()).assertEqual('http://www.itunes.com/dtds/podcast-1.0.dtd');
    });

    it('testParse', 0, () => {
      let syndfeed = readSynd('modules/itunes/leshow.xml');
      const info = feedInfo(syndfeed);
      expect(info.block).assertTrue();
      expect(info.ownerName).assertEqual('Harry Shearer');
      expect(info.ownerEmailAddress).assertEqual('');
      expect(info.image).assertEqual('http://a1.phobos.apple.com/Music/y2005/m06/d26/h21/mcdrrifv.jpg');
      expect(info.categories[0].name).assertEqual('Comedy');
      expect(info.categories[1].name).assertEqual('Arts & Entertainment');
      expect(info.categories[1].subcategories[0].name).assertEqual('Entertainment');
      expect(info.summary).assertEqual('A weekly, hour-long romp through the worlds of media, politics, sports and ' +
        'show business, leavened with an eclectic mix of mysterious music, hosted by Harry Shearer.');
      expect(info.complete).assertTrue();
      expect(info.newFeedUrl).assertEqual('http://example.org');
      syndfeed.entries.forEach((entry: SyndEntry) => {
        expect(entryInfo(entry) instanceof EntryInformation).assertTrue();
      });
      syndfeed = readSynd('modules/xml/rsr.xml');
      syndfeed.entries.forEach((entry: SyndEntry) => {
        expect(entryInfo(entry) instanceof EntryInformation).assertTrue();
      });
    });

    it('testParseItem', 0, () => {
      const syndfeed = readSynd('modules/xml/leshow.xml');
      const entryInfo0 = entryInfo(syndfeed.entries[0]);
      expect(entryInfo0.closedCaptioned).assertTrue();
      expect(entryInfo0.order).assertEqual(2);
      expect(entryInfo0.image).assertEqual('http://example.org/image.png');
      expect(entryInfo0.explicit).assertFalse();
      expect(entryInfo0.title).assertEqual('test-itunes-title');
      expect(entryInfo(syndfeed.entries[1]).explicit).assertTrue();
      const entryInfo2 = entryInfo(syndfeed.entries[2]);
      expect(entryInfo2.explicit).assertFalse();
      expect(entryInfo2.explicitNullable).assertNull();
    });

    it('testDuration', 0, () => {
      expect(entryInfo(readSynd('modules/com/rometools/modules/itunes/duration.xml').entries[0]).duration!.milliseconds)
        .assertEqual(1000);
    });

    it('testDurationEmpty', 0, () => {
      expect(entryInfo(readSynd('modules/com/rometools/modules/itunes/duration-empty.xml').entries[0]).duration)
        .assertNull();
    });

    it('testDurationBad', 0, () => {
      expect(entryInfo(readSynd('modules/com/rometools/modules/itunes/duration-bad.xml').entries[0]).duration)
        .assertNull();
    });

    it('testExplicitnessTrue', 0, () => {
      ['explicitness-capital-yes.xml', 'explicitness-yes.xml'].forEach((xml: string) => {
        expect(feedInfo(readSynd(`modules/com/rometools/modules/itunes/${xml}`)).explicitNullable).assertTrue();
      });
    });

    it('testExplicitnessFalse', 0, () => {
      ['explicitness-no.xml', 'explicitness-clean.xml'].forEach((xml: string) => {
        expect(feedInfo(readSynd(`modules/com/rometools/modules/itunes/${xml}`)).explicitNullable).assertFalse();
      });
    });

    it('testParseNonHttpUris', 0, () => {
      const syndfeed = readSynd('modules/itunes/no-http-uris.xml');
      expect(feedInfo(syndfeed).imageUri).assertEqual('file://some-location/1.jpg');
      expect(entryInfo(syndfeed.entries[0]).imageUri).assertEqual('gs://some-location/whitespaces are allowed/2.jpg');
    });

    // Expected values from ROME 6b4a7e8 on Temurin 17.0.17+10.
    it('parseEdgeValuesMatchRome', 0, () => {
      const info = parseItem('<itunes:block>yeſ</itunes:block><itunes:isClosedCaptioned> YES </itunes:isClosedCaptioned>' +
        '<itunes:explicit> TRUE </itunes:explicit><itunes:order>+٣</itunes:order><itunes:season>x</itunes:season>' +
        '<itunes:episode> 7 </itunes:episode><itunes:keywords> a,,b , c &amp; d,<b>e</b> </itunes:keywords>' +
        '<itunes:image href=" http://exa mple.com/i.png "/><itunes:author> A </itunes:author>' +
        '<itunes:title> T </itunes:title><itunes:duration>bad:1:2:3</itunes:duration>');
      expect(info.block).assertTrue();
      expect(info.closedCaptioned).assertTrue();
      expect(info.explicitNullable).assertTrue();
      expect(info.order).assertEqual(3);
      expect(info.season).assertNull();
      expect(info.episode).assertEqual(7);
      expect(info.keywords.join('~')).assertEqual('a~b ~ c &amp; d~<b>e</b>');
      expect(info.image).assertEqual('http://exa mple.com/i.png');
      expect(info.imageUri).assertEqual('http://exa mple.com/i.png');
      expect(info.author).assertEqual(' A ');
      expect(info.title).assertEqual(' T ');
      expect(info.duration).assertNull();
      const other = parseItem('<itunes:image href="nope"/><itunes:explicit>maybe</itunes:explicit>');
      expect(other.image).assertNull();
      expect(other.imageUri).assertEqual('nope');
      expect(other.explicitNullable).assertNull();
      expect(other.keywords.length).assertEqual(0);
    });
  });

  describe('ITunesGeneratorTest', () => {
    // ROME compares the modules' toString(), which is not ported; the serialized modules hold more.
    ['modules/xml/leshow.xml', 'modules/xml/lr.xml'].forEach((id: string) => {
      it(`testEndToEnd ${id}`, 0, () => {
        const syndfeed = readSynd(id);
        const syndCheck = new SyndFeed(readWire(writeSynd(syndfeed)));
        expect(json(syndCheck.getModule(ITunes.URI)!)).assertEqual(json(syndfeed.getModule(ITunes.URI)!));
        expect(syndCheck.entries.length).assertEqual(syndfeed.entries.length);
        syndfeed.entries.forEach((entry: SyndEntry, i: number) => {
          expect(json(syndCheck.entries[i].getModule(ITunes.URI)!)).assertEqual(json(entry.getModule(ITunes.URI)!));
        });
      });
    });

    it('testCreate', 0, () => {
      const feed = new SyndFeed();
      feed.feedType = 'rss_2.0';
      feed.language = 'en-us';
      feed.title = 'sales.com on the Radio!';
      feed.description = 'sales.com radio shows in MP3 format';
      feed.link = 'http://foo/rss/podcasts.rss';
      const fi = new FeedInformation();
      fi.ownerName = 'sales.com';
      fi.categories.push(new Category('Shopping'));
      fi.ownerEmailAddress = 'patti@sales.com';
      fi.type = 'serial';
      feed.modules.push(fi);
      const xml = writeSynd(feed);
      expect(xml.includes('<itunes:category text="Shopping" />')).assertTrue();
      expect(xml.includes('<itunes:type>serial</itunes:type>')).assertTrue();
    });

    it('testImage', 0, () => {
      const feed = imageFeed();
      const itunesFeed = new FeedInformation();
      itunesFeed.image = 'https://example.org/test.png';
      feed.modules.push(itunesFeed);
      const parsed = feedInfo(new SyndFeed(readWire(writeSynd(feed))));
      expect(parsed.image).assertEqual('https://example.org/test.png');
      expect(parsed.imageUri).assertEqual('https://example.org/test.png');
    });

    it('testImageUri', 0, () => {
      const feed = imageFeed();
      const itunesFeed = new FeedInformation();
      itunesFeed.imageUri = 'https://example.org/test.png';
      feed.modules.push(itunesFeed);
      const parsed = feedInfo(new SyndFeed(readWire(writeSynd(feed))));
      expect(parsed.imageUri).assertEqual('https://example.org/test.png');
      expect(parsed.image).assertEqual('https://example.org/test.png');
    });

    it('testImageTakesPrecedenceOverImageUri', 0, () => {
      const feed = imageFeed();
      const itunesFeed = new FeedInformation();
      itunesFeed.image = 'https://example.org/test1.png';
      itunesFeed.imageUri = 'https://example.org/test2.png';
      feed.modules.push(itunesFeed);
      const parsed = feedInfo(new SyndFeed(readWire(writeSynd(feed))));
      expect(parsed.image).assertEqual('https://example.org/test1.png');
      expect(parsed.imageUri).assertEqual('https://example.org/test1.png');
    });

    // Expected output from ROME 6b4a7e8: null owner fields and no keywords still produce empty elements.
    it('emptyFeedInformationMatchesRome', 0, () => {
      const channel = new Element('channel');
      new ITunesGenerator().generate(new FeedInformation(), channel);
      expect(new XMLOutputter(Format.getRawFormat()).outputString(channel)).assertEqual(
        '<channel xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"><itunes:owner><itunes:email></itunes:email>' +
          '<itunes:name></itunes:name></itunes:owner><itunes:keywords></itunes:keywords></channel>');
    });
  });

  describe('ITunesGolden', () => {
    GOLDEN_FIXTURES.forEach((id: string) => {
      fixture(id).kinds('full').forEach((kind: string) => {
        it(`${kind} ${id}`, 0, () => {
          assertGolden(id, 'full', kind);
        });
      });
    });
  });
}
