// Ported from ROME rome/src/main/java/com/rometools/rome/io/SyndFeedOutput.java (Apache-2.0)
import { SyndFeed } from '../feed/synd/SyndFeed';
import { Document } from '../xml/Dom';
import { WireFeedOutput } from './WireFeedOutput';

/** Converts a SyndFeed to a wire feed of its feedType and writes it with WireFeedOutput. */
export class SyndFeedOutput {
  private readonly feedOutput: WireFeedOutput = new WireFeedOutput();

  outputString(feed: SyndFeed, prettyPrint: boolean = true): string {
    return this.feedOutput.outputString(feed.createWireFeed(), prettyPrint);
  }

  outputJDom(feed: SyndFeed): Document {
    return this.feedOutput.outputJDom(feed.createWireFeed());
  }
}
