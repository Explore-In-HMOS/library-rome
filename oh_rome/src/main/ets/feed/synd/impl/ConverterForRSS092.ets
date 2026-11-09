// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS092.java (Apache-2.0)
import { Category } from '../../rss/Category';
import { Enclosure } from '../../rss/Enclosure';
import { Item } from '../../rss/Item';
import { SyndCategory } from '../SyndCategory';
import { SyndEnclosure } from '../SyndEnclosure';
import { SyndEntry } from '../SyndEntry';
import { ConverterForRSS091Userland } from './ConverterForRSS091Userland';

export class ConverterForRSS092 extends ConverterForRSS091Userland {
  constructor(type: string = 'rss_0.92') {
    super(type);
  }

  protected createSyndEntry(item: Item, preserveWireItem: boolean): SyndEntry {
    const syndEntry = super.createSyndEntry(item, preserveWireItem);
    if (item.categories.length > 0) {
      syndEntry.categories =
        this.distinctCategories(this.createSyndCategories(item.categories).concat(syndEntry.categories));
    }
    if (item.enclosures.length > 0) {
      syndEntry.enclosures = this.createSyndEnclosures(item.enclosures);
    }
    return syndEntry;
  }

  // Java's LinkedHashSet<SyndCategory>: first occurrence wins, equality over name, taxonomyUri and label.
  protected distinctCategories(categories: SyndCategory[]): SyndCategory[] {
    const seen = new Set<string>();
    return categories.filter((c: SyndCategory) => {
      const key = JSON.stringify([c.name, c.taxonomyUri, c.label]);
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    });
  }

  protected createSyndCategories(rssCats: Category[]): SyndCategory[] {
    return rssCats.map((rssCat: Category) => {
      const sCat = new SyndCategory();
      sCat.taxonomyUri = rssCat.domain;
      sCat.name = rssCat.value;
      return sCat;
    });
  }

  protected createSyndEnclosures(enclosures: Enclosure[]): SyndEnclosure[] {
    return enclosures.map((enc: Enclosure) => {
      const sEnc = new SyndEnclosure();
      sEnc.url = enc.url;
      sEnc.type = enc.type;
      sEnc.length = enc.length;
      return sEnc;
    });
  }

  protected createRSSItem(sEntry: SyndEntry): Item {
    const item = super.createRSSItem(sEntry);
    if (sEntry.categories.length > 0) {
      item.categories = this.createRSSCategories(sEntry.categories);
    }
    if (sEntry.enclosures.length > 0) {
      item.enclosures = this.createEnclosures(sEntry.enclosures);
    }
    return item;
  }

  protected createRSSCategories(sCats: SyndCategory[]): Category[] {
    return sCats.map((sCat: SyndCategory) => {
      const cat = new Category();
      cat.domain = sCat.taxonomyUri;
      cat.value = sCat.name;
      return cat;
    });
  }

  protected createEnclosures(sEnclosures: SyndEnclosure[]): Enclosure[] {
    return sEnclosures.map((sEnc: SyndEnclosure) => {
      const enc = new Enclosure();
      enc.url = sEnc.url;
      enc.type = sEnc.type;
      enc.length = sEnc.length;
      return enc;
    });
  }
}
