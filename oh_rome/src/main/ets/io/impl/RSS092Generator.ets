// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS092Generator.java (Apache-2.0)
import { Attribute, Element } from '../../xml/Dom';
import { Category } from '../../feed/rss/Category';
import { Channel } from '../../feed/rss/Channel';
import { Cloud } from '../../feed/rss/Cloud';
import { Enclosure } from '../../feed/rss/Enclosure';
import { Item } from '../../feed/rss/Item';
import { Source } from '../../feed/rss/Source';
import { RSS091UserlandGenerator } from './RSS091UserlandGenerator';

export class RSS092Generator extends RSS091UserlandGenerator {
  constructor(type: string = 'rss_0.92', version: string = '0.92') {
    super(type, version);
  }

  protected populateChannel(channel: Channel, eChannel: Element): void {
    super.populateChannel(channel, eChannel);
    if (channel.cloud !== null) {
      eChannel.addContent(this.generateCloud(channel.cloud));
    }
  }

  protected generateCloud(cloud: Cloud): Element {
    const eCloud = new Element('cloud', this.getFeedNamespace());
    if (cloud.domain !== null) {
      eCloud.setAttribute(new Attribute('domain', cloud.domain));
    }
    if (cloud.port !== 0) {
      eCloud.setAttribute(new Attribute('port', String(cloud.port)));
    }
    if (cloud.path !== null) {
      eCloud.setAttribute(new Attribute('path', cloud.path));
    }
    if (cloud.registerProcedure !== null) {
      eCloud.setAttribute(new Attribute('registerProcedure', cloud.registerProcedure));
    }
    if (cloud.protocol !== null) {
      eCloud.setAttribute(new Attribute('protocol', cloud.protocol));
    }
    return eCloud;
  }

  protected getNumberOfEnclosures(enclosures: Enclosure[]): number {
    return enclosures.length > 0 ? 1 : 0;
  }

  protected populateItem(item: Item, eItem: Element, index: number): void {
    super.populateItem(item, eItem, index);
    if (item.source !== null) {
      eItem.addContent(this.generateSourceElement(item.source));
    }
    const enclosures = item.enclosures;
    for (let i = 0; i < this.getNumberOfEnclosures(enclosures); i++) {
      eItem.addContent(this.generateEnclosure(enclosures[i]));
    }
    for (const category of item.categories) {
      eItem.addContent(this.generateCategoryElement(category));
    }
  }

  protected generateSourceElement(source: Source): Element {
    const sourceElement = new Element('source', this.getFeedNamespace());
    if (source.url !== null) {
      sourceElement.setAttribute(new Attribute('url', source.url));
    }
    sourceElement.addContent(source.value ?? '');
    return sourceElement;
  }

  protected generateEnclosure(enclosure: Enclosure): Element {
    const enclosureElement = new Element('enclosure', this.getFeedNamespace());
    if (enclosure.url !== null) {
      enclosureElement.setAttribute('url', enclosure.url);
    }
    enclosureElement.setAttribute('length', String(enclosure.length));
    if (enclosure.type !== null) {
      enclosureElement.setAttribute('type', enclosure.type);
    }
    return enclosureElement;
  }

  protected generateCategoryElement(category: Category): Element {
    const categoryElement = new Element('category', this.getFeedNamespace());
    if (category.domain !== null) {
      categoryElement.setAttribute('domain', category.domain);
    }
    categoryElement.addContent(category.value ?? '');
    return categoryElement;
  }

  protected checkChannelConstraints(eChannel: Element): void {
    this.checkNotNullAndLength(eChannel, 'title', 0, -1);
    this.checkNotNullAndLength(eChannel, 'description', 0, -1);
    this.checkNotNullAndLength(eChannel, 'link', 0, -1);
  }

  protected checkImageConstraints(eImage: Element): void {
    this.checkNotNullAndLength(eImage, 'title', 0, -1);
    this.checkNotNullAndLength(eImage, 'url', 0, -1);
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
  }
}
