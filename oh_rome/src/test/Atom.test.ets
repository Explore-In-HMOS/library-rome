import { describe, it, expect } from '@ohos/hypium';
import { Category } from '../main/ets/feed/atom/Category';
import { Content } from '../main/ets/feed/atom/Content';
import { Entry } from '../main/ets/feed/atom/Entry';
import { Feed } from '../main/ets/feed/atom/Feed';
import { Generator } from '../main/ets/feed/atom/Generator';
import { Link } from '../main/ets/feed/atom/Link';
import { Person } from '../main/ets/feed/atom/Person';
import { Module } from '../main/ets/feed/module/Module';
import { DCModule } from '../main/ets/feed/module/DCModule';
import { SyndPerson } from '../main/ets/feed/synd/SyndPerson';

// Readable java.beans properties of the ROME classes (Introspector, minus class), without the computed ones below.
const CATEGORY_PROPS = 'label scheme schemeResolved term';
const CONTENT_PROPS = 'mode src type value';
const ENTRY_PROPS = 'alternateLinks authors categories contents contributors created foreignMarkup id ' +
  'modules otherLinks published rights source summary titleEx updated xmlBase';
const FEED_PROPS = 'alternateLinks authors categories contributors encoding entries feedType foreignMarkup ' +
  'generator icon id info language logo modules otherLinks rights styleSheet subtitle titleEx updated xmlBase';
const GENERATOR_PROPS = 'url value version';
const LINK_PROPS = 'href hrefResolved hreflang length rel title type';
// uriResolved is write-only in ROME, so it is not a readable property there.
const PERSON_PROPS = 'email modules name uri uriResolved';

function jsonKeys(json: string): string {
  const obj = JSON.parse(json) as Record<string, Object>;
  return Object.keys(obj).map((k: string) => k.startsWith('_') ? k.substring(1) : k).sort().join(' ');
}

function sorted(props: string): string {
  return props.split(' ').sort().join(' ');
}

function link(rel: string, href: string): Link {
  const l = new Link();
  l.rel = rel;
  l.href = href;
  return l;
}

export default function atomTest() {
  describe('Atom', () => {
    it('serializedKeysMatchJavaBeanProperties', 0, () => {
      expect(jsonKeys(JSON.stringify(new Category()))).assertEqual(sorted(CATEGORY_PROPS));
      expect(jsonKeys(JSON.stringify(new Content()))).assertEqual(sorted(CONTENT_PROPS));
      expect(jsonKeys(JSON.stringify(new Entry()))).assertEqual(sorted(ENTRY_PROPS));
      expect(jsonKeys(JSON.stringify(new Feed('atom_1.0')))).assertEqual(sorted(FEED_PROPS));
      expect(jsonKeys(JSON.stringify(new Generator()))).assertEqual(sorted(GENERATOR_PROPS));
      expect(jsonKeys(JSON.stringify(new Link()))).assertEqual(sorted(LINK_PROPS));
      expect(jsonKeys(JSON.stringify(new Person()))).assertEqual(sorted(PERSON_PROPS));
    });

    it('defaults', 0, () => {
      const l = new Link();
      expect(l.rel).assertEqual('alternate');
      expect(l.length).assertEqual(0);
      expect(l.href).assertNull();
      const entry = new Entry();
      expect(entry.otherLinks.length).assertEqual(0);
      expect(entry.modules.length).assertEqual(0);
      expect(entry.title).assertNull();
      expect(entry.published).assertNull();
      const feed = new Feed();
      expect(feed.feedType).assertNull();
      expect(feed.entries.length).assertEqual(0);
      expect(new Feed('atom_0.3').feedType).assertEqual('atom_0.3');
      expect(new Content().mode).assertNull();
    });

    it('resolvedFallsBackToRaw', 0, () => {
      const l = new Link();
      l.href = 'a.html';
      expect(l.hrefResolved).assertEqual('a.html');
      l.hrefResolved = 'http://x/a.html';
      expect(l.hrefResolved).assertEqual('http://x/a.html');
      expect(l.href).assertEqual('a.html');
      expect(JSON.stringify(new Link()).includes('"_hrefResolved":null')).assertTrue();

      const c = new Category();
      c.scheme = 's';
      expect(c.schemeResolved).assertEqual('s');
      c.schemeResolved = 'http://x/s';
      expect(c.schemeResolved).assertEqual('http://x/s');

      const p = new Person();
      p.uri = 'u';
      expect(p.getUriResolved(null)).assertEqual('u');
      p.uriResolved = 'http://x/u';
      expect(p.getUriResolved(null)).assertEqual('http://x/u');
    });

    it('personUrlIsUri', 0, () => {
      const p = new Person();
      p.url = 'http://a';
      expect(p.uri).assertEqual('http://a');
      p.uri = 'http://b';
      expect(p.url).assertEqual('http://b');
      const persons: SyndPerson[] = [p];
      expect(persons[0] instanceof SyndPerson).assertTrue();
      const dc: Module = new DCModule();
      p.modules = [dc];
      expect(p.getModule(DCModule.URI)).assertEqual(dc);
    });

    it('contentModeIsLowerCasedAndValidated', 0, () => {
      const c = new Content();
      c.mode = Content.ESCAPED;
      expect(c.mode).assertEqual('escaped');
      c.mode = 'base64';
      expect(c.mode).assertEqual('base64');
      let message = '';
      try {
        c.mode = 'XML';
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Invalid mode [XML]');
      expect(c.mode).assertEqual('xml');
      message = '';
      try {
        c.mode = null;
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Invalid mode [null]');
      expect(c.mode).assertNull();
      message = '';
      try {
        c.mode = Content.TEXT;
      } catch (e) {
        message = (e as Error).message;
      }
      expect(message).assertEqual('Invalid mode [text]');
      expect(Content.HTML).assertEqual('html');
      expect(Content.XHTML).assertEqual('xhtml');
    });

    it('titleIsBackedByTitleEx', 0, () => {
      const entry = new Entry();
      entry.title = 'T';
      expect(entry.titleEx!.value).assertEqual('T');
      const content = new Content();
      content.type = 'html';
      entry.titleEx = content;
      entry.title = 'U';
      expect(entry.titleEx).assertEqual(content);
      expect(content.value).assertEqual('U');
      expect(entry.title).assertEqual('U');

      const feed = new Feed();
      expect(feed.title).assertNull();
      feed.title = 'F';
      expect(feed.titleEx!.value).assertEqual('F');
      expect(feed.title).assertEqual('F');
    });

    it('entryDatesAreCopiedAndAliased', 0, () => {
      const entry = new Entry();
      const date = new Date(Date.UTC(2024, 0, 2));
      entry.published = date;
      date.setTime(0);
      expect(entry.published!.getTime()).assertEqual(Date.UTC(2024, 0, 2));
      entry.published!.setTime(0);
      expect(entry.published!.getTime()).assertEqual(Date.UTC(2024, 0, 2));
      expect(entry.issued!.getTime()).assertEqual(Date.UTC(2024, 0, 2));
      entry.issued = new Date(5);
      expect(entry.published!.getTime()).assertEqual(5);

      entry.modified = new Date(7);
      expect(entry.updated!.getTime()).assertEqual(7);
      entry.updated = new Date(8);
      expect(entry.modified!.getTime()).assertEqual(8);
      entry.updated!.setTime(0);
      expect(entry.updated!.getTime()).assertEqual(8);

      const created = new Date(9);
      entry.created = created;
      created.setTime(0);
      expect(entry.created!.getTime()).assertEqual(9);
      entry.created = null;
      expect(entry.created).assertNull();
      expect(JSON.stringify(entry).includes('"_updated":"1970-01-01T00:00:00.008Z"')).assertTrue();
    });

    it('feedAliasesShareState', 0, () => {
      const feed = new Feed();
      const tagline = new Content();
      feed.tagline = tagline;
      expect(feed.subtitle).assertEqual(tagline);
      feed.subtitle = null;
      expect(feed.tagline).assertNull();
      feed.copyright = 'c';
      expect(feed.rights).assertEqual('c');
      feed.rights = 'r';
      expect(feed.copyright).assertEqual('r');
      const date = new Date(3);
      feed.modified = date;
      expect(feed.updated).assertEqual(date);
      feed.updated = null;
      expect(feed.modified).assertNull();
    });

    it('mediaEntryLooksAtOtherLinks', 0, () => {
      const entry = new Entry();
      expect(entry.mediaEntry).assertFalse();
      entry.alternateLinks = [link('edit-media', 'a')];
      expect(entry.mediaEntry).assertFalse();
      entry.otherLinks = [link('edit', 'e'), link('edit-media', 'm')];
      expect(entry.mediaEntry).assertTrue();
    });

    it('findRelatedLinkReturnsFirstOtherLinkWithRel', 0, () => {
      const entry = new Entry();
      expect(entry.findRelatedLink('self')).assertNull();
      const first = link('self', '1');
      entry.alternateLinks = [link('related', 'alt')];
      entry.otherLinks = [link('edit', 'e'), first, link('self', '2')];
      expect(entry.findRelatedLink('self')).assertEqual(first);
      expect(entry.findRelatedLink('related')).assertNull();
      expect(entry.findRelatedLink('Self')).assertNull();
    });

    it('getModuleFindsByUri', 0, () => {
      const dc = new DCModule();
      const entry = new Entry();
      expect(entry.getModule(DCModule.URI)).assertNull();
      entry.modules = [dc];
      expect(entry.getModule(DCModule.URI)).assertEqual(dc);
      const feed = new Feed();
      feed.modules = [dc];
      expect(feed.getModule(DCModule.URI)).assertEqual(dc);
      expect(feed.getModule('urn:other')).assertNull();
    });

    it('aliasSettersCopyTheDate', 0, () => {
      const entry = new Entry();
      const modified = new Date(1000);
      entry.modified = modified;
      modified.setTime(2000);
      expect(entry.updated!.getTime()).assertEqual(1000);
      const issued = new Date(3000);
      entry.issued = issued;
      issued.setTime(4000);
      expect(entry.published!.getTime()).assertEqual(3000);
    });

    it('feedTitleReusesTitleEx', 0, () => {
      const feed = new Feed();
      const titleEx = new Content();
      titleEx.type = 'html';
      feed.titleEx = titleEx;
      feed.title = 'T';
      expect(feed.titleEx === titleEx).assertTrue();
      expect(feed.titleEx!.type).assertEqual('html');
      expect(feed.titleEx!.value).assertEqual('T');
    });

    it('mediaEntryRelIsCaseSensitive', 0, () => {
      const entry = new Entry();
      const link = new Link();
      link.rel = 'EDIT-MEDIA';
      entry.otherLinks = [link];
      expect(entry.mediaEntry).assertFalse();
    });

    // Expected values from ROME 6b4a7e8 on Temurin 17.0.17+10: Link.clone() is CloneableBean.beanClone.
    it('linkCloneCopiesThroughGettersAndSkipsNulls', 0, () => {
      const link = new Link();
      link.rel = null;
      link.href = 'h';
      link.title = 't';
      link.length = 5;
      const copy = link.clone();
      expect(copy === link).assertFalse();
      expect(copy.rel).assertEqual('alternate');
      expect(copy.href).assertEqual('h');
      expect(copy.title).assertEqual('t');
      expect(copy.length).assertEqual(5);
      expect(copy.type).assertNull();
      link.href = 'changed';
      expect(copy.hrefResolved).assertEqual('h');
      expect(link.hrefResolved).assertEqual('changed');
    });
  });
}
