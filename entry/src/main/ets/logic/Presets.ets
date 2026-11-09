// Public feeds for trying the library on real data, stored as OPML so the subscription list itself goes through the
// library's OPML parser. Picked to cover RSS 2.0, RSS 1.0 (RDF), Atom 1.0, an iTunes podcast, Media RSS, GeoRSS, a
// non-UTF-8 encoding and non-Latin text.
export const PRESETS_OPML = `<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <head>
    <title>oh_rome demo subscriptions</title>
  </head>
  <body>
    <outline text="News">
      <outline type="rss" text="BBC News" title="RSS 2.0 with Media RSS thumbnails"
        xmlUrl="https://feeds.bbci.co.uk/news/rss.xml" htmlUrl="https://www.bbc.co.uk/news"/>
      <outline type="rss" text="NHK News" title="RSS 2.0 in Japanese"
        xmlUrl="https://www3.nhk.or.jp/rss/news/cat0.xml" htmlUrl="https://www3.nhk.or.jp/news/"/>
      <outline type="rss" text="Slashdot" title="RSS 1.0 (RDF) in ISO-8859-1, with the Slash module"
        xmlUrl="https://rss.slashdot.org/Slashdot/slashdotMain" htmlUrl="https://slashdot.org/"/>
      <outline type="rss" text="Hacker News" title="Plain RSS 2.0"
        xmlUrl="https://news.ycombinator.com/rss" htmlUrl="https://news.ycombinator.com/"/>
    </outline>
    <outline text="Blogs and science">
      <outline type="rss" text="The Verge" title="Atom 1.0 with threading"
        xmlUrl="https://www.theverge.com/rss/index.xml" htmlUrl="https://www.theverge.com/"/>
      <outline type="rss" text="xkcd" title="Small Atom 1.0"
        xmlUrl="https://xkcd.com/atom.xml" htmlUrl="https://xkcd.com/"/>
      <outline type="rss" text="NASA" title="RSS 2.0 with content:encoded"
        xmlUrl="https://www.nasa.gov/news-release/feed/" htmlUrl="https://www.nasa.gov/"/>
      <outline type="rss" text="USGS earthquakes" title="Atom 1.0 with GeoRSS"
        xmlUrl="https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.atom"
        htmlUrl="https://earthquake.usgs.gov/"/>
    </outline>
    <outline text="Podcasts">
      <outline type="rss" text="Planet Money" title="iTunes podcast, about 2 MB"
        xmlUrl="https://feeds.npr.org/510289/podcast.xml" htmlUrl="https://www.npr.org/podcasts/510289/planet-money"/>
    </outline>
  </body>
</opml>`;
