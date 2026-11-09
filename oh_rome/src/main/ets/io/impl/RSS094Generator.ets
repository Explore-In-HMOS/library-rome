// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS094Generator.java (Apache-2.0)
import { Attribute, Element } from '../../xml/Dom';
import { Item } from '../../feed/rss/Item';
import { RSS093Generator } from './RSS093Generator';

export class RSS094Generator extends RSS093Generator {
  constructor(type: string = 'rss_0.94', version: string = '0.94') {
    super(type, version);
  }

  protected populateItem(item: Item, eItem: Element, index: number): void {
    super.populateItem(item, eItem, index);
    const description = item.description;
    if (description !== null && description.type !== null) {
      eItem.getChild('description', this.getFeedNamespace())!.setAttribute(new Attribute('type', description.type));
    }
    eItem.removeChild('expirationDate', this.getFeedNamespace());
  }
}
