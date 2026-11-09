// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS093Generator.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { Enclosure } from '../../feed/rss/Enclosure';
import { Item } from '../../feed/rss/Item';
import { DateParser } from './DateParser';
import { RSS092Generator } from './RSS092Generator';

export class RSS093Generator extends RSS092Generator {
  constructor(type: string = 'rss_0.93', version: string = '0.93') {
    super(type, version);
  }

  protected populateItem(item: Item, eItem: Element, index: number): void {
    super.populateItem(item, eItem, index);
    const pubDate = item.pubDate;
    if (pubDate !== null) {
      eItem.addContent(this.generateSimpleElement('pubDate', DateParser.formatRFC822(pubDate)));
    }
    const expirationDate = item.expirationDate;
    if (expirationDate !== null) {
      eItem.addContent(this.generateSimpleElement('expirationDate', DateParser.formatRFC822(expirationDate)));
    }
  }

  protected getNumberOfEnclosures(enclosures: Enclosure[]): number {
    return enclosures.length;
  }
}
