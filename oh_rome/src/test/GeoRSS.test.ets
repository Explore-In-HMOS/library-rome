// Ported from ROME rome-modules/src/test/java/com/rometools/modules/georss/GeoRSSModuleTest.java (Apache-2.0)
import { describe, expect, it } from '@ohos/hypium';
import { Element } from '../main/ets/xml/Dom';
import { parseXml } from '../main/ets/xml/XmlParser';
import { Format } from '../main/ets/xml/Format';
import { XMLOutputter } from '../main/ets/xml/XmlOutputter';
import { Extendable } from '../main/ets/feed/module/Module';
import { WireFeed } from '../main/ets/feed/WireFeed';
import { Channel } from '../main/ets/feed/rss/Channel';
import { Item } from '../main/ets/feed/rss/Item';
import { SyndContent } from '../main/ets/feed/synd/SyndContent';
import { SyndEntry } from '../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { WireFeedParser } from '../main/ets/io/WireFeedParser';
import { plugins } from '../main/ets/io/impl/PluginRegistry';
import { GeoRSSModule } from '../main/ets/modules/georss/GeoRSSModule';
import { GeoRSSUtils } from '../main/ets/modules/georss/GeoRSSUtils';
import { SimpleGenerator } from '../main/ets/modules/georss/SimpleGenerator';
import { SimpleModuleImpl } from '../main/ets/modules/georss/SimpleModuleImpl';
import { LineString } from '../main/ets/modules/georss/geometries/LineString';
import { Position } from '../main/ets/modules/georss/geometries/Position';
import { PositionList } from '../main/ets/modules/georss/geometries/PositionList';
import { assertGolden, fixture } from './golden/Golden';

const DELTA = 0.00001;

const ATOM_FIXTURE = 'modules/org/rometools/feed/module/georss/usgs-gov-earthquakes-all-hour-atom.xml';
// The GeoRSS module fixtures, every kind.
const GOLDEN_FIXTURES: string[] = ['modules/data/rss2.0-gml.xml', 'modules/data/rss2.0-simple.xml',
  'modules/data/rss2.0-w3cgeo.xml', 'modules/data/rss1.0-w3cgeo.xml', 'modules/data/georss-double-space-issue.xml',
  'modules/org/rometools/feed/module/georss/issue-02.xml', 'modules/data/geo-rss-issue-27.rss', ATOM_FIXTURE];

function readWire(xml: string): WireFeed {
  const document = parseXml(xml);
  return plugins().getFeedParsers().find((p: WireFeedParser) => p.isMyType(document))!.parse(document);
}

// SyndFeedOutput then SyndFeedInput.
function writeAndRead(feed: SyndFeed): SyndFeed {
  const wire = feed.createWireFeed();
  const document = plugins().getFeedGenerator(wire.feedType!)!.generate(wire);
  return new SyndFeed(readWire(new XMLOutputter(Format.getPrettyFormat()).outputString(document)));
}

// ROME reads these RSS files through SyndFeedInput; until A6 the items are read from the wire feed, which holds the
// same modules the converter copies onto the entries.
function assertTestFile(id: string, expectedLat: (number | null)[], expectedLng: (number | null)[]): void {
  assertItems((readWire(fixture(id).xml) as Channel).items, expectedLat, expectedLng);
}

function assertItems(items: Extendable[], expectedLat: (number | null)[], expectedLng: (number | null)[]): void {
  for (let i = 0; i < items.length; i++) {
    const position = GeoRSSUtils.getGeoRSS(items[i])!.position;
    const lat = expectedLat[i];
    const lng = expectedLng[i];
    if (lat === null || lng === null) {
      expect(position).assertNull();
    } else {
      expect(Math.abs(position!.latitude - lat) < DELTA).assertTrue();
      expect(Math.abs(position!.longitude - lng) < DELTA).assertTrue();
    }
  }
}

// ROME's createFeed().
function createFeed(): SyndFeed {
  const feed = new SyndFeed();
  feed.feedType = 'rss_2.0';
  feed.title = 'Sample Feed (created with ROME)';
  feed.link = 'http://rome.dev.java.net';
  feed.description = 'This feed has been created using ROME (Java syndication utilities';
  const entry = new SyndEntry();
  entry.title = 'ROME v1.0';
  entry.link = 'http://wiki.java.net/bin/view/Javawsxml/Rome01';
  entry.publishedDate = new Date();
  const description = new SyndContent();
  description.type = 'text/plain';
  description.value = 'Initial release of ROME';
  entry.description = description;
  feed.entries = [entry];
  return feed;
}

export default function geoRSSTest() {
  describe('GeoRSSGolden', () => {
    GOLDEN_FIXTURES.forEach((id: string) => {
      fixture(id).kinds('full').forEach((kind: string) => {
        it(`${kind} ${id}`, 0, () => {
          assertGolden(id, 'full', kind);
        });
      });
    });
  });

  describe('GeoRSSModuleTest', () => {
    it('testReadRss2Simple', 0, () => {
      assertTestFile('modules/data/rss2.0-simple.xml', [31.7666667, 31.7666667, 31.7666667],
        [35.2333333, 35.2333333, 35.2333333]);
    });

    it('testReadRss2W3CGeo', 0, () => {
      assertTestFile('modules/data/rss2.0-w3cgeo.xml', [42.986284, 41.492491, 39.901893, 40.750598],
        [-71.45156, -72.095783, -75.171998, -73.993392]);
    });

    it('testReadGML', 0, () => {
      assertTestFile('modules/data/rss2.0-gml.xml', [45.256, 45.256, 45.256, 45.256], [-71.92, -71.92, -71.92, -71.92]);
    });

    it('testNpeOnEmptyPoint', 0, () => {
      assertTestFile('modules/data/geo-rss-issue-27.rss', [null, 0.0, 0.0, 0.0, 43.653226, 0.0, 0.0, 0.0, 0.0, 0.0],
        [null, 0.0, 0.0, 0.0, -79.383184, 0.0, 0.0, 0.0, 0.0, 0.0]);
    });

    it('testProduceAndReadSimple', 0, () => {
      const feed = createFeed();
      const geoRSSModule = new SimpleModuleImpl();
      const position = new Position();
      position.latitude = 47.0;
      position.longitude = 9.0;
      geoRSSModule.position = position;
      feed.entries[0].modules.push(geoRSSModule);
      assertItems(writeAndRead(feed).entries, [47.0], [9.0]);
    });

    it('testProduceAndReadSimpleLine', 0, () => {
      const latitudes: number[] = [45.256, 46.46, 43.84];
      const longitudes: number[] = [-110.45, -109.48, -109.86];
      const feed = createFeed();
      const positionList = new PositionList();
      for (let i = 0; i < latitudes.length; i++) {
        positionList.add(latitudes[i], longitudes[i]);
      }
      const geoRSSModule = new SimpleModuleImpl();
      geoRSSModule.geometry = new LineString(positionList);
      feed.entries[0].modules.push(geoRSSModule);

      const entries = writeAndRead(feed).entries;
      expect(entries.length).assertEqual(1);
      const read = (GeoRSSUtils.getGeoRSS(entries[0]) as SimpleModuleImpl).geometry as LineString;
      expect(read.positionList.size()).assertEqual(3);
      for (let i = 0; i < read.positionList.size(); i++) {
        expect(Math.abs(read.positionList.getLatitude(i) - latitudes[i]) < DELTA).assertTrue();
        expect(Math.abs(read.positionList.getLongitude(i) - longitudes[i]) < DELTA).assertTrue();
      }
    });

    it('testParseInvalidPointValue', 0, () => {
      readWire(fixture('modules/org/rometools/feed/module/georss/issue-02.xml').xml);
    });

    it('testDoubleSpacePointValue', 0, () => {
      assertTestFile('modules/data/georss-double-space-issue.xml', [31.7666667, 31.7666667, 31.7666667],
        [35.2333333, 35.2333333, 35.2333333]);
    });

    it('testParseElevValue', 0, () => {
      const feed = new SyndFeed(readWire(fixture(ATOM_FIXTURE).xml));
      expect(feed.entries.length > 0).assertTrue();
      feed.entries.forEach((entry: SyndEntry) => {
        const geoRSSModule: GeoRSSModule = GeoRSSUtils.getGeoRSS(entry)!;
        expect(geoRSSModule.featureTypeTag).assertEqual('position');
        expect(entry.title!.indexOf(geoRSSModule.featureNameTag!) > 0).assertTrue();
        expect(geoRSSModule.relationshipTag).assertEqual('is-centered-at');
        expect(geoRSSModule.elev !== null).assertTrue();
        expect(geoRSSModule.floor).assertEqual(0);
        expect(geoRSSModule.radius).assertEqual(1.0);
      });
    });

    // ROME's output; the wire goldens cannot see generated coordinates, only roundtrip.xml can.
    it('generatesPointAsJdk17DoubleToString', 0, () => {
      const geoRSSModule = new SimpleModuleImpl();
      geoRSSModule.position = new Position(35.09239818, 37.99687960292);
      const item = new Element('item');
      new SimpleGenerator().generate(geoRSSModule, item);
      expect(item.getChildText('point', GeoRSSModule.SIMPLE_NS)).assertEqual('35.09239818 37.99687960292');
    });

    it('testFeatureNameTag', 0, () => {
      const feed = createFeed();
      const geoRSSModule = new SimpleModuleImpl();
      geoRSSModule.position = new Position(50.714, -1.876);
      geoRSSModule.featureNameTag = 'Bournemouth Pier';
      feed.entries[0].modules.push(geoRSSModule);
      const read = GeoRSSUtils.getGeoRSS(writeAndRead(feed).entries[0]) as SimpleModuleImpl;
      expect(read.featureNameTag).assertEqual('Bournemouth Pier');
    });
  });
}
