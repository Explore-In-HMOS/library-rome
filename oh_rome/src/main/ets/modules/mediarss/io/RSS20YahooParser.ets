// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/io/RSS20YahooParser.java (Apache-2.0)
import { Document, Element, Namespace } from '../../../xml/Dom';
import { WireFeed } from '../../../feed/WireFeed';
import { RSS20Parser } from '../../../io/impl/RSS20Parser';

const RSS_URI: string = 'urn:yahoo:yn';

export class RSS20YahooParser extends RSS20Parser {
  constructor(type: string = 'rss_2.0yahoo') {
    super(type);
  }

  isMyType(document: Document): boolean {
    return document.getRootElement().getNamespace()!.equals(this.getRSSNamespace());
  }

  protected getRSSNamespace(): Namespace {
    return Namespace.getNamespace(RSS_URI);
  }

  // Reports rss_2.0 so that converters and generators work.
  protected parseChannel(rssRoot: Element): WireFeed {
    const wFeed = super.parseChannel(rssRoot);
    wFeed.feedType = 'rss_2.0';
    return wFeed;
  }
}
