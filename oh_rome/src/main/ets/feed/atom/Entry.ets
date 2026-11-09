// Ported from ROME rome/src/main/java/com/rometools/rome/feed/atom/Entry.java (Apache-2.0)
import { Dates } from '../../utils/Dates';
import { Element } from '../../xml/Dom';
import { Extendable, Module, ModuleUtils } from '../module/Module';
import { SyndPerson } from '../synd/SyndPerson';
import { Category } from './Category';
import { Content } from './Content';
import { Feed } from './Feed';
import { Link } from './Link';

export class Entry implements Extendable {
  summary: Content | null = null;
  titleEx: Content | null = null;
  private _created: Date | null = null;
  private _published: Date | null = null;
  private _updated: Date | null = null;
  source: Feed | null = null;
  alternateLinks: Link[] = [];
  authors: SyndPerson[] = [];
  categories: Category[] = [];
  contents: Content[] = [];
  contributors: SyndPerson[] = [];
  foreignMarkup: Element[] = [];
  modules: Module[] = [];
  otherLinks: Link[] = [];
  id: string | null = null;
  rights: string | null = null;
  xmlBase: string | null = null;

  get title(): string | null {
    return this.titleEx === null ? null : this.titleEx.value;
  }

  set title(title: string | null) {
    if (this.titleEx === null) {
      this.titleEx = new Content();
    }
    this.titleEx.value = title;
  }

  // Atom 0.3 only.
  get created(): Date | null {
    return Dates.copy(this._created);
  }

  set created(created: Date | null) {
    this._created = Dates.copy(created);
  }

  get published(): Date | null {
    return Dates.copy(this._published);
  }

  set published(published: Date | null) {
    this._published = Dates.copy(published);
  }

  // Atom 0.3 name of published.
  get issued(): Date | null {
    return Dates.copy(this._published);
  }

  set issued(issued: Date | null) {
    this._published = Dates.copy(issued);
  }

  get updated(): Date | null {
    return Dates.copy(this._updated);
  }

  set updated(updated: Date | null) {
    this._updated = Dates.copy(updated);
  }

  // Atom 0.3 name of updated.
  get modified(): Date | null {
    return Dates.copy(this._updated);
  }

  set modified(modified: Date | null) {
    this._updated = Dates.copy(modified);
  }

  get mediaEntry(): boolean {
    for (const link of this.otherLinks) {
      if (link.rel === 'edit-media') {
        return true;
      }
    }
    return false;
  }

  getModule(uri: string): Module | null {
    return ModuleUtils.getModule(this.modules, uri);
  }

  findRelatedLink(relation: string): Link | null {
    for (const link of this.otherLinks) {
      if (relation === link.rel) {
        return link;
      }
    }
    return null;
  }
}
