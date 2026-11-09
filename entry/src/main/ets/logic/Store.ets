import { SyndEntry, SyndFeed } from 'oh_rome';
import { Subscription } from './Opml';
import { FeedSource } from './Source';

// What the pages share. The Navigation stack carries only page names, so the open feed lives here.
export class Store {
  static source: FeedSource | null = null;
  static feed: SyndFeed | null = null;
  static entry: SyndEntry | null = null;
  // Feeds the user added by URL in this session, on top of the presets.
  static added: Subscription[] = [];

  static open(source: FeedSource, feed: SyndFeed): void {
    Store.source = source;
    Store.feed = feed;
    Store.entry = null;
  }
}
