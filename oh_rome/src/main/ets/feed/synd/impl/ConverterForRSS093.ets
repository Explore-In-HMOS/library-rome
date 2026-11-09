// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS093.java (Apache-2.0)
import { Item } from '../../rss/Item';
import { SyndEntry } from '../SyndEntry';
import { ConverterForRSS092 } from './ConverterForRSS092';

export class ConverterForRSS093 extends ConverterForRSS092 {
  constructor(type: string = 'rss_0.93') {
    super(type);
  }

  protected createSyndEntry(item: Item, preserveWireItem: boolean): SyndEntry {
    const syndEntry = super.createSyndEntry(item, preserveWireItem);
    const pubDate = item.pubDate;
    if (pubDate !== null && syndEntry.publishedDate === null) {
      syndEntry.publishedDate = pubDate;
    }
    return syndEntry;
  }

  protected createRSSItem(sEntry: SyndEntry): Item {
    const item = super.createRSSItem(sEntry);
    item.pubDate = sEntry.publishedDate;
    return item;
  }
}
