// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/{SyndEntry,SyndEntryImpl}.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { Dates } from '../../utils/Dates';
import { Lists } from '../../utils/Lists';
import { Strings } from '../../utils/Strings';
import { DCModule } from '../module/DCModule';
import { Extendable, Module, ModuleUtils } from '../module/Module';
import { SyndCategory } from './SyndCategory';
import { SyndContent } from './SyndContent';
import { SyndEnclosure } from './SyndEnclosure';
import { SyndFeed } from './SyndFeed';
import { SyndLink } from './SyndLink';
import { SyndPerson } from './SyndPerson';

export class SyndEntry implements Extendable {
  uri: string | null = null;
  link: string | null = null;
  comments: string | null = null;
  private _updatedDate: Date | null = null;
  titleEx: SyndContent | null = null;
  description: SyndContent | null = null;
  links: SyndLink[] = [];
  contents: SyndContent[] = [];
  enclosures: SyndEnclosure[] = [];
  authors: SyndPerson[] = [];
  contributors: SyndPerson[] = [];
  categories: SyndCategory[] = [];
  source: SyndFeed | null = null;
  foreignMarkup: Element[] = [];
  wireEntry: Object | null = null;
  private moduleList: Module[] = [];

  get updatedDate(): Date | null {
    return Dates.copy(this._updatedDate);
  }

  // Throws on null, as Java's new Date(updatedDate.getTime()) does.
  set updatedDate(updatedDate: Date | null) {
    this._updatedDate = new Date(updatedDate!.getTime());
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

  // First author's name, else the DC creator, else ''.
  get author(): string | null {
    const author: string | null = Lists.isNotEmpty(this.authors) ? this.authors[0].name : this.dcModule().creator;
    return author === null ? '' : author;
  }

  // Only sets the DC creator when it is still empty.
  set author(author: string | null) {
    const dcModule = this.dcModule();
    if (Strings.isEmpty(dcModule.creator)) {
      dcModule.creator = author;
    }
  }

  findRelatedLink(relation: string): SyndLink | null {
    for (const link of this.links) {
      if (relation === link.rel) {
        return link;
      }
    }
    return null;
  }

  private dcModule(): DCModule {
    return this.getModule(DCModule.URI) as DCModule;
  }
}
