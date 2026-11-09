// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS090Generator.java (Apache-2.0)
import { Document, Element, Namespace } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Channel } from '../../feed/rss/Channel';
import { Image } from '../../feed/rss/Image';
import { Item } from '../../feed/rss/Item';
import { TextInput } from '../../feed/rss/TextInput';
import { FeedException } from '../FeedException';
import { BaseWireFeedGenerator } from './BaseWireFeedGenerator';

const RDF_NS: Namespace = Namespace.getNamespace('rdf', 'http://www.w3.org/1999/02/22-rdf-syntax-ns#');
const RSS_NS: Namespace = Namespace.getNamespace('http://my.netscape.com/rdf/simple/0.9/');
const CONTENT_NS: Namespace = Namespace.getNamespace('content', 'http://purl.org/rss/1.0/modules/content/');

export class RSS090Generator extends BaseWireFeedGenerator {
  constructor(type: string = 'rss_0.9') {
    super(type);
  }

  generate(feed: WireFeed): Document {
    const channel = feed as Channel;
    const root = this.createRootElement(channel);
    this.populateFeed(channel, root);
    BaseWireFeedGenerator.purgeUnusedNamespaceDeclarations(root);
    return this.createDocument(root);
  }

  protected getFeedNamespace(): Namespace {
    return RSS_NS;
  }

  protected getRDFNamespace(): Namespace {
    return RDF_NS;
  }

  protected getContentNamespace(): Namespace {
    return CONTENT_NS;
  }

  protected createDocument(root: Element): Document {
    return new Document(root);
  }

  protected createRootElement(channel: Channel): Element {
    const root = new Element('RDF', this.getRDFNamespace());
    root.addNamespaceDeclaration(this.getFeedNamespace());
    root.addNamespaceDeclaration(this.getRDFNamespace());
    root.addNamespaceDeclaration(this.getContentNamespace());
    this.generateModuleNamespaceDefs(root);
    return root;
  }

  protected populateFeed(channel: Channel, parent: Element): void {
    this.addChannel(channel, parent);
    this.addImage(channel, parent);
    this.addTextInput(channel, parent);
    this.addItems(channel, parent);
    this.generateForeignMarkup(parent, channel.foreignMarkup);
  }

  protected addChannel(channel: Channel, parent: Element): void {
    const eChannel = new Element('channel', this.getFeedNamespace());
    this.populateChannel(channel, eChannel);
    this.checkChannelConstraints(eChannel);
    parent.addContent(eChannel);
    this.generateFeedModules(channel.modules, eChannel);
  }

  protected populateChannel(channel: Channel, eChannel: Element): void {
    if (channel.title !== null) {
      eChannel.addContent(this.generateSimpleElement('title', channel.title));
    }
    if (channel.link !== null) {
      eChannel.addContent(this.generateSimpleElement('link', channel.link));
    }
    if (channel.description !== null) {
      eChannel.addContent(this.generateSimpleElement('description', channel.description));
    }
  }

  // maxLen == -1 means unlimited.
  protected checkNotNullAndLength(parent: Element, childName: string, minLen: number, maxLen: number): void {
    if (parent.getChild(childName, this.getFeedNamespace()) === null) {
      throw new FeedException(`Invalid ${this.getType()} feed, missing ${parent.getName()} ${childName}`);
    }
    this.checkLength(parent, childName, minLen, maxLen);
  }

  // maxLen == -1 means unlimited.
  protected checkLength(parent: Element, childName: string, minLen: number, maxLen: number): void {
    const child = parent.getChild(childName, this.getFeedNamespace());
    if (child !== null) {
      if (minLen > 0 && child.getText().length < minLen) {
        throw new FeedException(
          `Invalid ${this.getType()} feed, ${parent.getName()} ${childName}short of ${minLen} length`);
      }
      if (maxLen > -1 && child.getText().length > maxLen) {
        throw new FeedException(`Invalid ${this.getType()} feed, ${parent.getName()} ${childName}exceeds ${maxLen} length`);
      }
    }
  }

  protected addImage(channel: Channel, parent: Element): void {
    const image = channel.image;
    if (image !== null) {
      const eImage = new Element('image', this.getFeedNamespace());
      this.populateImage(image, eImage);
      this.checkImageConstraints(eImage);
      parent.addContent(eImage);
    }
  }

  protected populateImage(image: Image, eImage: Element): void {
    if (image.title !== null) {
      eImage.addContent(this.generateSimpleElement('title', image.title));
    }
    if (image.url !== null) {
      eImage.addContent(this.generateSimpleElement('url', image.url));
    }
    if (image.link !== null) {
      eImage.addContent(this.generateSimpleElement('link', image.link));
    }
  }

  protected getTextInputLabel(): string {
    return 'textInput';
  }

  protected addTextInput(channel: Channel, parent: Element): void {
    const textInput = channel.textInput;
    if (textInput !== null) {
      const eTextInput = new Element(this.getTextInputLabel(), this.getFeedNamespace());
      this.populateTextInput(textInput, eTextInput);
      this.checkTextInputConstraints(eTextInput);
      parent.addContent(eTextInput);
    }
  }

  protected populateTextInput(textInput: TextInput, eTextInput: Element): void {
    if (textInput.title !== null) {
      eTextInput.addContent(this.generateSimpleElement('title', textInput.title));
    }
    if (textInput.description !== null) {
      eTextInput.addContent(this.generateSimpleElement('description', textInput.description));
    }
    if (textInput.name !== null) {
      eTextInput.addContent(this.generateSimpleElement('name', textInput.name));
    }
    if (textInput.link !== null) {
      eTextInput.addContent(this.generateSimpleElement('link', textInput.link));
    }
  }

  protected addItems(channel: Channel, parent: Element): void {
    channel.items.forEach((item: Item, index: number) => this.addItem(item, parent, index));
    this.checkItemsConstraints(parent);
  }

  protected addItem(item: Item, parent: Element, index: number): void {
    const eItem = new Element('item', this.getFeedNamespace());
    this.populateItem(item, eItem, index);
    this.checkItemConstraints(eItem);
    this.generateItemModules(item.modules, eItem);
    parent.addContent(eItem);
  }

  protected populateItem(item: Item, eItem: Element, index: number): void {
    if (item.title !== null) {
      eItem.addContent(this.generateSimpleElement('title', item.title));
    }
    if (item.link !== null) {
      eItem.addContent(this.generateSimpleElement('link', item.link));
    }
    this.generateForeignMarkup(eItem, item.foreignMarkup);
  }

  // A null value becomes empty text, as JDOM's Text(null).
  protected generateSimpleElement(name: string, value: string | null): Element {
    const element = new Element(name, this.getFeedNamespace());
    element.addContent(value ?? '');
    return element;
  }

  protected checkChannelConstraints(eChannel: Element): void {
    this.checkNotNullAndLength(eChannel, 'title', 0, 40);
    this.checkNotNullAndLength(eChannel, 'description', 0, 500);
    this.checkNotNullAndLength(eChannel, 'link', 0, 500);
  }

  protected checkImageConstraints(eImage: Element): void {
    this.checkNotNullAndLength(eImage, 'title', 0, 40);
    this.checkNotNullAndLength(eImage, 'url', 0, 500);
    this.checkNotNullAndLength(eImage, 'link', 0, 500);
  }

  protected checkTextInputConstraints(eTextInput: Element): void {
    this.checkNotNullAndLength(eTextInput, 'title', 0, 40);
    this.checkNotNullAndLength(eTextInput, 'description', 0, 100);
    this.checkNotNullAndLength(eTextInput, 'name', 0, 500);
    this.checkNotNullAndLength(eTextInput, 'link', 0, 500);
  }

  protected checkItemsConstraints(parent: Element): void {
    const count = parent.getChildren('item', this.getFeedNamespace()).length;
    if (count < 1 || count > 15) {
      throw new FeedException(`Invalid ${this.getType()} feed, item count is ${count} it must be between 1 an 15`);
    }
  }

  protected checkItemConstraints(eItem: Element): void {
    this.checkNotNullAndLength(eItem, 'title', 0, 100);
    this.checkNotNullAndLength(eItem, 'link', 0, 500);
  }
}
