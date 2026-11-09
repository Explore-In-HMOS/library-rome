// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS10Parser.java (Apache-2.0)
import { Document, Element, Namespace } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Channel } from '../../feed/rss/Channel';
import { Content } from '../../feed/rss/Content';
import { Description } from '../../feed/rss/Description';
import { Item } from '../../feed/rss/Item';
import { RSS090Parser } from './RSS090Parser';

const RSS_URI: string = 'http://purl.org/rss/1.0/';

export class RSS10Parser extends RSS090Parser {
  constructor(type: string = 'rss_1.0', ns: Namespace | null = Namespace.getNamespace(RSS_URI)) {
    super(type, ns);
  }

  isMyType(document: Document): boolean {
    const rssRoot = document.getRootElement();
    return rssRoot.getNamespace()!.equals(this.getRDFNamespace()) &&
      rssRoot.getChild('channel', this.getRSSNamespace()) !== null;
  }

  protected getRSSNamespace(): Namespace {
    return Namespace.getNamespace(RSS_URI);
  }

  protected parseItem(rssRoot: Element, eItem: Element): Item {
    const item = super.parseItem(rssRoot, eItem);
    const description = eItem.getChild('description', this.getRSSNamespace());
    if (description !== null) {
      item.description = this.parseItemDescription(rssRoot, description);
    }
    const encoded = eItem.getChild('encoded', this.getContentNamespace());
    if (encoded !== null) {
      const content = new Content();
      content.type = Content.HTML;
      content.value = encoded.getText();
      item.content = content;
    }
    const about = eItem.getAttributeValue('about', this.getRDFNamespace());
    if (about !== null) {
      item.uri = about;
    }
    return item;
  }

  protected parseChannel(rssRoot: Element): WireFeed {
    const channel = super.parseChannel(rssRoot) as Channel;
    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace())!;
    const uri = eChannel.getAttributeValue('about', this.getRDFNamespace());
    if (uri !== null) {
      channel.uri = uri;
    }
    return channel;
  }

  protected parseItemDescription(rssRoot: Element, eDesc: Element): Description {
    const desc = new Description();
    desc.type = 'text/plain';
    desc.value = eDesc.getText();
    return desc;
  }
}
