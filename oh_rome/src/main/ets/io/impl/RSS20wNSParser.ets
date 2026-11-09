// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS20wNSParser.java (Apache-2.0)
import { Document, Element, Namespace } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { RSS20Parser } from './RSS20Parser';

const RSS20_URI: string = 'http://backend.userland.com/rss2';

export class RSS20wNSParser extends RSS20Parser {
  constructor(type: string = 'rss_2.0wNS') {
    super(type);
  }

  isMyType(document: Document): boolean {
    return document.getRootElement().getNamespace()!.equals(this.getRSSNamespace()) && super.isMyType(document);
  }

  protected getRSSNamespace(): Namespace {
    return Namespace.getNamespace(RSS20_URI);
  }

  protected parseChannel(rssRoot: Element): WireFeed {
    const wFeed = super.parseChannel(rssRoot);
    wFeed.feedType = 'rss_2.0';
    return wFeed;
  }
}
