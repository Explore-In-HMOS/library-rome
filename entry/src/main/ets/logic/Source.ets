import { SyndFeed, SyndFeedInput, XmlReader } from '@explore-in-hmos/oh_rome';

// A feed as it arrived: fetched bytes with their HTTP Content-Type, or text from a sample or the paste box.
export class FeedSource {
  readonly label: string;
  readonly url: string | null;
  readonly bytes: Uint8Array | null;
  readonly text: string | null;
  readonly contentType: string | null;

  constructor(label: string, url: string | null, bytes: Uint8Array | null, text: string | null,
    contentType: string | null) {
    this.label = label;
    this.url = url;
    this.bytes = bytes;
    this.text = text;
    this.contentType = contentType;
  }

  static ofText(label: string, text: string): FeedSource {
    return new FeedSource(label, null, null, text, null);
  }

  static ofHttp(label: string, url: string, bytes: Uint8Array, contentType: string): FeedSource {
    return new FeedSource(label, url, bytes, null, contentType === '' ? null : contentType);
  }

  get size(): number {
    return this.bytes !== null ? this.bytes.length : (this.text ?? '').length;
  }
}

export class Parsed {
  readonly feed: SyndFeed;
  // The charset XmlReader chose for fetched bytes; empty for text.
  readonly encoding: string;

  constructor(feed: SyndFeed, encoding: string) {
    this.feed = feed;
    this.encoding = encoding;
  }
}

// Fetched bytes go through XmlReader with the HTTP Content-Type, as a ROME app does with new XmlReader(is, contentType)
// and build(Reader): RFC 3023 charsets, the text/xml defaults and the lenient text/html fallback. Every call parses
// again, so a conversion never sees changes made to an earlier SyndFeed.
export function parseDetailed(source: FeedSource): Parsed {
  if (source.bytes !== null) {
    const reader = new XmlReader(source.bytes, source.contentType);
    return new Parsed(new SyndFeedInput().build(reader.read()), reader.encoding);
  }
  return new Parsed(new SyndFeedInput().build(source.text ?? ''), '');
}

export function parseSource(source: FeedSource): SyndFeed {
  return parseDetailed(source).feed;
}
