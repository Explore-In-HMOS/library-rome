// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS094.java (Apache-2.0)
import { WireFeed } from '../../WireFeed';
import { DCModule } from '../../module/DCModule';
import { Channel } from '../../rss/Channel';
import { Guid } from '../../rss/Guid';
import { Item } from '../../rss/Item';
import { SyndEntry } from '../SyndEntry';
import { SyndFeed } from '../SyndFeed';
import { ConverterForRSS093 } from './ConverterForRSS093';

export class ConverterForRSS094 extends ConverterForRSS093 {
  constructor(type: string = 'rss_0.94') {
    super(type);
  }

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void {
    const channel = feed as Channel;
    super.copyInto(channel, syndFeed);
    if (channel.categories.length > 0) {
      syndFeed.categories =
        this.distinctCategories(this.createSyndCategories(channel.categories).concat(syndFeed.categories));
    }
  }

  protected createSyndEntry(item: Item, preserveWireItem: boolean): SyndEntry {
    const syndEntry = super.createSyndEntry(item, preserveWireItem);
    const author = item.author;
    if (author !== null) {
      const dc = syndEntry.getModule(DCModule.URI) as DCModule;
      if (!dc.creators.includes(author)) {
        const s = new Set<string>(dc.creators);
        s.add(author);
        dc.creators = Array.from(s);
      }
    }
    const guid = item.guid;
    const itemLink = item.link;
    if (guid !== null) {
      syndEntry.uri = guid.value;
      if (itemLink === null && guid.permaLink) {
        syndEntry.link = guid.value;
      }
    } else {
      syndEntry.uri = itemLink;
    }
    return syndEntry;
  }

  protected createChannel(type: string, syndFeed: SyndFeed): Channel {
    const channel = super.createChannel(type, syndFeed);
    const cats = syndFeed.categories;
    if (cats.length > 0) {
      channel.categories = this.createRSSCategories(cats);
    }
    return channel;
  }

  protected createRSSItem(sEntry: SyndEntry): Item {
    const item = super.createRSSItem(sEntry);
    if (sEntry.authors.length > 0) {
      item.author = sEntry.authors[0].email;
    }
    let guid: Guid | null = null;
    if (sEntry.uri !== null) {
      guid = new Guid();
      guid.permaLink = false;
      guid.value = sEntry.uri;
    } else if (sEntry.link !== null) {
      guid = new Guid();
      guid.permaLink = true;
      guid.value = sEntry.link;
    }
    item.guid = guid;
    const comments = sEntry.findRelatedLink('comments');
    if (comments !== null && (comments.type === null || comments.type.endsWith('html'))) {
      item.comments = comments.href;
    }
    return item;
  }
}
