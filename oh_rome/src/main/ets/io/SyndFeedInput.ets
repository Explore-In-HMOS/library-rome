// Ported from ROME rome/src/main/java/com/rometools/rome/io/SyndFeedInput.java (Apache-2.0)
import { SyndFeed } from '../feed/synd/SyndFeed';
import { Document } from '../xml/Dom';
import { WireFeedInput } from './WireFeedInput';

/** Parses a feed with WireFeedInput and converts it to a SyndFeed. */
export class SyndFeedInput {
  private readonly feedInput: WireFeedInput = new WireFeedInput();
  preserveWireFeed: boolean = false;

  get xmlHealerOn(): boolean {
    return this.feedInput.xmlHealerOn;
  }

  set xmlHealerOn(heals: boolean) {
    this.feedInput.xmlHealerOn = heals;
  }

  get allowDoctypes(): boolean {
    return this.feedInput.allowDoctypes;
  }

  set allowDoctypes(allowDoctypes: boolean) {
    this.feedInput.allowDoctypes = allowDoctypes;
  }

  build(input: string | Uint8Array | Document): SyndFeed {
    return new SyndFeed(this.feedInput.build(input), this.preserveWireFeed);
  }
}
