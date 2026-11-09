import { describe, it, expect } from '@ohos/hypium';
import { DCModule, DCSubject } from '../main/ets/feed/module/DCModule';
import { SyndCategory } from '../main/ets/feed/synd/SyndCategory';
import { SyndEntry } from '../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../main/ets/feed/synd/SyndFeed';
import { SyndPerson } from '../main/ets/feed/synd/SyndPerson';

export default function syndTest() {
  describe('Synd', () => {
    it('modulesAlwaysContainDc', 0, () => {
      const feed = new SyndFeed();
      expect(feed.modules.length).assertEqual(1);
      feed.modules = [];
      expect(feed.getModule(DCModule.URI) instanceof DCModule).assertTrue();
    });

    it('feedConveniencePropertiesUseDc', 0, () => {
      const feed = new SyndFeed();
      const date = new Date(Date.UTC(2024, 0, 2));
      feed.publishedDate = date;
      feed.copyright = 'c';
      feed.language = 'tr';
      feed.author = 'a';
      const dc = feed.getModule(DCModule.URI) as DCModule;
      expect(dc.dates[0].getTime()).assertEqual(date.getTime());
      expect(dc.rightsList[0]).assertEqual('c');
      expect(dc.languages[0]).assertEqual('tr');
      expect(dc.creators[0]).assertEqual('a');
      feed.publishedDate = null;
      expect(dc.dates.length).assertEqual(0);
    });

    it('entryUpdatedDateIsCopiedInAndOut', 0, () => {
      const entry = new SyndEntry();
      expect(entry.updatedDate).assertNull();
      const date = new Date(Date.UTC(2024, 0, 2));
      entry.updatedDate = date;
      date.setTime(0);
      expect(entry.updatedDate!.getTime()).assertEqual(Date.UTC(2024, 0, 2));
      entry.updatedDate!.setTime(0);
      expect(entry.updatedDate!.getTime()).assertEqual(Date.UTC(2024, 0, 2));
      let threw = false;
      try {
        entry.updatedDate = null;
      } catch (e) {
        threw = true;
      }
      expect(threw).assertTrue();
      expect(entry.updatedDate!.getTime()).assertEqual(Date.UTC(2024, 0, 2));
    });

    it('titleIsBackedByTitleEx', 0, () => {
      const feed = new SyndFeed();
      expect(feed.title).assertNull();
      feed.title = 'T';
      expect(feed.titleEx!.value).assertEqual('T');
      feed.description = 'D';
      expect(feed.descriptionEx!.value).assertEqual('D');
    });

    it('feedCategoriesAreDcSubjects', 0, () => {
      const feed = new SyndFeed();
      const category = new SyndCategory();
      category.name = 'news';
      category.taxonomyUri = 'urn:tax';
      feed.categories = [category];
      const dc = feed.getModule(DCModule.URI) as DCModule;
      expect(dc.subjects[0].value).assertEqual('news');
      expect(dc.subjects[0].taxonomyUri).assertEqual('urn:tax');
      expect(feed.categories[0].name).assertEqual('news');
    });

    it('entryAuthorPrefersAuthorsThenDcThenEmpty', 0, () => {
      const entry = new SyndEntry();
      expect(entry.author).assertEqual('');
      entry.author = 'dc';
      entry.author = 'ignored because dc creator is set';
      expect(entry.author).assertEqual('dc');
      const person = new SyndPerson();
      person.name = 'person';
      entry.authors = [person];
      expect(entry.author).assertEqual('person');
    });

    it('dcCloneIsDeep', 0, () => {
      const dc = new DCModule();
      const subject = new DCSubject();
      subject.value = 's';
      dc.subjects = [subject];
      dc.dates = [new Date(0)];
      dc.title = 't';
      const copy = dc.clone();
      copy.subjects[0].value = 'changed';
      copy.dates[0].setTime(1000);
      copy.titles.push('x');
      expect(dc.subjects[0].value).assertEqual('s');
      expect(dc.dates[0].getTime()).assertEqual(0);
      expect(dc.titles.length).assertEqual(1);
    });

    it('unknownFeedTypeThrows', 0, () => {
      const feed = new SyndFeed();
      let message = '';
      try {
        feed.createWireFeed('rss_9.9');
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Invalid feed type [rss_9.9]');
    });
  });
}
