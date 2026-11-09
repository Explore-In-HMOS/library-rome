// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS091UserlandParser.java (Apache-2.0)
import { Document, Element, Namespace } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Channel } from '../../feed/rss/Channel';
import { Content } from '../../feed/rss/Content';
import { Description } from '../../feed/rss/Description';
import { Image } from '../../feed/rss/Image';
import { Item } from '../../feed/rss/Item';
import { parseJavaInt } from '../../utils/JavaMath';
import { Strings } from '../../utils/Strings';
import { DateParser } from './DateParser';
import { NumberParser } from './NumberParser';
import { RSS090Parser } from './RSS090Parser';

export class RSS091UserlandParser extends RSS090Parser {
  constructor(type: string = 'rss_0.91U') {
    super(type, null);
  }

  isMyType(document: Document): boolean {
    const rssRoot = document.getRootElement();
    const version = rssRoot.getAttribute('version');
    return rssRoot.getName() === 'rss' && version !== null && version.getValue() === this.getRSSVersion();
  }

  protected getRSSVersion(): string {
    return '0.91';
  }

  protected getRSSNamespace(): Namespace {
    return Namespace.getNamespace('');
  }

  protected parseChannel(rssRoot: Element): WireFeed {
    const channel = super.parseChannel(rssRoot) as Channel;
    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace())!;

    const language = eChannel.getChild('language', this.getRSSNamespace());
    if (language !== null) {
      channel.language = language.getText();
    }
    const rating = eChannel.getChild('rating', this.getRSSNamespace());
    if (rating !== null) {
      channel.rating = rating.getText();
    }
    const copyright = eChannel.getChild('copyright', this.getRSSNamespace());
    if (copyright !== null) {
      channel.copyright = copyright.getText();
    }
    const pubDate = eChannel.getChild('pubDate', this.getRSSNamespace());
    if (pubDate !== null) {
      channel.pubDate = DateParser.parseDate(pubDate.getText());
    }
    const lastBuildDate = eChannel.getChild('lastBuildDate', this.getRSSNamespace());
    if (lastBuildDate !== null) {
      channel.lastBuildDate = DateParser.parseDate(lastBuildDate.getText());
    }
    const docs = eChannel.getChild('docs', this.getRSSNamespace());
    if (docs !== null) {
      channel.docs = docs.getText();
    }
    const generator = eChannel.getChild('generator', this.getRSSNamespace());
    if (generator !== null) {
      channel.generator = generator.getText();
    }
    const managingEditor = eChannel.getChild('managingEditor', this.getRSSNamespace());
    if (managingEditor !== null) {
      channel.managingEditor = managingEditor.getText();
    }
    const webMaster = eChannel.getChild('webMaster', this.getRSSNamespace());
    if (webMaster !== null) {
      channel.webMaster = webMaster.getText();
    }
    const eSkipHours = eChannel.getChild('skipHours');
    if (eSkipHours !== null) {
      channel.skipHours = eSkipHours.getChildren('hour', this.getRSSNamespace())
        .map((eHour: Element) => parseJavaInt(Strings.trim(eHour.getText())!));
    }
    const eSkipDays = eChannel.getChild('skipDays');
    if (eSkipDays !== null) {
      channel.skipDays = eSkipDays.getChildren('day', this.getRSSNamespace())
        .map((eDay: Element) => Strings.trim(eDay.getText())!);
    }
    return channel;
  }

  protected parseImage(rssRoot: Element): Image | null {
    const image = super.parseImage(rssRoot);
    if (image !== null) {
      const eImage = this.getImage(rssRoot)!;
      const width = eImage.getChild('width', this.getRSSNamespace());
      if (width !== null) {
        const val = NumberParser.parseInt(width.getText());
        if (val !== null) {
          image.width = val;
        }
      }
      const height = eImage.getChild('height', this.getRSSNamespace());
      if (height !== null) {
        const val = NumberParser.parseInt(height.getText());
        if (val !== null) {
          image.height = val;
        }
      }
      const description = eImage.getChild('description', this.getRSSNamespace());
      if (description !== null) {
        image.description = description.getText();
      }
    }
    return image;
  }

  protected getItems(rssRoot: Element): Element[] {
    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace());
    return eChannel === null ? [] : eChannel.getChildren('item', this.getRSSNamespace());
  }

  protected getImage(rssRoot: Element): Element | null {
    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace());
    return eChannel === null ? null : eChannel.getChild('image', this.getRSSNamespace());
  }

  protected getTextInputLabel(): string {
    return 'textInput';
  }

  protected getTextInput(rssRoot: Element): Element | null {
    const eChannel = rssRoot.getChild('channel', this.getRSSNamespace());
    return eChannel === null ? null : eChannel.getChild(this.getTextInputLabel(), this.getRSSNamespace());
  }

  protected parseItem(rssRoot: Element, eItem: Element): Item {
    const item = super.parseItem(rssRoot, eItem);
    const description = eItem.getChild('description', this.getRSSNamespace());
    if (description !== null) {
      item.description = this.parseItemDescription(rssRoot, description);
    }
    const pubDate = eItem.getChild('pubDate', this.getRSSNamespace());
    if (pubDate !== null) {
      item.pubDate = DateParser.parseDate(pubDate.getText());
    }
    const encoded = eItem.getChild('encoded', this.getContentNamespace());
    if (encoded !== null) {
      const content = new Content();
      content.type = Content.HTML;
      content.value = encoded.getText();
      item.content = content;
    }
    return item;
  }

  protected parseItemDescription(rssRoot: Element, eDesc: Element): Description {
    const desc = new Description();
    desc.type = 'text/plain';
    desc.value = eDesc.getText();
    return desc;
  }
}
