import { describe, it, expect } from '@ohos/hypium';
import { DCModule } from '../main/ets/feed/module/DCModule';
import { Category } from '../main/ets/feed/rss/Category';
import { Channel } from '../main/ets/feed/rss/Channel';
import { Cloud } from '../main/ets/feed/rss/Cloud';
import { Content } from '../main/ets/feed/rss/Content';
import { Description } from '../main/ets/feed/rss/Description';
import { Enclosure } from '../main/ets/feed/rss/Enclosure';
import { Guid } from '../main/ets/feed/rss/Guid';
import { Image } from '../main/ets/feed/rss/Image';
import { Item } from '../main/ets/feed/rss/Item';
import { Source } from '../main/ets/feed/rss/Source';
import { TextInput } from '../main/ets/feed/rss/TextInput';

// The expect lines are pasted from tools/rss-oracle/RssOracle.java, which runs ROME 6b4a7e8.

function errorOf(run: () => void): string {
  try {
    run();
    return 'no error';
  } catch (e) {
    return (e as Error).message;
  }
}

function time(d: Date | null): number {
  return d!.getTime();
}

export default function rssTest() {
  describe('Rss', () => {
    it('channelDefaults', 0, () => {
      expect(new Channel().feedType).assertNull();
      const c = new Channel('rss_2.0');
      expect(c.feedType).assertEqual('rss_2.0');
      expect(c.ttl).assertEqual(-1);
      expect(c.title).assertNull();
      expect(c.description).assertNull();
      expect(c.link).assertNull();
      expect(c.uri).assertNull();
      expect(c.image).assertNull();
      expect(c.textInput).assertNull();
      expect(c.language).assertNull();
      expect(c.rating).assertNull();
      expect(c.copyright).assertNull();
      expect(c.pubDate).assertNull();
      expect(c.lastBuildDate).assertNull();
      expect(c.docs).assertNull();
      expect(c.managingEditor).assertNull();
      expect(c.webMaster).assertNull();
      expect(c.cloud).assertNull();
      expect(c.generator).assertNull();
      expect(c.items.length).assertEqual(0);
      expect(c.categories.length).assertEqual(0);
      expect(c.modules.length).assertEqual(0);
      expect(c.foreignMarkup.length).assertEqual(0);
      expect(c.skipHours.length).assertEqual(0);
      expect(c.skipDays.length).assertEqual(0);
      expect([Channel.SUNDAY, Channel.MONDAY, Channel.TUESDAY, Channel.WEDNESDAY, Channel.THURSDAY, Channel.FRIDAY, Channel.SATURDAY].join(',')).assertEqual('sunday,monday,tuesday,wednesday,thursday,friday,saturday');
    });

    it('channelListsKeepAddedValues', 0, () => {
      const c = new Channel('rss_2.0');
      c.items.push(new Item());
      c.categories.push(new Category());
      c.modules.push(new DCModule());
      expect(c.items.length).assertEqual(1);
      expect(c.categories.length).assertEqual(1);
      expect(c.getModule(DCModule.URI) instanceof DCModule).assertTrue();
      expect(c.getModule('urn:x')).assertNull();
      expect(new Channel().getModule(DCModule.URI)).assertNull();
    });

    it('unsetSkipListsSerializeAsEmptyLists', 0, () => {
      const c = new Channel('rss_2.0');
      expect(JSON.stringify(c).includes('"_skipHours":[]')).assertTrue();
      expect(JSON.stringify(c).includes('"_skipDays":[]')).assertTrue();
    });

    it('skipHoursAcceptsZeroToTwentyFour', 0, () => {
      const c = new Channel('rss_2.0');
      const hours = [0, 24];
      c.skipHours = hours;
      expect(c.skipHours === hours).assertTrue();
      c.skipHours.push(99);
      expect(c.skipHours.join(',')).assertEqual('0,24,99');
      expect(errorOf(() => { c.skipHours = [25]; })).assertEqual('Invalid hour [25]');
      expect(errorOf(() => { c.skipHours = [-1]; })).assertEqual('Invalid hour [-1]');
      expect(errorOf(() => { c.skipHours = [1, 25, -1]; })).assertEqual('Invalid hour [25]');
      expect(c.skipHours.join(',')).assertEqual('0,24,99');
      c.skipHours = [];
      expect(c.skipHours.length).assertEqual(0);
    });

    it('skipDaysLowercasesTheGivenListInPlace', 0, () => {
      const c = new Channel('rss_2.0');
      const days = ['Monday', 'SUNDAY', 'saturday'];
      c.skipDays = days;
      expect(c.skipDays === days).assertTrue();
      expect(days.join(',')).assertEqual('monday,sunday,saturday');
      const bad = ['Tuesday', 'Funday', 'FRIDAY'];
      expect(errorOf(() => { c.skipDays = bad; })).assertEqual('Invalid day [funday]');
      expect(bad.join(',')).assertEqual('tuesday,Funday,FRIDAY');
      expect(c.skipDays.join(',')).assertEqual('monday,sunday,saturday');
      expect(errorOf(() => { c.skipDays = [' monday']; })).assertEqual('Invalid day [ monday]');
    });

    it('channelDatesAreCopied', 0, () => {
      const c = new Channel('rss_2.0');
      const pubDate = new Date(1704153600000);
      c.pubDate = pubDate;
      pubDate.setTime(0);
      expect(time(c.pubDate)).assertEqual(1704153600000);
      c.pubDate!.setTime(5);
      expect(time(c.pubDate)).assertEqual(1704153600000);
      expect(c.pubDate === c.pubDate).assertFalse();
      const lastBuildDate = new Date(1704153600000);
      c.lastBuildDate = lastBuildDate;
      lastBuildDate.setTime(0);
      c.lastBuildDate!.setTime(7);
      expect(time(c.lastBuildDate)).assertEqual(1704153600000);
      c.pubDate = null;
      expect(c.pubDate).assertNull();
    });

    it('itemDefaultsListsAndModules', 0, () => {
      const i = new Item();
      expect(i.title).assertNull();
      expect(i.link).assertNull();
      expect(i.uri).assertNull();
      expect(i.description).assertNull();
      expect(i.content).assertNull();
      expect(i.source).assertNull();
      expect(i.guid).assertNull();
      expect(i.comments).assertNull();
      expect(i.author).assertNull();
      expect(i.pubDate).assertNull();
      expect(i.expirationDate).assertNull();
      expect(i.categories.length).assertEqual(0);
      expect(i.modules.length).assertEqual(0);
      expect(i.foreignMarkup.length).assertEqual(0);
      i.enclosures.push(new Enclosure());
      expect(i.enclosures.length).assertEqual(1);
      expect(i.getModule(DCModule.URI)).assertNull();
      i.modules.push(new DCModule());
      expect(i.getModule(DCModule.URI) instanceof DCModule).assertTrue();
    });

    it('itemDatesAreCopied', 0, () => {
      const i = new Item();
      const pubDate = new Date(1704153600000);
      i.pubDate = pubDate;
      pubDate.setTime(0);
      i.pubDate!.setTime(1);
      const expirationDate = new Date(1704240000000);
      i.expirationDate = expirationDate;
      expirationDate.setTime(0);
      i.expirationDate!.setTime(1);
      expect(time(i.pubDate)).assertEqual(1704153600000);
      expect(time(i.expirationDate)).assertEqual(1704240000000);
    });

    it('beanDefaults', 0, () => {
      const image = new Image();
      expect(image.title).assertNull();
      expect(image.url).assertNull();
      expect(image.link).assertNull();
      expect(image.width).assertEqual(-1);
      expect(image.height).assertEqual(-1);
      expect(image.description).assertNull();
      const guid = new Guid();
      expect(guid.permaLink).assertTrue();
      expect(guid.value).assertNull();
      const enclosure = new Enclosure();
      expect(enclosure.url).assertNull();
      expect(enclosure.length).assertEqual(0);
      expect(enclosure.type).assertNull();
      const cloud = new Cloud();
      expect(cloud.domain).assertNull();
      expect(cloud.port).assertEqual(0);
      expect(cloud.path).assertNull();
      expect(cloud.registerProcedure).assertNull();
      expect(cloud.protocol).assertNull();
      const category = new Category();
      expect(category.domain).assertNull();
      expect(category.value).assertNull();
      const content = new Content();
      expect(content.type).assertNull();
      expect(content.value).assertNull();
      expect(Content.HTML).assertEqual('html');
      expect(Content.TEXT).assertEqual('text');
      const description = new Description();
      expect(description.type).assertNull();
      expect(description.value).assertNull();
      const source = new Source();
      expect(source.url).assertNull();
      expect(source.value).assertNull();
      const textInput = new TextInput();
      expect(textInput.title).assertNull();
      expect(textInput.description).assertNull();
      expect(textInput.name).assertNull();
      expect(textInput.link).assertNull();
    });
  });
}
