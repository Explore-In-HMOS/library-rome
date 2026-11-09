// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/Converter.java (Apache-2.0)
import { WireFeed } from '../WireFeed';
import { SyndFeed } from './SyndFeed';

export interface Converter {
  getType(): string;

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void;

  createRealFeed(syndFeed: SyndFeed): WireFeed;
}
