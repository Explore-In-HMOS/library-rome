// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS10.java (Apache-2.0)
import { WireFeed } from '../../WireFeed';
import { Channel } from '../../rss/Channel';
import { Content } from '../../rss/Content';
import { Description } from '../../rss/Description';
import { Item } from '../../rss/Item';
import { SyndContent } from '../SyndContent';
import { SyndEntry } from '../SyndEntry';
import { SyndFeed } from '../SyndFeed';
import { ConverterForRSS090 } from './ConverterForRSS090';

export class ConverterForRSS10 extends ConverterForRSS090 {
  constructor(type: string = 'rss_1.0') {
    super(type);
  }

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void {
    const channel = feed as Channel;
    super.copyInto(channel, syndFeed);
    syndFeed.uri = channel.uri !== null ? channel.uri : channel.link;
  }

  protected createSyndEntry(item: Item, preserveWireItem: boolean): SyndEntry {
    const syndEntry = super.createSyndEntry(item, preserveWireItem);
    const desc = item.description;
    if (desc !== null) {
      const descContent = new SyndContent();
      descContent.type = desc.type;
      descContent.value = desc.value;
      syndEntry.description = descContent;
    }
    const cont = item.content;
    if (cont !== null) {
      const contContent = new SyndContent();
      contContent.type = cont.type;
      contContent.value = cont.value;
      syndEntry.contents = [contContent];
    }
    return syndEntry;
  }

  protected createChannel(type: string, syndFeed: SyndFeed): Channel {
    const channel = super.createChannel(type, syndFeed);
    channel.uri = syndFeed.uri !== null ? syndFeed.uri : syndFeed.link;
    return channel;
  }

  protected createRSSItem(sEntry: SyndEntry): Item {
    const item = super.createRSSItem(sEntry);
    if (sEntry.description !== null) {
      item.description = this.createItemDescription(sEntry.description);
    }
    if (sEntry.contents.length > 0) {
      item.content = this.createItemContent(sEntry.contents[0]);
    }
    if (sEntry.uri !== null) {
      item.uri = sEntry.uri;
    }
    return item;
  }

  protected createItemDescription(sContent: SyndContent): Description {
    const desc = new Description();
    desc.value = sContent.value;
    desc.type = sContent.type;
    return desc;
  }

  protected createItemContent(sContent: SyndContent): Content {
    const cont = new Content();
    cont.value = sContent.value;
    cont.type = sContent.type;
    return cont;
  }
}
