// Ported from ROME rome/src/main/java/com/rometools/rome/io/WireFeedParser.java (Apache-2.0)
import { Document } from '../xml/Dom';
import { WireFeed } from '../feed/WireFeed';

export interface WireFeedParser {
  getType(): string;

  isMyType(document: Document): boolean;

  // Throws FeedException.
  parse(document: Document): WireFeed;
}
