// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS10Generator.java (Apache-2.0)
import { Element, Namespace } from '../../xml/Dom';
import { Channel } from '../../feed/rss/Channel';
import { Item } from '../../feed/rss/Item';
import { RSS090Generator } from './RSS090Generator';

const RSS_NS: Namespace = Namespace.getNamespace('http://purl.org/rss/1.0/');

export class RSS10Generator extends RSS090Generator {
  constructor(type: string = 'rss_1.0') {
    super(type);
  }

  protected getFeedNamespace(): Namespace {
    return RSS_NS;
  }

  protected populateChannel(channel: Channel, eChannel: Element): void {
    super.populateChannel(channel, eChannel);
    if (channel.uri !== null) {
      eChannel.setAttribute('about', channel.uri, this.getRDFNamespace());
    }
    const items = channel.items;
    if (items.length > 0) {
      const eItems = new Element('items', this.getFeedNamespace());
      const eSeq = new Element('Seq', this.getRDFNamespace());
      for (const item of items) {
        const lis = new Element('li', this.getRDFNamespace());
        if (item.uri !== null) {
          lis.setAttribute('resource', item.uri, this.getRDFNamespace());
        }
        eSeq.addContent(lis);
      }
      eItems.addContent(eSeq);
      eChannel.addContent(eItems);
    }
  }

  protected populateItem(item: Item, eItem: Element, index: number): void {
    super.populateItem(item, eItem, index);
    if (item.uri !== null) {
      eItem.setAttribute('about', item.uri, this.getRDFNamespace());
    } else if (item.link !== null) {
      eItem.setAttribute('about', item.link, this.getRDFNamespace());
    }
    if (item.description !== null) {
      eItem.addContent(this.generateSimpleElement('description', item.description.value));
    }
    if (item.getModule(this.getContentNamespace().getURI()) === null && item.content !== null) {
      const elem = new Element('encoded', this.getContentNamespace());
      elem.addContent(item.content.value ?? '');
      eItem.addContent(elem);
    }
  }

  protected checkChannelConstraints(eChannel: Element): void {
    this.checkNotNullAndLength(eChannel, 'title', 0, -1);
    this.checkNotNullAndLength(eChannel, 'description', 0, -1);
    this.checkNotNullAndLength(eChannel, 'link', 0, -1);
  }

  protected checkImageConstraints(eImage: Element): void {
    this.checkNotNullAndLength(eImage, 'title', 0, -1);
    this.checkNotNullAndLength(eImage, 'url', 0, -1);
    this.checkNotNullAndLength(eImage, 'link', 0, -1);
  }

  protected checkTextInputConstraints(eTextInput: Element): void {
    this.checkNotNullAndLength(eTextInput, 'title', 0, -1);
    this.checkNotNullAndLength(eTextInput, 'description', 0, -1);
    this.checkNotNullAndLength(eTextInput, 'name', 0, -1);
    this.checkNotNullAndLength(eTextInput, 'link', 0, -1);
  }

  protected checkItemsConstraints(parent: Element): void {
  }

  protected checkItemConstraints(eItem: Element): void {
    this.checkNotNullAndLength(eItem, 'title', 0, -1);
    this.checkNotNullAndLength(eItem, 'link', 0, -1);
  }
}
