// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForAtom03.java (Apache-2.0)
import { Alternatives } from '../../../utils/Alternatives';
import { Lists } from '../../../utils/Lists';
import { Strings } from '../../../utils/Strings';
import { Content } from '../../atom/Content';
import { Entry } from '../../atom/Entry';
import { Feed } from '../../atom/Feed';
import { Link } from '../../atom/Link';
import { Person } from '../../atom/Person';
import { ModuleUtils } from '../../module/Module';
import { WireFeed } from '../../WireFeed';
import { Converter } from '../Converter';
import { SyndContent } from '../SyndContent';
import { SyndEnclosure } from '../SyndEnclosure';
import { SyndEntry } from '../SyndEntry';
import { SyndFeed } from '../SyndFeed';
import { SyndImage } from '../SyndImage';
import { SyndLink } from '../SyndLink';
import { SyndPerson } from '../SyndPerson';

export class ConverterForAtom03 implements Converter {
  private readonly type: string;

  constructor(type: string = 'atom_0.3') {
    this.type = type;
  }

  getType(): string {
    return this.type;
  }

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void {
    const aFeed = feed as Feed;

    syndFeed.modules = ModuleUtils.cloneModules(aFeed.modules);

    const foreignMarkup = feed.foreignMarkup;
    if (Lists.isNotEmpty(foreignMarkup)) {
      syndFeed.foreignMarkup = foreignMarkup;
    }

    syndFeed.encoding = aFeed.encoding;
    syndFeed.styleSheet = aFeed.styleSheet;

    const logo = aFeed.logo;
    const icon = aFeed.icon;

    if (logo !== null) {
      const image = new SyndImage();
      image.url = logo;
      syndFeed.image = image;
    } else if (icon !== null) {
      const image = new SyndImage();
      image.url = icon;
      syndFeed.image = image;
    }

    syndFeed.uri = aFeed.id;

    syndFeed.title = aFeed.title;

    const alternateLinks = aFeed.alternateLinks;
    if (Lists.isNotEmpty(alternateLinks)) {
      syndFeed.link = alternateLinks[0].hrefResolved;
    }
    const syndLinks: SyndLink[] = [];
    if (Lists.isNotEmpty(alternateLinks)) {
      syndLinks.push(...this.createSyndLinks(alternateLinks));
    }
    const otherLinks = aFeed.otherLinks;
    if (Lists.isNotEmpty(otherLinks)) {
      syndLinks.push(...this.createSyndLinks(otherLinks));
    }
    syndFeed.links = syndLinks;

    const tagline = aFeed.tagline;
    if (tagline !== null) {
      syndFeed.description = tagline.value;
    }

    const aEntries = aFeed.entries;
    if (Lists.isNotEmpty(aEntries)) {
      syndFeed.entries = this.createSyndEntries(aEntries, syndFeed.isPreservingWireFeed());
    }

    // Core Atom language/author/copyright/modified elements have precedence over the DC equivalents.

    const language = aFeed.language;
    if (language !== null) {
      syndFeed.language = language;
    }

    const authors = aFeed.authors;
    if (Lists.isNotEmpty(authors)) {
      syndFeed.authors = ConverterForAtom03.createSyndPersons(authors);
    }

    const copyright = aFeed.copyright;
    if (copyright !== null) {
      syndFeed.copyright = copyright;
    }

    const date = aFeed.modified;
    if (date !== null) {
      syndFeed.publishedDate = date;
    }
  }

  protected createSyndLinks(atomLinks: Link[]): SyndLink[] {
    const syndLinks: SyndLink[] = [];
    for (const link of atomLinks) {
      // Java calls link.getRel().equals(...), which throws for a null rel.
      if (link.rel === null) {
        throw new Error('Link rel is null');
      }
      if (link.rel !== 'enclosure') {
        syndLinks.push(this.createSyndLink(link));
      }
    }
    return syndLinks;
  }

  createSyndLink(link: Link): SyndLink {
    const syndLink = new SyndLink();
    syndLink.rel = link.rel;
    syndLink.type = link.type;
    syndLink.href = link.hrefResolved;
    syndLink.title = link.title;
    return syndLink;
  }

  protected createSyndEntries(atomEntries: Entry[], preserveWireItems: boolean): SyndEntry[] {
    const syndEntries: SyndEntry[] = [];
    for (const atomEntry of atomEntries) {
      syndEntries.push(this.createSyndEntry(atomEntry, preserveWireItems));
    }
    return syndEntries;
  }

  protected createSyndEntry(entry: Entry, preserveWireItem: boolean): SyndEntry {
    const syndEntry = new SyndEntry();

    if (preserveWireItem) {
      syndEntry.wireEntry = entry;
    }

    syndEntry.modules = ModuleUtils.cloneModules(entry.modules);

    const foreignMarkup = entry.foreignMarkup;
    if (Lists.isNotEmpty(foreignMarkup)) {
      syndEntry.foreignMarkup = foreignMarkup;
    }

    syndEntry.title = entry.title;

    // Only a single alternate link becomes THE link.
    const alternateLinks = entry.alternateLinks;
    if (Lists.sizeIs(alternateLinks, 1)) {
      syndEntry.link = alternateLinks[0].hrefResolved;
    }

    const syndEnclosures: SyndEnclosure[] = [];
    const otherLinks = entry.otherLinks;
    if (Lists.isNotEmpty(otherLinks)) {
      for (const thisLink of otherLinks) {
        if (thisLink.rel === 'enclosure') {
          syndEnclosures.push(this.createSyndEnclosure(entry, thisLink));
        }
      }
    }
    syndEntry.enclosures = syndEnclosures;

    const syndLinks: SyndLink[] = [];
    if (Lists.isNotEmpty(alternateLinks)) {
      syndLinks.push(...this.createSyndLinks(alternateLinks));
    }
    if (Lists.isNotEmpty(otherLinks)) {
      syndLinks.push(...this.createSyndLinks(otherLinks));
    }
    syndEntry.links = syndLinks;

    const id = entry.id;
    if (id !== null) {
      syndEntry.uri = id;
    } else {
      syndEntry.uri = syndEntry.link;
    }

    const summary = entry.summary;
    if (summary !== null) {
      const sContent = new SyndContent();
      sContent.type = summary.type;
      sContent.value = summary.value;
      syndEntry.description = sContent;
    }

    const contents = entry.contents;
    if (Lists.isNotEmpty(contents)) {
      const sContents: SyndContent[] = [];
      for (const content of contents) {
        const sContent = new SyndContent();
        sContent.type = content.type;
        sContent.value = content.value;
        sContent.mode = content.mode;
        sContents.push(sContent);
      }
      syndEntry.contents = sContents;
    }

    const authors = entry.authors;
    if (Lists.isNotEmpty(authors)) {
      syndEntry.authors = ConverterForAtom03.createSyndPersons(authors);
      syndEntry.author = syndEntry.authors[0].name;
    }

    let date = entry.modified;
    if (date === null) {
      date = Alternatives.firstNotNull(entry.issued, entry.created);
    }

    if (date !== null) {
      syndEntry.publishedDate = date;
    }

    return syndEntry;
  }

  createSyndEnclosure(entry: Entry, link: Link): SyndEnclosure {
    const syndEncl = new SyndEnclosure();
    syndEncl.url = link.hrefResolved;
    syndEncl.type = link.type;
    syndEncl.length = link.length;
    return syndEncl;
  }

  createRealFeed(syndFeed: SyndFeed): WireFeed {
    const aFeed = new Feed(this.getType());
    aFeed.modules = ModuleUtils.cloneModules(syndFeed.modules);

    aFeed.encoding = syndFeed.encoding;
    aFeed.styleSheet = syndFeed.styleSheet;

    aFeed.id = syndFeed.uri;

    const sTitle = syndFeed.titleEx;
    if (sTitle !== null) {
      aFeed.titleEx = ConverterForAtom03.createAtomTitle(sTitle);
    }

    const alternateLinks: Link[] = [];
    const otherLinks: Link[] = [];

    for (const syndLink of syndFeed.links) {
      const link = this.createAtomLink(syndLink);
      const rel = link.rel;
      if (Strings.isBlank(rel) || rel === 'alternate') {
        alternateLinks.push(link);
      } else {
        otherLinks.push(link);
      }
    }
    const sLink = syndFeed.link;
    if (alternateLinks.length === 0 && sLink !== null) {
      const link = new Link();
      link.rel = 'alternate';
      link.href = sLink;
      alternateLinks.push(link);
    }

    if (alternateLinks.length > 0) {
      aFeed.alternateLinks = alternateLinks;
    }
    if (otherLinks.length > 0) {
      aFeed.otherLinks = otherLinks;
    }

    const sDesc = syndFeed.description;
    if (sDesc !== null) {
      const tagline = new Content();
      tagline.value = sDesc;
      aFeed.tagline = tagline;
    }

    aFeed.language = syndFeed.language;

    const authors = syndFeed.authors;
    if (Lists.isNotEmpty(authors)) {
      aFeed.authors = ConverterForAtom03.createAtomPersons(authors);
    }

    aFeed.copyright = syndFeed.copyright;

    aFeed.modified = syndFeed.publishedDate;

    aFeed.entries = this.createAtomEntries(syndFeed.entries);

    return aFeed;
  }

  // Type and mode are only set when present: Content.mode rejects null.
  private static createAtomTitle(sTitle: SyndContent): Content {
    const title = new Content();
    if (sTitle.type !== null) {
      title.type = sTitle.type;
    }
    if (sTitle.mode !== null) {
      title.mode = sTitle.mode;
    }
    title.value = sTitle.value;
    return title;
  }

  static createAtomPersons(sPersons: SyndPerson[]): SyndPerson[] {
    const persons: SyndPerson[] = [];
    for (const sPerson of sPersons) {
      const person = new Person();
      person.name = sPerson.name;
      person.uri = sPerson.uri;
      person.email = sPerson.email;
      person.modules = sPerson.modules;
      persons.push(person);
    }
    return persons;
  }

  static createSyndPersons(aPersons: SyndPerson[]): SyndPerson[] {
    const persons: SyndPerson[] = [];
    for (const person2 of aPersons) {
      const person = new SyndPerson();
      person.name = person2.name;
      person.uri = person2.uri;
      person.email = person2.email;
      person.modules = person2.modules;
      persons.push(person);
    }
    return persons;
  }

  protected createAtomEntries(syndEntries: SyndEntry[]): Entry[] {
    const atomEntries: Entry[] = [];
    for (const syndEntry of syndEntries) {
      atomEntries.push(this.createAtomEntry(syndEntry));
    }
    return atomEntries;
  }

  protected createAtomEntry(sEntry: SyndEntry): Entry {
    const aEntry = new Entry();
    aEntry.modules = ModuleUtils.cloneModules(sEntry.modules);

    aEntry.id = sEntry.uri;

    const sTitle = sEntry.titleEx;
    if (sTitle !== null) {
      aEntry.titleEx = ConverterForAtom03.createAtomTitle(sTitle);
    }

    const alternateLinks: Link[] = [];
    const otherLinks: Link[] = [];

    for (const syndLink of sEntry.links) {
      const link = this.createAtomLink(syndLink);
      const rel = link.rel;
      if (Strings.isBlank(rel) || rel === 'alternate') {
        alternateLinks.push(link);
      } else {
        otherLinks.push(link);
      }
    }
    const sLink = sEntry.link;
    if (alternateLinks.length === 0 && sLink !== null) {
      const link = new Link();
      link.rel = 'alternate';
      link.href = sLink;
      alternateLinks.push(link);
    }

    for (const syndEnclosure of sEntry.enclosures) {
      otherLinks.push(this.createAtomEnclosure(syndEnclosure));
    }

    if (alternateLinks.length > 0) {
      aEntry.alternateLinks = alternateLinks;
    }
    if (otherLinks.length > 0) {
      aEntry.otherLinks = otherLinks;
    }

    const sContent = sEntry.description;
    if (sContent !== null) {
      const content = new Content();
      content.type = sContent.type;
      content.value = sContent.value;
      content.mode = Content.ESCAPED;
      aEntry.summary = content;
    }

    const contents = sEntry.contents;
    if (contents.length > 0) {
      const aContents: Content[] = [];
      for (const syndContent of contents) {
        const content = new Content();
        content.type = syndContent.type;
        content.value = syndContent.value;
        content.mode = syndContent.mode;
        aContents.push(content);
      }
      aEntry.contents = aContents;
    }

    const sAuthors = sEntry.authors;
    const author = sEntry.author;
    if (Lists.isNotEmpty(sAuthors)) {
      aEntry.authors = ConverterForAtom03.createAtomPersons(sAuthors);
    } else if (author !== null) {
      const person = new Person();
      person.name = author;
      aEntry.authors = [person];
    }

    aEntry.modified = sEntry.publishedDate;
    aEntry.issued = sEntry.publishedDate;

    return aEntry;
  }

  createAtomLink(syndLink: SyndLink): Link {
    const link = new Link();
    link.rel = syndLink.rel;
    link.type = syndLink.type;
    link.href = syndLink.href;
    link.title = syndLink.title;
    return link;
  }

  createAtomEnclosure(syndEnclosure: SyndEnclosure): Link {
    const link = new Link();
    link.rel = 'enclosure';
    link.type = syndEnclosure.type;
    link.href = syndEnclosure.url;
    link.length = syndEnclosure.length;
    return link;
  }
}
