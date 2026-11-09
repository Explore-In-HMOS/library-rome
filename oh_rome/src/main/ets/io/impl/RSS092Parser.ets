// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS092Parser.java (Apache-2.0)
import { CType, Element } from '../../xml/Dom';
import { Format } from '../../xml/Format';
import { XMLOutputter } from '../../xml/XmlOutputter';
import { WireFeed } from '../../feed/WireFeed';
import { Category } from '../../feed/rss/Category';
import { Channel } from '../../feed/rss/Channel';
import { Cloud } from '../../feed/rss/Cloud';
import { Description } from '../../feed/rss/Description';
import { Enclosure } from '../../feed/rss/Enclosure';
import { Item } from '../../feed/rss/Item';
import { Source } from '../../feed/rss/Source';
import { parseJavaInt } from '../../utils/JavaMath';
import { Strings } from '../../utils/Strings';
import { NumberParser } from './NumberParser';
import { RSS091UserlandParser } from './RSS091UserlandParser';

export class RSS092Parser extends RSS091UserlandParser {
  constructor(type: string = 'rss_0.92') {
    super(type);
  }

  protected getRSSVersion(): string {
    return '0.92';
  }

  protected parseChannel(rssRoot: Element): WireFeed {
    const channel = super.parseChannel(rssRoot) as Channel;
    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace())!;
    const eCloud = eChannel.getChild('cloud', this.getRSSNamespace());
    if (eCloud !== null) {
      const cloud = new Cloud();
      const domain = eCloud.getAttributeValue('domain');
      if (domain !== null) {
        cloud.domain = domain;
      }
      const port = eCloud.getAttributeValue('port');
      if (port !== null) {
        cloud.port = parseJavaInt(Strings.trim(port)!);
      }
      const path = eCloud.getAttributeValue('path');
      if (path !== null) {
        cloud.path = path;
      }
      const registerProcedure = eCloud.getAttributeValue('registerProcedure');
      if (registerProcedure !== null) {
        cloud.registerProcedure = registerProcedure;
      }
      const protocol = eCloud.getAttributeValue('protocol');
      if (protocol !== null) {
        cloud.protocol = protocol;
      }
      channel.cloud = cloud;
    }
    return channel;
  }

  protected parseItem(rssRoot: Element, eItem: Element): Item {
    const item = super.parseItem(rssRoot, eItem);
    const eSource = eItem.getChild('source', this.getRSSNamespace());
    if (eSource !== null) {
      const source = new Source();
      source.url = eSource.getAttributeValue('url');
      source.value = eSource.getText();
      item.source = source;
    }

    // Enclosures and categories are read in no namespace whatever the RSS namespace is.
    const eEnclosures = eItem.getChildren('enclosure');
    if (eEnclosures.length > 0) {
      item.enclosures = eEnclosures.map((eEnclosure: Element) => {
        const enclosure = new Enclosure();
        const url = eEnclosure.getAttributeValue('url');
        if (url !== null) {
          enclosure.url = url;
        }
        enclosure.length = NumberParser.parseLongWithDefault(eEnclosure.getAttributeValue('length'), 0);
        const type = eEnclosure.getAttributeValue('type');
        if (type !== null) {
          enclosure.type = type;
        }
        return enclosure;
      });
    }
    item.categories = this.parseCategories(eItem.getChildren('category')) ?? [];
    return item;
  }

  // Null when no category has text, as in ROME; the model's getter then reads it as an empty list.
  protected parseCategories(eCats: Element[]): Category[] | null {
    const cats: Category[] = [];
    for (const eCat of eCats) {
      const text = eCat.getText();
      if (Strings.isBlank(text)) {
        continue;
      }
      const cat = new Category();
      const domain = eCat.getAttributeValue('domain');
      if (domain !== null) {
        cat.domain = domain;
      }
      cat.value = text;
      cats.push(cat);
    }
    return cats.length === 0 ? null : cats;
  }

  protected parseItemDescription(rssRoot: Element, eDesc: Element): Description {
    const desc = new Description();
    const outputter = new XMLOutputter(Format.getRawFormat());
    let value = '';
    for (const c of eDesc.getContent()) {
      const type = c.getCType();
      if (type === CType.Text || type === CType.CDATA || type === CType.EntityRef) {
        value += c.getValue();
      } else if (type === CType.Element) {
        value += outputter.outputString(c as Element);
      }
    }
    desc.value = value;
    const att = eDesc.getAttributeValue('type');
    desc.type = att === null ? 'text/html' : att;
    return desc;
  }
}
