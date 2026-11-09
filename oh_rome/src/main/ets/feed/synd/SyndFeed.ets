// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/{SyndFeed,SyndFeedImpl,SyndCategoryListFacade}.java (Apache-2.0)
import { IllegalArgumentException } from '../../utils/Exceptions';
import { Element } from '../../xml/Dom';
import { DCModule, DCSubject } from '../module/DCModule';
import { Extendable, Module, ModuleUtils } from '../module/Module';
import { WireFeed } from '../WireFeed';
import { plugins } from '../../io/impl/PluginRegistry';
import { SyndCategory } from './SyndCategory';
import { SyndContent } from './SyndContent';
import { SyndEntry } from './SyndEntry';
import { SyndImage } from './SyndImage';
import { SyndLink } from './SyndLink';
import { SyndPerson } from './SyndPerson';

export class SyndFeed implements Extendable {
  feedType: string | null = null;
  encoding: string | null = null;
  uri: string | null = null;
  titleEx: SyndContent | null = null;
  descriptionEx: SyndContent | null = null;
  link: string | null = null;
  webMaster: string | null = null;
  managingEditor: string | null = null;
  docs: string | null = null;
  generator: string | null = null;
  styleSheet: string | null = null;
  links: SyndLink[] = [];
  icon: SyndImage | null = null;
  image: SyndImage | null = null;
  entries: SyndEntry[] = [];
  authors: SyndPerson[] = [];
  contributors: SyndPerson[] = [];
  foreignMarkup: Element[] = [];
  private moduleList: Module[] = [];
  private wireFeed: WireFeed | null = null;
  private preserveWireFeed: boolean = false;

  // Converts the given wire feed with the converter registered for its type; throws for unknown types.
  constructor(feed?: WireFeed, preserveWireFeed?: boolean) {
    if (feed === undefined) {
      return;
    }
    if (preserveWireFeed === true) {
      this.wireFeed = feed;
      this.preserveWireFeed = true;
    }
    this.feedType = feed.feedType;
    const converter = this.feedType === null ? null : plugins().getConverter(this.feedType);
    if (converter === null) {
      throw new IllegalArgumentException(`Invalid feed type [${this.feedType}]`);
    }
    converter.copyInto(feed, this);
  }

  getSupportedFeedTypes(): string[] {
    return plugins().getConverterTypes();
  }

  // Uses this feed's own type when none is given.
  createWireFeed(feedType?: string): WireFeed {
    const type = feedType === undefined ? this.feedType : feedType;
    if (type === null) {
      throw new IllegalArgumentException('Feed type cannot be null');
    }
    const converter = plugins().getConverter(type);
    if (converter === null) {
      throw new IllegalArgumentException(`Invalid feed type [${type}]`);
    }
    return converter.createRealFeed(this);
  }

  originalWireFeed(): WireFeed | null {
    return this.wireFeed;
  }

  isPreservingWireFeed(): boolean {
    return this.preserveWireFeed;
  }

  get title(): string | null {
    return this.titleEx === null ? null : this.titleEx.value;
  }

  set title(title: string | null) {
    if (this.titleEx === null) {
      this.titleEx = new SyndContent();
    }
    this.titleEx.value = title;
  }

  get description(): string | null {
    return this.descriptionEx === null ? null : this.descriptionEx.value;
  }

  set description(description: string | null) {
    if (this.descriptionEx === null) {
      this.descriptionEx = new SyndContent();
    }
    this.descriptionEx.value = description;
  }

  // Always contains a DCModule, added on first read, as in Java.
  get modules(): Module[] {
    if (ModuleUtils.getModule(this.moduleList, DCModule.URI) === null) {
      this.moduleList.push(new DCModule());
    }
    return this.moduleList;
  }

  set modules(modules: Module[]) {
    this.moduleList = modules;
  }

  getModule(uri: string): Module | null {
    return ModuleUtils.getModule(this.modules, uri);
  }

  get publishedDate(): Date | null {
    return this.dcModule().date;
  }

  set publishedDate(publishedDate: Date | null) {
    this.dcModule().date = publishedDate;
  }

  get copyright(): string | null {
    return this.dcModule().rights;
  }

  set copyright(copyright: string | null) {
    this.dcModule().rights = copyright;
  }

  get language(): string | null {
    return this.dcModule().language;
  }

  set language(language: string | null) {
    this.dcModule().language = language;
  }

  get author(): string | null {
    return this.dcModule().creator;
  }

  set author(author: string | null) {
    this.dcModule().creator = author;
  }

  // Feed categories are the DC subjects. Java returns a live view; this returns a copy, so assign to change.
  get categories(): SyndCategory[] {
    return this.dcModule().subjects.map((subject: DCSubject) => {
      const category = new SyndCategory();
      category.name = subject.value;
      category.taxonomyUri = subject.taxonomyUri;
      return category;
    });
  }

  set categories(categories: SyndCategory[]) {
    this.dcModule().subjects = categories.map((category: SyndCategory) => {
      const subject = new DCSubject();
      subject.value = category.name;
      subject.taxonomyUri = category.taxonomyUri;
      return subject;
    });
  }

  private dcModule(): DCModule {
    return this.getModule(DCModule.URI) as DCModule;
  }
}
