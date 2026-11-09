// Ported from ROME rome-opml/src/main/java/com/rometools/opml/feed/opml/Opml.java (Apache-2.0)
import { WireFeed } from '../../../feed/WireFeed';
import { Outline } from './Outline';

export class Opml extends WireFeed {
  created: Date | null = null;
  modified: Date | null = null;
  verticalScrollState: number | null = null;
  windowBottom: number | null = null;
  windowLeft: number | null = null;
  windowRight: number | null = null;
  windowTop: number | null = null;
  outlines: Outline[] = [];
  docs: string | null = null;
  ownerEmail: string | null = null;
  ownerId: string | null = null;
  ownerName: string | null = null;
  title: string | null = null;
  expansionState: number[] | null = null;
}
