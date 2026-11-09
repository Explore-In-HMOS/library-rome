// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS090.java (Apache-2.0)
import { WireFeed } from '../../WireFeed';
import { ModuleUtils } from '../../module/Module';
import { Channel } from '../../rss/Channel';
import { Image } from '../../rss/Image';
import { Item } from '../../rss/Item';
import { Source } from '../../rss/Source';
import { Converter } from '../Converter';
import { SyndEntry } from '../SyndEntry';
import { SyndFeed } from '../SyndFeed';
import { SyndImage } from '../SyndImage';

export class ConverterForRSS090 implements Converter {
  private readonly type: string;

  constructor(type: string = 'rss_0.9') {
    this.type = type;
  }

  getType(): string {
    return this.type;
  }

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void {
    syndFeed.modules = ModuleUtils.cloneModules(feed.modules);
    if (feed.foreignMarkup.length > 0) {
      syndFeed.foreignMarkup = feed.foreignMarkup;
    }
    syndFeed.styleSheet = feed.styleSheet;
    syndFeed.encoding = feed.encoding;
    const channel = feed as Channel;
    syndFeed.title = channel.title;
    syndFeed.link = channel.link;
    syndFeed.description = channel.description;
    if (channel.image !== null) {
      syndFeed.image = this.createSyndImage(channel.image);
    }
    syndFeed.entries = this.createSyndEntries(channel.items, syndFeed.isPreservingWireFeed());
  }

  protected createSyndImage(rssImage: Image): SyndImage {
    const syndImage = new SyndImage();
    syndImage.title = rssImage.title;
    syndImage.url = rssImage.url;
    syndImage.link = rssImage.link;
    syndImage.width = rssImage.width;
    syndImage.height = rssImage.height;
    return syndImage;
  }

  protected createSyndEntries(rssItems: Item[], preserveWireItems: boolean): SyndEntry[] {
    return rssItems.map((item: Item) => this.createSyndEntry(item, preserveWireItems));
  }

  protected createSyndEntry(item: Item, preserveWireItem: boolean): SyndEntry {
    const syndEntry = new SyndEntry();
    if (preserveWireItem) {
      syndEntry.wireEntry = item;
    }
    syndEntry.modules = ModuleUtils.cloneModules(item.modules);
    if (item.foreignMarkup.length > 0) {
      syndEntry.foreignMarkup = item.foreignMarkup;
    }
    syndEntry.uri = item.uri;
    syndEntry.link = item.link;
    syndEntry.title = item.title;
    syndEntry.source = this.createSyndSource(item.source);
    return syndEntry;
  }

  // Java overloads createSource for both directions; this is the Source to SyndFeed one.
  protected createSyndSource(source: Source | null): SyndFeed | null {
    if (source === null) {
      return null;
    }
    const feed = new SyndFeed();
    feed.link = source.url;
    feed.uri = source.url;
    feed.title = source.value;
    return feed;
  }

  createRealFeed(syndFeed: SyndFeed): WireFeed {
    return this.createChannel(this.getType(), syndFeed);
  }

  // Java's protected createRealFeed(type, syndFeed).
  protected createChannel(type: string, syndFeed: SyndFeed): Channel {
    const channel = new Channel(type);
    channel.modules = ModuleUtils.cloneModules(syndFeed.modules);
    channel.styleSheet = syndFeed.styleSheet;
    channel.encoding = syndFeed.encoding;
    channel.title = syndFeed.title;
    if (syndFeed.link !== null) {
      channel.link = syndFeed.link;
    } else if (syndFeed.links.length > 0) {
      channel.link = syndFeed.links[0].href;
    }
    channel.description = syndFeed.description;
    if (syndFeed.image !== null) {
      channel.image = this.createRSSImage(syndFeed.image);
    }
    channel.items = this.createRSSItems(syndFeed.entries);
    if (syndFeed.foreignMarkup.length > 0) {
      channel.foreignMarkup = syndFeed.foreignMarkup;
    }
    return channel;
  }

  protected createRSSImage(sImage: SyndImage): Image {
    const image = new Image();
    image.title = sImage.title;
    image.url = sImage.url;
    image.link = sImage.link;
    image.height = sImage.height;
    image.width = sImage.width;
    return image;
  }

  protected createRSSItems(sEntries: SyndEntry[]): Item[] {
    return sEntries.map((entry: SyndEntry) => this.createRSSItem(entry));
  }

  protected createRSSItem(sEntry: SyndEntry): Item {
    const item = new Item();
    item.modules = ModuleUtils.cloneModules(sEntry.modules);
    item.title = sEntry.title;
    item.link = sEntry.link;
    if (sEntry.foreignMarkup.length > 0) {
      item.foreignMarkup = sEntry.foreignMarkup;
    }
    item.source = this.createRSSSource(sEntry.source);
    if (sEntry.uri !== null) {
      item.uri = sEntry.uri;
    }
    return item;
  }

  // Java overloads createSource for both directions; this is the SyndFeed to Source one.
  protected createRSSSource(feed: SyndFeed | null): Source | null {
    if (feed === null) {
      return null;
    }
    const source = new Source();
    source.url = feed.uri;
    source.value = feed.title;
    return source;
  }
}
