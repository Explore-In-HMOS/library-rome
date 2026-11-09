// Ported from ROME rome/src/main/java/com/rometools/rome/io/WireFeedGenerator.java (Apache-2.0)
import { Document } from '../xml/Dom';
import { WireFeed } from '../feed/WireFeed';

export interface WireFeedGenerator {
  getType(): string;

  // Throws FeedException.
  generate(feed: WireFeed): Document;
}
