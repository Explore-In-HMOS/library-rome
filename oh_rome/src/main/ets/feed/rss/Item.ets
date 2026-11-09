// Ported from ROME rome/src/main/java/com/rometools/rome/feed/rss/Item.java (Apache-2.0)
import { Dates } from '../../utils/Dates';
import { Element } from '../../xml/Dom';
import { Extendable, Module, ModuleUtils } from '../module/Module';
import { Category } from './Category';
import { Content } from './Content';
import { Description } from './Description';
import { Enclosure } from './Enclosure';
import { Guid } from './Guid';
import { Source } from './Source';

export class Item implements Extendable {
  title: string | null = null;
  link: string | null = null;
  uri: string | null = null;
  description: Description | null = null;
  content: Content | null = null;
  source: Source | null = null;
  enclosures: Enclosure[] = [];
  categories: Category[] = [];
  guid: Guid | null = null;
  comments: string | null = null;
  author: string | null = null;
  private _pubDate: Date | null = null;
  private _expirationDate: Date | null = null;
  modules: Module[] = [];
  foreignMarkup: Element[] = [];

  getModule(uri: string): Module | null {
    return ModuleUtils.getModule(this.modules, uri);
  }

  get pubDate(): Date | null {
    return Dates.copy(this._pubDate);
  }

  set pubDate(pubDate: Date | null) {
    this._pubDate = Dates.copy(pubDate);
  }

  get expirationDate(): Date | null {
    return Dates.copy(this._expirationDate);
  }

  set expirationDate(expirationDate: Date | null) {
    this._expirationDate = Dates.copy(expirationDate);
  }
}
