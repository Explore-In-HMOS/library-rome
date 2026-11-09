// Sample feeds bundled with the demo, so it runs without network access.
export class Sample {
  readonly name: string;
  readonly xml: string;

  constructor(name: string, xml: string) {
    this.name = name;
    this.xml = xml;
  }
}

const RSS_20 = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Harbour News</title>
    <link>https://example.com/harbour</link>
    <description>Daily notes from a small harbour</description>
    <item>
      <title>Ferry timetable changes on Monday</title>
      <link>https://example.com/harbour/ferry</link>
      <pubDate>Mon, 02 Nov 2026 08:30:00 GMT</pubDate>
    </item>
    <item>
      <title>Lighthouse open to visitors again</title>
      <link>https://example.com/harbour/lighthouse</link>
      <pubDate>Sat, 31 Oct 2026 16:00:00 GMT</pubDate>
    </item>
    <item>
      <title>First winter storm expected this week</title>
      <link>https://example.com/harbour/storm</link>
      <pubDate>Thu, 29 Oct 2026 06:45:00 GMT</pubDate>
    </item>
  </channel>
</rss>`;

const ATOM_10 = `<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Field Notes</title>
  <id>urn:example:field-notes</id>
  <updated>2026-11-03T10:00:00Z</updated>
  <entry>
    <title>Seedlings after the spring burn</title>
    <id>urn:example:field-notes:1</id>
    <link href="https://example.com/notes/seedlings"/>
    <published>2026-11-03T10:00:00Z</published>
    <updated>2026-11-03T10:00:00Z</updated>
  </entry>
  <entry>
    <title>Counting moss on the north slope</title>
    <id>urn:example:field-notes:2</id>
    <link href="https://example.com/notes/moss"/>
    <published>2026-10-27T14:20:00Z</published>
    <updated>2026-10-28T09:00:00Z</updated>
  </entry>
</feed>`;

const PODCAST = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">
  <channel>
    <title>Tide Tables</title>
    <link>https://example.com/tide</link>
    <description>A podcast about the sea, one tide at a time</description>
    <itunes:author>Tide Tables Crew</itunes:author>
    <item>
      <title>Why the spring tide is late</title>
      <guid>https://example.com/tide/2</guid>
      <pubDate>Tue, 03 Nov 2026 06:00:00 GMT</pubDate>
      <itunes:duration>42:15</itunes:duration>
    </item>
    <item>
      <title>A short history of the lighthouse</title>
      <guid>https://example.com/tide/1</guid>
      <pubDate>Tue, 27 Oct 2026 06:00:00 GMT</pubDate>
      <itunes:duration>1:03:30</itunes:duration>
    </item>
  </channel>
</rss>`;

const RSS_091 = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="0.91">
  <channel>
    <title>Lighthouse Log</title>
    <link>https://example.com/log</link>
    <description>The oldest format the library reads, with a mandatory language</description>
    <language>en-gb</language>
    <item>
      <title>Lamp cleaned and wound</title>
      <link>https://example.com/log/lamp</link>
      <description>Routine maintenance before the winter season.</description>
    </item>
  </channel>
</rss>`;

const RSS_10 = `<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://purl.org/rss/1.0/"
  xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:slash="http://purl.org/rss/1.0/modules/slash/">
  <channel rdf:about="https://example.com/board">
    <title>Harbour Board</title>
    <link>https://example.com/board</link>
    <description>RSS 1.0 (RDF) with Dublin Core and Slash</description>
    <items>
      <rdf:Seq>
        <rdf:li rdf:resource="https://example.com/board/1"/>
      </rdf:Seq>
    </items>
  </channel>
  <item rdf:about="https://example.com/board/1">
    <title>New mooring fees from January</title>
    <link>https://example.com/board/1</link>
    <dc:creator>Harbour Master</dc:creator>
    <dc:date>2026-11-01T09:00:00Z</dc:date>
    <dc:subject>Fees</dc:subject>
    <slash:section>news</slash:section>
    <slash:comments>12</slash:comments>
  </item>
</rdf:RDF>`;

const ATOM_03 = `<?xml version="1.0" encoding="UTF-8"?>
<feed version="0.3" xmlns="http://purl.org/atom/ns#">
  <title>Old Notes</title>
  <link rel="alternate" type="text/html" href="https://example.com/old"/>
  <modified>2026-10-30T12:00:00Z</modified>
  <entry>
    <title>Atom 0.3 still parses</title>
    <link rel="alternate" type="text/html" href="https://example.com/old/1"/>
    <id>urn:example:old:1</id>
    <issued>2026-10-30T12:00:00Z</issued>
    <modified>2026-10-30T12:00:00Z</modified>
  </entry>
</feed>`;

const MEDIA_GEO = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/" xmlns:georss="http://www.georss.org/georss">
  <channel>
    <title>Coast Photos</title>
    <link>https://example.com/photos</link>
    <description>Media RSS and GeoRSS on each item</description>
    <item>
      <title>Sunrise over the breakwater</title>
      <link>https://example.com/photos/sunrise</link>
      <pubDate>Wed, 04 Nov 2026 06:40:00 GMT</pubDate>
      <media:content url="https://example.com/photos/sunrise.jpg" type="image/jpeg" medium="image"
        width="1600" height="1067" fileSize="482133"/>
      <media:thumbnail url="https://example.com/photos/sunrise-small.jpg" width="160" height="107"/>
      <media:keywords>sunrise, harbour, sea</media:keywords>
      <georss:point>50.3664 -4.1427</georss:point>
    </item>
  </channel>
</rss>`;

// Not well-formed on purpose: the item is never closed. Shows a parse error with its line and column.
const BROKEN = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Broken feed</title>
    <item>
      <title>This item is never closed</title>
  </channel>
</rss>`;

export const SAMPLES: Sample[] = [
  new Sample('RSS 2.0', RSS_20),
  new Sample('RSS 0.91', RSS_091),
  new Sample('RSS 1.0', RSS_10),
  new Sample('Atom 1.0', ATOM_10),
  new Sample('Atom 0.3', ATOM_03),
  new Sample('iTunes', PODCAST),
  new Sample('Media + Geo', MEDIA_GEO),
  new Sample('Broken', BROKEN)
];
