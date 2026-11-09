// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForAtom10.java (Apache-2.0)
import { Lists } from '../../../utils/Lists';
import { Strings } from '../../../utils/Strings';
import { Category } from '../../atom/Category';
import { Content } from '../../atom/Content';
import { Entry } from '../../atom/Entry';
import { Feed } from '../../atom/Feed';
import { Link } from '../../atom/Link';
import { Person } from '../../atom/Person';
import { ModuleUtils } from '../../module/Module';
import { WireFeed } from '../../WireFeed';
import { Converter } from '../Converter';
import { SyndCategory } from '../SyndCategory';
import { SyndContent } from '../SyndContent';
import { SyndEnclosure } from '../SyndEnclosure';
import { SyndEntry } from '../SyndEntry';
import { SyndFeed } from '../SyndFeed';
import { SyndImage } from '../SyndImage';
import { SyndLink } from '../SyndLink';
import { ConverterForAtom03 } from './ConverterForAtom03';

export class ConverterForAtom10 implements Converter {
  private readonly type: string;

  constructor(type: string = 'atom_1.0') {
    this.type = type;
  }

  getType(): string {
    return this.type;
  }

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void {
    const aFeed = feed as Feed;

    syndFeed.modules = ModuleUtils.cloneModules(aFeed.modules);

    const foreignMarkup = feed.foreignMarkup;
    if (foreignMarkup.length > 0) {
      syndFeed.foreignMarkup = foreignMarkup;
    }

    syndFeed.encoding = aFeed.encoding;
    syndFeed.styleSheet = aFeed.styleSheet;

    const logo = aFeed.logo;
    if (logo !== null) {
      const image = new SyndImage();
      image.url = logo;
      syndFeed.image = image;
    }

    const icon = aFeed.icon;
    if (icon !== null) {
      const image = new SyndImage();
      image.url = icon;
      syndFeed.icon = image;
    }

    syndFeed.uri = aFeed.id;

    const aTitle = aFeed.titleEx;
    if (aTitle !== null) {
      syndFeed.titleEx = this.createSyndContent(aTitle);
    }

    const aSubtitle = aFeed.subtitle;
    if (aSubtitle !== null) {
      syndFeed.descriptionEx = this.createSyndContent(aSubtitle);
    }

    // THE link is the first "self" link, else the first alternate link.
    const self = aFeed.otherLinks.find((l: Link) => l.rel === 'self');
    syndFeed.link = self === undefined ? null : self.hrefResolved;

    const alternateLinks = aFeed.alternateLinks;
    if (Lists.isNotEmpty(alternateLinks) && syndFeed.link === null) {
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

    syndFeed.entries = this.createSyndEntries(aFeed, aFeed.entries, syndFeed.isPreservingWireFeed());

    // Core Atom author/rights/updated elements have precedence over the DC equivalents.

    const authors = aFeed.authors;
    if (Lists.isNotEmpty(authors)) {
      syndFeed.authors = ConverterForAtom03.createSyndPersons(authors);
    }

    const contributors = aFeed.contributors;
    if (Lists.isNotEmpty(contributors)) {
      syndFeed.contributors = ConverterForAtom03.createSyndPersons(contributors);
    }

    const rights = aFeed.rights;
    if (rights !== null) {
      syndFeed.copyright = rights;
    }

    const date = aFeed.updated;
    if (date !== null) {
      syndFeed.publishedDate = date;
    }
  }

  protected createSyndLinks(atomLinks: Link[]): SyndLink[] {
    return atomLinks.map((atomLink: Link) => this.createSyndLink(atomLink));
  }

  protected createSyndEntries(feed: Feed, atomEntries: Entry[], preserveWireItems: boolean): SyndEntry[] {
    return atomEntries.map((atomEntry: Entry) => this.createSyndEntry(feed, atomEntry, preserveWireItems));
  }

  protected createSyndEntry(feed: Feed, entry: Entry, preserveWireItem: boolean): SyndEntry {
    const syndEntry = new SyndEntry();
    if (preserveWireItem) {
      syndEntry.wireEntry = entry;
    }
    syndEntry.modules = ModuleUtils.cloneModules(entry.modules);

    const foreignMarkup = entry.foreignMarkup;
    if (foreignMarkup.length > 0) {
      syndEntry.foreignMarkup = foreignMarkup;
    }

    const eTitle = entry.titleEx;
    if (eTitle !== null) {
      syndEntry.titleEx = this.createSyndContent(eTitle);
    }

    const summary = entry.summary;
    if (summary !== null) {
      syndEntry.description = this.createSyndContent(summary);
    }

    const contents = entry.contents;
    if (Lists.isNotEmpty(contents)) {
      syndEntry.contents = contents.map((content: Content) => this.createSyndContent(content));
    }

    const authors = entry.authors;
    if (Lists.isNotEmpty(authors)) {
      syndEntry.authors = ConverterForAtom03.createSyndPersons(authors);
      syndEntry.author = syndEntry.authors[0].name;
    }

    const contributors = entry.contributors;
    if (Lists.isNotEmpty(contributors)) {
      syndEntry.contributors = ConverterForAtom03.createSyndPersons(contributors);
    }

    let date = entry.published;
    if (date !== null) {
      syndEntry.publishedDate = date;
    }

    date = entry.updated;
    if (date !== null) {
      syndEntry.updatedDate = date;
    }

    syndEntry.categories = entry.categories.map((category: Category) => {
      const syndCategory = new SyndCategory();
      syndCategory.name = category.term;
      syndCategory.taxonomyUri = category.schemeResolved;
      syndCategory.label = category.label;
      return syndCategory;
    });

    const alternateLinks = entry.alternateLinks;
    if (Lists.isNotEmpty(alternateLinks)) {
      syndEntry.link = alternateLinks[0].hrefResolved;
    }

    const syndEnclosures: SyndEnclosure[] = [];
    const otherLinks = entry.otherLinks;
    if (Lists.isNotEmpty(otherLinks)) {
      for (const link of otherLinks) {
        if (link.rel === 'enclosure') {
          syndEnclosures.push(this.createSyndEnclosure(feed, entry, link));
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

    const source = entry.source;
    if (source !== null) {
      syndEntry.source = new SyndFeed(source);
    }

    return syndEntry;
  }

  createSyndEnclosure(feed: Feed, entry: Entry, link: Link): SyndEnclosure {
    const syndEncl = new SyndEnclosure();
    syndEncl.url = link.hrefResolved;
    syndEncl.type = link.type;
    syndEncl.length = link.length;
    return syndEncl;
  }

  createAtomEnclosure(syndEnclosure: SyndEnclosure): Link {
    const link = new Link();
    link.rel = 'enclosure';
    link.type = syndEnclosure.type;
    link.href = syndEnclosure.url;
    link.length = syndEnclosure.length;
    return link;
  }

  createSyndLink(link: Link): SyndLink {
    const syndLink = new SyndLink();
    syndLink.rel = link.rel;
    syndLink.type = link.type;
    syndLink.href = link.hrefResolved;
    syndLink.hreflang = link.hreflang;
    syndLink.length = link.length;
    syndLink.title = link.title;
    return syndLink;
  }

  createAtomLink(syndLink: SyndLink): Link {
    const link = new Link();
    link.rel = syndLink.rel;
    link.type = syndLink.type;
    link.href = syndLink.href;
    link.hreflang = syndLink.hreflang;
    link.length = syndLink.length;
    link.title = syndLink.title;
    return link;
  }

  createRealFeed(syndFeed: SyndFeed): WireFeed {
    const aFeed = new Feed(this.getType());
    aFeed.modules = ModuleUtils.cloneModules(syndFeed.modules);

    aFeed.encoding = syndFeed.encoding;
    aFeed.styleSheet = syndFeed.styleSheet;

    aFeed.id = syndFeed.uri;

    const sTitle = syndFeed.titleEx;
    if (sTitle !== null) {
      aFeed.titleEx = this.createAtomContent(sTitle);
    }

    const sDesc = syndFeed.descriptionEx;
    if (sDesc !== null) {
      aFeed.subtitle = this.createAtomContent(sDesc);
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

    const aCats = this.createAtomCategories(syndFeed.categories);
    if (aCats.length > 0) {
      aFeed.categories = aCats;
    }

    const authors = syndFeed.authors;
    if (Lists.isNotEmpty(authors)) {
      aFeed.authors = ConverterForAtom03.createAtomPersons(authors);
    }

    const contributors = syndFeed.contributors;
    if (Lists.isNotEmpty(contributors)) {
      aFeed.contributors = ConverterForAtom03.createAtomPersons(contributors);
    }

    const image = syndFeed.image;
    if (image !== null) {
      aFeed.logo = image.url;
    }

    const icon = syndFeed.icon;
    if (icon !== null) {
      aFeed.icon = icon.url;
    }

    aFeed.rights = syndFeed.copyright;

    aFeed.updated = syndFeed.publishedDate;

    aFeed.entries = this.createAtomEntries(syndFeed.entries);

    const foreignMarkup = syndFeed.foreignMarkup;
    if (foreignMarkup.length > 0) {
      aFeed.foreignMarkup = foreignMarkup;
    }

    return aFeed;
  }

  protected createSyndContent(content: Content): SyndContent {
    const sContent = new SyndContent();
    sContent.type = content.type;
    sContent.value = content.value;
    return sContent;
  }

  protected createAtomEntries(syndEntries: SyndEntry[]): Entry[] {
    return syndEntries.map((syndEntry: SyndEntry) => this.createAtomEntry(syndEntry));
  }

  protected createAtomContent(sContent: SyndContent): Content {
    const content = new Content();
    content.type = sContent.type;
    content.value = sContent.value;
    return content;
  }

  protected createAtomContents(syndContents: SyndContent[]): Content[] {
    return syndContents.map((syndContent: SyndContent) => this.createAtomContent(syndContent));
  }

  private createAtomCategories(sCats: SyndCategory[]): Category[] {
    return sCats.map((sCat: SyndCategory) => {
      const aCat = new Category();
      aCat.term = sCat.name;
      aCat.label = sCat.label;
      aCat.scheme = sCat.taxonomyUri;
      return aCat;
    });
  }

  protected createAtomEntry(sEntry: SyndEntry): Entry {
    const aEntry = new Entry();

    aEntry.modules = ModuleUtils.cloneModules(sEntry.modules);

    aEntry.id = sEntry.uri;

    const sTitle = sEntry.titleEx;
    if (sTitle !== null) {
      aEntry.titleEx = this.createAtomContent(sTitle);
    }

    const sDescription = sEntry.description;
    if (sDescription !== null) {
      aEntry.summary = this.createAtomContent(sDescription);
    }

    const alternateLinks: Link[] = [];
    const otherLinks: Link[] = [];
    // Enclosures are added as links only when no link already has rel="enclosure", so they are not duplicated.
    let linkRelEnclosureExists = false;

    for (const syndLink of sEntry.links) {
      const link = this.createAtomLink(syndLink);
      const sRel = syndLink.rel;
      if (sRel === 'enclosure') {
        linkRelEnclosureExists = true;
      }
      if (Strings.isBlank(link.rel) || sRel === 'alternate') {
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

    if (!linkRelEnclosureExists) {
      for (const syndEnclosure of sEntry.enclosures) {
        otherLinks.push(this.createAtomEnclosure(syndEnclosure));
      }
    }

    if (alternateLinks.length > 0) {
      aEntry.alternateLinks = alternateLinks;
    }
    if (otherLinks.length > 0) {
      aEntry.otherLinks = otherLinks;
    }

    const aCats = this.createAtomCategories(sEntry.categories);
    if (aCats.length > 0) {
      aEntry.categories = aCats;
    }

    aEntry.contents = this.createAtomContents(sEntry.contents);

    const authors = sEntry.authors;
    const author = sEntry.author;
    if (Lists.isNotEmpty(authors)) {
      aEntry.authors = ConverterForAtom03.createAtomPersons(authors);
    } else if (author !== null) {
      const person = new Person();
      person.name = author;
      aEntry.authors = [person];
    }

    const contributors = sEntry.contributors;
    if (Lists.isNotEmpty(contributors)) {
      aEntry.contributors = ConverterForAtom03.createAtomPersons(contributors);
    }

    aEntry.published = sEntry.publishedDate;

    // Atom requires an updated date: fall back to the published date (ROME issues #41, #42).
    if (sEntry.updatedDate !== null) {
      aEntry.updated = sEntry.updatedDate;
    } else {
      aEntry.updated = sEntry.publishedDate;
    }

    const foreignMarkup = sEntry.foreignMarkup;
    if (foreignMarkup.length > 0) {
      aEntry.foreignMarkup = foreignMarkup;
    }

    const sSource = sEntry.source;
    if (sSource !== null) {
      aEntry.source = sSource.createWireFeed(this.getType()) as Feed;
    }
    return aEntry;
  }
}
