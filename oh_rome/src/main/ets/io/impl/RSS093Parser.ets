// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS093Parser.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { Item } from '../../feed/rss/Item';
import { DateParser } from './DateParser';
import { RSS092Parser } from './RSS092Parser';

export class RSS093Parser extends RSS092Parser {
  constructor(type: string = 'rss_0.93') {
    super(type);
  }

  protected getRSSVersion(): string {
    return '0.93';
  }

  protected parseItem(rssRoot: Element, eItem: Element): Item {
    const item = super.parseItem(rssRoot, eItem);
    const pubDate = eItem.getChild('pubDate', this.getRSSNamespace());
    if (pubDate !== null) {
      item.pubDate = DateParser.parseDate(pubDate.getText());
    }
    const expirationDate = eItem.getChild('expirationDate', this.getRSSNamespace());
    if (expirationDate !== null) {
      item.expirationDate = DateParser.parseDate(expirationDate.getText());
    }
    const description = eItem.getChild('description', this.getRSSNamespace());
    if (description !== null) {
      const type = description.getAttributeValue('type');
      if (type !== null) {
        item.description!.type = type;
      }
    }
    return item;
  }
}
