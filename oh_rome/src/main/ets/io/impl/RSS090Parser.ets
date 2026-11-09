// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS090Parser.java (Apache-2.0)
import { Document, Element, Namespace } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Module } from '../../feed/module/Module';
import { Channel } from '../../feed/rss/Channel';
import { Image } from '../../feed/rss/Image';
import { Item } from '../../feed/rss/Item';
import { TextInput } from '../../feed/rss/TextInput';
import { BaseWireFeedParser } from './BaseWireFeedParser';

const RDF_NS: Namespace = Namespace.getNamespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
const RSS_NS: Namespace = Namespace.getNamespace('http://my.netscape.com/rdf/simple/0.9/');
const CONTENT_NS: Namespace = Namespace.getNamespace('http://purl.org/rss/1.0/modules/content/');

export class RSS090Parser extends BaseWireFeedParser {
  constructor(type: string = 'rss_0.9', ns: Namespace | null = RSS_NS) {
    super(type, ns);
  }

  isMyType(document: Document): boolean {
    const rssRoot = document.getRootElement();
    return rssRoot.getNamespace()!.equals(this.getRDFNamespace()) &&
      rssRoot.getAdditionalNamespaces().some((namespace: Namespace) => this.getRSSNamespace().equals(namespace));
  }

  parse(document: Document): WireFeed {
    return this.parseChannel(document.getRootElement());
  }

  protected getRSSNamespace(): Namespace {
    return RSS_NS;
  }

  protected getRDFNamespace(): Namespace {
    return RDF_NS;
  }

  protected getContentNamespace(): Namespace {
    return CONTENT_NS;
  }

  // A missing channel element throws a TypeError, where ROME throws a NullPointerException.
  protected parseChannel(rssRoot: Element): WireFeed {
    const channel = new Channel(this.getType());
    channel.styleSheet = this.getStyleSheet(rssRoot.getParent() as Document);

    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace())!;

    const title = eChannel.getChild('title', this.getRSSNamespace());
    if (title !== null) {
      channel.title = title.getText();
    }
    const link = eChannel.getChild('link', this.getRSSNamespace());
    if (link !== null) {
      channel.link = link.getText();
    }
    const description = eChannel.getChild('description', this.getRSSNamespace());
    if (description !== null) {
      channel.description = description.getText();
    }

    channel.image = this.parseImage(rssRoot);
    channel.textInput = this.parseTextInput(rssRoot);

    // Microsoft's SSE puts a channel module inside the rss element, so modules are read from the root too.
    const allFeedModules: Module[] = this.parseFeedModules(rssRoot).concat(this.parseFeedModules(eChannel));
    channel.modules = allFeedModules;
    channel.items = this.parseItems(rssRoot);

    const foreignMarkup = this.extractForeignMarkup(eChannel, channel, this.getRSSNamespace());
    if (foreignMarkup.length > 0) {
      channel.foreignMarkup = foreignMarkup;
    }
    return channel;
  }

  // RSS 0.90 and 1.0 have items, image and textinput under the root; the other versions under channel.
  protected getItems(rssRoot: Element): Element[] {
    return rssRoot.getChildren('item', this.getRSSNamespace());
  }

  protected getImage(rssRoot: Element): Element | null {
    return rssRoot.getChild('image', this.getRSSNamespace());
  }

  protected getTextInput(rssRoot: Element): Element | null {
    return rssRoot.getChild('textinput', this.getRSSNamespace());
  }

  protected parseImage(rssRoot: Element): Image | null {
    const eImage = this.getImage(rssRoot);
    if (eImage === null) {
      return null;
    }
    const image = new Image();
    const title = eImage.getChild('title', this.getRSSNamespace());
    if (title !== null) {
      image.title = title.getText();
    }
    const url = eImage.getChild('url', this.getRSSNamespace());
    if (url !== null) {
      image.url = url.getText();
    }
    const link = eImage.getChild('link', this.getRSSNamespace());
    if (link !== null) {
      image.link = link.getText();
    }
    return image;
  }

  protected parseItems(rssRoot: Element): Item[] {
    return this.getItems(rssRoot).map((eItem: Element) => this.parseItem(rssRoot, eItem));
  }

  protected parseItem(rssRoot: Element, eItem: Element): Item {
    const item = new Item();
    const title = eItem.getChild('title', this.getRSSNamespace());
    if (title !== null) {
      item.title = title.getText();
    }
    const link = eItem.getChild('link', this.getRSSNamespace());
    if (link !== null) {
      item.link = link.getText();
      item.uri = link.getText();
    }
    item.modules = this.parseItemModules(eItem);

    // content:encoded has no module but is read into Item.content, so it is not kept as foreign markup.
    const foreignMarkup = this.extractForeignMarkup(eItem, item, this.getRSSNamespace())
      .filter((e: Element) => !(this.getContentNamespace().equals(e.getNamespace()) && e.getName() === 'encoded'));
    if (foreignMarkup.length > 0) {
      item.foreignMarkup = foreignMarkup;
    }
    return item;
  }

  protected parseTextInput(rssRoot: Element): TextInput | null {
    const eTextInput = this.getTextInput(rssRoot);
    if (eTextInput === null) {
      return null;
    }
    const textInput = new TextInput();
    const title = eTextInput.getChild('title', this.getRSSNamespace());
    if (title !== null) {
      textInput.title = title.getText();
    }
    const description = eTextInput.getChild('description', this.getRSSNamespace());
    if (description !== null) {
      textInput.description = description.getText();
    }
    const name = eTextInput.getChild('name', this.getRSSNamespace());
    if (name !== null) {
      textInput.name = name.getText();
    }
    const link = eTextInput.getChild('link', this.getRSSNamespace());
    if (link !== null) {
      textInput.link = link.getText();
    }
    return textInput;
  }
}
