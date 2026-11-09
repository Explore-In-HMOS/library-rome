// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS091UserlandGenerator.java (Apache-2.0)
import { Attribute, Document, Element, Namespace } from '../../xml/Dom';
import { Channel } from '../../feed/rss/Channel';
import { Image } from '../../feed/rss/Image';
import { Item } from '../../feed/rss/Item';
import { parseJavaInt } from '../../utils/JavaMath';
import { FeedException } from '../FeedException';
import { DateParser } from './DateParser';
import { RSS090Generator } from './RSS090Generator';

export class RSS091UserlandGenerator extends RSS090Generator {
  private readonly version: string;

  constructor(type: string = 'rss_0.91U', version: string = '0.91') {
    super(type);
    this.version = version;
  }

  protected getFeedNamespace(): Namespace {
    return Namespace.NO_NAMESPACE;
  }

  protected isHourFormat24(): boolean {
    return true;
  }

  protected getVersion(): string {
    return this.version;
  }

  protected addChannel(channel: Channel, parent: Element): void {
    super.addChannel(channel, parent);
    const eChannel = parent.getChild('channel', this.getFeedNamespace())!;
    this.addImage(channel, eChannel);
    this.addTextInput(channel, eChannel);
    this.addItems(channel, eChannel);
  }

  protected checkChannelConstraints(eChannel: Element): void {
    this.checkNotNullAndLength(eChannel, 'title', 1, 100);
    this.checkNotNullAndLength(eChannel, 'description', 1, 500);
    this.checkNotNullAndLength(eChannel, 'link', 1, 500);
    this.checkNotNullAndLength(eChannel, 'language', 2, 5);
    this.checkLength(eChannel, 'rating', 20, 500);
    this.checkLength(eChannel, 'copyright', 1, 100);
    this.checkLength(eChannel, 'pubDate', 1, 100);
    this.checkLength(eChannel, 'lastBuildDate', 1, 100);
    this.checkLength(eChannel, 'docs', 1, 500);
    this.checkLength(eChannel, 'managingEditor', 1, 100);
    this.checkLength(eChannel, 'webMaster', 1, 100);
    const skipHours = eChannel.getChild('skipHours');
    if (skipHours !== null) {
      for (const hour of skipHours.getChildren()) {
        const value = parseJavaInt(hour.getText());
        if (this.isHourFormat24()) {
          if (value < 1 || value > 24) {
            throw new FeedException(`Invalid hour value ${value}, it must be between 1 and 24`);
          }
        } else if (value < 0 || value > 23) {
          throw new FeedException(`Invalid hour value ${value}, it must be between 0 and 23`);
        }
      }
    }
  }

  protected checkImageConstraints(eImage: Element): void {
    this.checkNotNullAndLength(eImage, 'title', 1, 100);
    this.checkNotNullAndLength(eImage, 'url', 1, 500);
    this.checkLength(eImage, 'link', 1, 500);
    this.checkLength(eImage, 'width', 1, 3);
    this.checkLength(eImage, 'width', 1, 3);
    this.checkLength(eImage, 'description', 1, 100);
  }

  protected checkItemConstraints(eItem: Element): void {
    this.checkNotNullAndLength(eItem, 'title', 1, 100);
    this.checkNotNullAndLength(eItem, 'link', 1, 500);
    this.checkLength(eItem, 'description', 1, 500);
  }

  protected checkTextInputConstraints(eTextInput: Element): void {
    this.checkNotNullAndLength(eTextInput, 'title', 1, 100);
    this.checkNotNullAndLength(eTextInput, 'description', 1, 500);
    this.checkNotNullAndLength(eTextInput, 'name', 1, 20);
    this.checkNotNullAndLength(eTextInput, 'link', 1, 500);
  }

  protected createDocument(root: Element): Document {
    return new Document(root);
  }

  protected createRootElement(channel: Channel): Element {
    const root = new Element('rss', this.getFeedNamespace());
    root.setAttribute(new Attribute('version', this.getVersion()));
    root.addNamespaceDeclaration(this.getContentNamespace());
    this.generateModuleNamespaceDefs(root);
    return root;
  }

  protected generateSkipDaysElement(days: string[]): Element {
    const skipDaysElement = new Element('skipDays');
    for (const day of days) {
      skipDaysElement.addContent(this.generateSimpleElement('day', day));
    }
    return skipDaysElement;
  }

  protected generateSkipHoursElement(hours: number[]): Element {
    const skipHoursElement = new Element('skipHours', this.getFeedNamespace());
    for (const hour of hours) {
      skipHoursElement.addContent(this.generateSimpleElement('hour', String(hour)));
    }
    return skipHoursElement;
  }

  protected populateChannel(channel: Channel, eChannel: Element): void {
    super.populateChannel(channel, eChannel);
    if (channel.language !== null) {
      eChannel.addContent(this.generateSimpleElement('language', channel.language));
    }
    if (channel.rating !== null) {
      eChannel.addContent(this.generateSimpleElement('rating', channel.rating));
    }
    if (channel.copyright !== null) {
      eChannel.addContent(this.generateSimpleElement('copyright', channel.copyright));
    }
    const pubDate = channel.pubDate;
    if (pubDate !== null) {
      eChannel.addContent(this.generateSimpleElement('pubDate', DateParser.formatRFC822(pubDate)));
    }
    const lastBuildDate = channel.lastBuildDate;
    if (lastBuildDate !== null) {
      eChannel.addContent(this.generateSimpleElement('lastBuildDate', DateParser.formatRFC822(lastBuildDate)));
    }
    if (channel.docs !== null) {
      eChannel.addContent(this.generateSimpleElement('docs', channel.docs));
    }
    if (channel.managingEditor !== null) {
      eChannel.addContent(this.generateSimpleElement('managingEditor', channel.managingEditor));
    }
    if (channel.webMaster !== null) {
      eChannel.addContent(this.generateSimpleElement('webMaster', channel.webMaster));
    }
    const skipHours = channel.skipHours;
    if (skipHours.length > 0) {
      eChannel.addContent(this.generateSkipHoursElement(skipHours));
    }
    const skipDays = channel.skipDays;
    if (skipDays.length > 0) {
      eChannel.addContent(this.generateSkipDaysElement(skipDays));
    }
  }

  protected populateFeed(channel: Channel, parent: Element): void {
    this.addChannel(channel, parent);
  }

  protected populateImage(image: Image, eImage: Element): void {
    super.populateImage(image, eImage);
    if (image.width !== null) {
      eImage.addContent(this.generateSimpleElement('width', String(image.width)));
    }
    if (image.height !== null) {
      eImage.addContent(this.generateSimpleElement('height', String(image.height)));
    }
    if (image.description !== null) {
      eImage.addContent(this.generateSimpleElement('description', image.description));
    }
  }

  protected populateItem(item: Item, eItem: Element, index: number): void {
    super.populateItem(item, eItem, index);
    if (item.description !== null) {
      eItem.addContent(this.generateSimpleElement('description', item.description.value));
    }
    const contentNamespace = this.getContentNamespace();
    if (item.getModule(contentNamespace.getURI()) === null && item.content !== null) {
      const elem = new Element('encoded', contentNamespace);
      elem.addContent(item.content.value ?? '');
      eItem.addContent(elem);
    }
  }
}
