// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS094Parser.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Channel } from '../../feed/rss/Channel';
import { Guid } from '../../feed/rss/Guid';
import { Item } from '../../feed/rss/Item';
import { NumberParser } from './NumberParser';
import { RSS093Parser } from './RSS093Parser';

export class RSS094Parser extends RSS093Parser {
  constructor(type: string = 'rss_0.94') {
    super(type);
  }

  protected getRSSVersion(): string {
    return '0.94';
  }

  protected parseChannel(rssRoot: Element): WireFeed {
    const channel = super.parseChannel(rssRoot) as Channel;
    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace())!;
    channel.categories = this.parseCategories(eChannel.getChildren('category', this.getRSSNamespace())) ?? [];
    const ttl = eChannel.getChild('ttl', this.getRSSNamespace());
    if (ttl !== null) {
      const ttlValue = NumberParser.parseInt(ttl.getText());
      if (ttlValue !== null) {
        channel.ttl = ttlValue;
      }
    }
    return channel;
  }

  protected parseItem(rssRoot: Element, eItem: Element): Item {
    const item = super.parseItem(rssRoot, eItem);
    item.expirationDate = null;
    const author = eItem.getChild('author', this.getRSSNamespace());
    if (author !== null) {
      item.author = author.getText();
    }
    const eGuid = eItem.getChild('guid', this.getRSSNamespace());
    if (eGuid !== null) {
      const guid = new Guid();
      const att = eGuid.getAttributeValue('isPermaLink');
      if (att !== null) {
        guid.permaLink = att.toLowerCase() === 'true';
      }
      guid.value = eGuid.getText();
      item.guid = guid;
    }
    const comments = eItem.getChild('comments', this.getRSSNamespace());
    if (comments !== null) {
      item.comments = comments.getText();
    }
    return item;
  }
}
