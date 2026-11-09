// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS091Userland.java (Apache-2.0)
import { WireFeed } from '../../WireFeed';
import { DCModule } from '../../module/DCModule';
import { Channel } from '../../rss/Channel';
import { Content } from '../../rss/Content';
import { Description } from '../../rss/Description';
import { Image } from '../../rss/Image';
import { Item } from '../../rss/Item';
import { SyndContent } from '../SyndContent';
import { SyndEntry } from '../SyndEntry';
import { SyndFeed } from '../SyndFeed';
import { SyndImage } from '../SyndImage';
import { ConverterForRSS090 } from './ConverterForRSS090';

export class ConverterForRSS091Userland extends ConverterForRSS090 {
  constructor(type: string = 'rss_0.91U') {
    super(type);
  }

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void {
    const channel = feed as Channel;
    super.copyInto(channel, syndFeed);
    syndFeed.language = channel.language;
    syndFeed.copyright = channel.copyright;
    syndFeed.docs = channel.docs;
    syndFeed.managingEditor = channel.managingEditor;
    syndFeed.webMaster = channel.webMaster;
    syndFeed.generator = channel.generator;
    const pubDate = channel.pubDate;
    if (pubDate !== null) {
      syndFeed.publishedDate = pubDate;
    } else if (channel.lastBuildDate !== null) {
      syndFeed.publishedDate = channel.lastBuildDate;
    }
    const author = channel.managingEditor;
    if (author !== null) {
      const dc = syndFeed.getModule(DCModule.URI) as DCModule;
      if (!dc.creators.includes(author)) {
        const s = new Set<string>(dc.creators);
        s.add(author);
        dc.creators = Array.from(s);
      }
    }
  }

  protected createItemDescription(sContent: SyndContent): Description {
    const desc = new Description();
    desc.value = sContent.value;
    desc.type = sContent.type;
    return desc;
  }

  protected createRSSImage(sImage: SyndImage): Image {
    const image = super.createRSSImage(sImage);
    image.description = sImage.description;
    return image;
  }

  protected createRSSItem(sEntry: SyndEntry): Item {
    const item = super.createRSSItem(sEntry);
    item.comments = sEntry.comments;
    if (sEntry.description !== null) {
      item.description = this.createItemDescription(sEntry.description);
    }
    if (sEntry.contents.length > 0) {
      const syndContent = sEntry.contents[0];
      const cont = new Content();
      cont.value = syndContent.value;
      cont.type = syndContent.type;
      item.content = cont;
    }
    return item;
  }

  protected createChannel(type: string, syndFeed: SyndFeed): Channel {
    const channel = super.createChannel(type, syndFeed);
    channel.language = syndFeed.language;
    channel.copyright = syndFeed.copyright;
    channel.pubDate = syndFeed.publishedDate;
    channel.docs = syndFeed.docs;
    channel.managingEditor = syndFeed.managingEditor;
    channel.webMaster = syndFeed.webMaster;
    channel.generator = syndFeed.generator;
    if (syndFeed.authors.length > 0) {
      channel.managingEditor = syndFeed.authors[0].name;
    }
    return channel;
  }

  protected createSyndEntry(item: Item, preserveWireItem: boolean): SyndEntry {
    const syndEntry = super.createSyndEntry(item, preserveWireItem);
    const desc = item.description;
    syndEntry.comments = item.comments;
    if (syndEntry.publishedDate === null) {
      syndEntry.publishedDate = item.pubDate;
    }
    if (desc !== null) {
      const descContent = new SyndContent();
      descContent.type = desc.type;
      descContent.value = desc.value;
      syndEntry.description = descContent;
    }
    const cont = item.content;
    if (cont !== null) {
      const content = new SyndContent();
      content.type = cont.type;
      content.value = cont.value;
      syndEntry.contents = [content];
    }
    return syndEntry;
  }

  protected createSyndImage(rssImage: Image): SyndImage {
    const syndImage = super.createSyndImage(rssImage);
    syndImage.description = rssImage.description;
    return syndImage;
  }
}
