// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS20Generator.java (Apache-2.0)
import { Element } from '../../xml/Dom';
import { Channel } from '../../feed/rss/Channel';
import { Item } from '../../feed/rss/Item';
import { RSS094Generator } from './RSS094Generator';

export class RSS20Generator extends RSS094Generator {
  constructor(type: string = 'rss_2.0', version: string = '2.0') {
    super(type, version);
  }

  protected populateChannel(channel: Channel, eChannel: Element): void {
    super.populateChannel(channel, eChannel);
    if (channel.generator !== null) {
      eChannel.addContent(this.generateSimpleElement('generator', channel.generator));
    }
    if (channel.ttl > -1) {
      eChannel.addContent(this.generateSimpleElement('ttl', String(channel.ttl)));
    }
    for (const category of channel.categories) {
      eChannel.addContent(this.generateCategoryElement(category));
    }
    this.generateForeignMarkup(eChannel, channel.foreignMarkup);
  }

  protected populateItem(item: Item, eItem: Element, index: number): void {
    super.populateItem(item, eItem, index);
    const description = eItem.getChild('description', this.getFeedNamespace());
    if (description !== null) {
      description.removeAttribute('type');
    }
    if (item.author !== null) {
      eItem.addContent(this.generateSimpleElement('author', item.author));
    }
    if (item.comments !== null) {
      eItem.addContent(this.generateSimpleElement('comments', item.comments));
    }
    const guid = item.guid;
    if (guid !== null) {
      const eGuid = this.generateSimpleElement('guid', guid.value);
      if (!guid.permaLink) {
        eGuid.setAttribute('isPermaLink', 'false');
      }
      eItem.addContent(eGuid);
    }
  }
}
