# oh_rome

RSS, Atom and OPML for HarmonyOS, in pure ArkTS: a port of the Java library [ROME](https://github.com/rometools/rome)
(commit `6b4a7e8`). It reads and writes feeds in every RSS, Atom and OPML version, converts between them through a common
`SyndFeed` model, and supports the common modules: iTunes, Media RSS, GeoRSS, Dublin Core, content, and others.

The port aims for the same output as ROME for the same input. Golden tests compare the parsed models, generated XML and
conversions with what ROME itself produces, over ROME's own test feeds. Where the port still differs, see
[Differences from ROME](#differences-from-rome).

## Install

```shell
ohpm install @explore-in-hmos/oh_rome
```

or in your module's `oh-package.json5`:

```json5
"dependencies": {
  "@explore-in-hmos/oh_rome": "^1.0.0"
}
```

Importing from `@explore-in-hmos/oh_rome` registers all parsers, generators, converters and modules.

## Permissions

None. The library does no I/O: you pass it a string or bytes, as with ROME. An app that downloads feeds needs
`ohos.permission.INTERNET` for its own HTTP requests.

## Usage

Parse any supported format into the common model:

```ts
import { SyndEntry, SyndFeed, SyndFeedInput } from '@explore-in-hmos/oh_rome';

const feed: SyndFeed = new SyndFeedInput().build(xml); // a string, a Uint8Array, or a Document
console.info(`${feed.feedType}: ${feed.title}`);
feed.entries.forEach((entry: SyndEntry) => {
  console.info(`${entry.title} ${entry.link} ${entry.publishedDate}`);
});
```

Bytes go through `XmlReader`, which applies ROME's encoding detection (BOM, XML prolog). A string isn't decoded; the XML
healer still runs on it unless you turn `xmlHealerOn` off.

A feed fetched over HTTP: pass the response bytes with the `Content-Type` header, so the HTTP charset rules apply as in
ROME's `new XmlReader(stream, contentType)`:

```ts
import { http } from '@kit.NetworkKit';
import { SyndFeed, SyndFeedInput, XmlReader } from '@explore-in-hmos/oh_rome';

async function load(url: string): Promise<SyndFeed | null> {
  const request = http.createHttp();
  try {
    const response = await request.request(url, { expectDataType: http.HttpDataType.ARRAY_BUFFER });
    const headers = response.header as Record<string, string>;
    const reader = new XmlReader(new Uint8Array(response.result as ArrayBuffer),
      headers['content-type'] ?? headers['Content-Type'] ?? null);
    return new SyndFeedInput().build(reader.read());
  } catch (e) {
    console.error(`Could not load ${url}: ${(e as Error).message}`);
    return null;
  } finally {
    request.destroy();
  }
}
```

Write it out, in the same format or another:

```ts
import { SyndFeedOutput } from '@explore-in-hmos/oh_rome';

feed.feedType = 'atom_1.0';
const atom: string = new SyndFeedOutput().outputString(feed);
```

As in ROME, every RSS format needs a channel title, description and link. RSS 0.90 limits them to 40, 500 and 500
characters, and RSS 0.91 (Netscape and Userland) also needs a `language`. An Atom feed with no `<subtitle>` has no
description, so writing it as `rss_2.0` throws `FeedException: Invalid rss_2.0 feed, missing channel description`; set
`feed.description` first.

Build a feed from scratch:

```ts
import { SyndContent, SyndEntry, SyndFeed, SyndFeedOutput } from '@explore-in-hmos/oh_rome';

const feed = new SyndFeed();
feed.feedType = 'rss_2.0';
feed.title = 'My feed';
feed.link = 'https://example.com/';
feed.description = 'News from example.com';
const entry = new SyndEntry();
entry.title = 'Hello';
entry.link = 'https://example.com/hello';
entry.publishedDate = new Date();
const description = new SyndContent();
description.type = 'text/plain';
description.value = 'First post';
entry.description = description;
feed.entries = [entry];
const xml: string = new SyndFeedOutput().outputString(feed);
```

Read module data from an entry:

```ts
import { EntryInformation, ITunes, MediaEntryModule, MediaModule } from '@explore-in-hmos/oh_rome';

const itunes = entry.getModule(ITunes.URI);
if (itunes instanceof EntryInformation) {
  console.info(`duration ${itunes.duration?.toString()}`);
}
const media = entry.getModule(MediaModule.URI);
if (media instanceof MediaEntryModule) {
  console.info(`${media.mediaContents.length} media items`);
}
```

Work with the format's own model through `WireFeedInput` and `WireFeedOutput`; OPML documents come back as `Opml`:

```ts
import { Channel, Opml, WireFeedInput } from '@explore-in-hmos/oh_rome';

const channel = new WireFeedInput().build(rssXml) as Channel;
const opml = new WireFeedInput().build(opmlXml) as Opml;
opml.outlines.forEach((outline) => console.info(`${outline.text} ${outline.xmlUrl}`));
```

## API

| Class | Use |
|---|---|
| `SyndFeedInput`, `SyndFeedOutput` | Parse any format into `SyndFeed`; write a `SyndFeed` in any format (`feedType`) |
| `SyndFeed`, `SyndEntry`, `SyndContent`, `SyndLink`, `SyndPerson`, `SyndCategory`, `SyndEnclosure`, `SyndImage` | The common model |
| `WireFeedInput`, `WireFeedOutput` | The same, with the format's own model: `Channel` (RSS), `Feed` (Atom), `Opml` |
| `XmlReader` | Bytes to text with ROME's encoding detection, optionally with an HTTP `Content-Type` |
| `ParsingFeedException`, `FeedException` | Parse and generation errors |
| `DCModule`, `ITunes`/`EntryInformation`/`FeedInformation`, `MediaModule`/`MediaEntryModule`, `GeoRSSModule`, `ContentModule`, `Slash`, `ThreadingModule`, `CreativeCommons`, `PodloveSimpleChapterModule`, `OpenSearchModule`, `AtomLinkModule` | Module data, through `getModule(URI)` on a feed or entry |
| `Atom10Parser.parseEntry` | Parse a single Atom entry |

Options, on both `SyndFeedInput` and `WireFeedInput`:

| Property | Default | Meaning |
|---|---|---|
| `xmlHealerOn` | `true` | Repairs common feed mistakes first: whitespace and comments before the XML declaration, HTML entities such as `&nbsp;`, stray `&` |
| `allowDoctypes` | `false` | Accepts a DOCTYPE. Off by default, as in ROME, so feeds with one are rejected; RSS 0.91 Netscape feeds need it |

`SyndFeedInput` also has `preserveWireFeed`, which keeps the original model for `feed.originalWireFeed()`.

Errors follow ROME: malformed XML and anything unexpected while parsing throw `ParsingFeedException` (with
`getLineNumber()` and `getColumnNumber()`), a document in no known format throws `IllegalArgumentException("Invalid
document")`, and `IllegalArgumentException` subclasses such as `NumberFormatException` pass through unwrapped.


## Supported formats

| Format | `feedType` | Read | Write |
|---|---|---|---|
| RSS 0.90 | `rss_0.9` | yes | yes |
| RSS 0.91 Netscape, Userland | `rss_0.91N`, `rss_0.91U` | yes | yes |
| RSS 0.92, 0.93, 0.94 | `rss_0.92`, `rss_0.93`, `rss_0.94` | yes | yes |
| RSS 1.0 | `rss_1.0` | yes | yes |
| RSS 2.0 | `rss_2.0` | yes | yes |
| RSS 2.0 with a namespace | `rss_2.0wNS` | yes, reported as `rss_2.0` | as `rss_2.0` |
| RSS 2.0 in Yahoo's `urn:yahoo:yn` namespace | `rss_2.0yahoo` | yes, reported as `rss_2.0` | as `rss_2.0` |
| Atom 0.3, 1.0 | `atom_0.3`, `atom_1.0` | yes | yes |
| OPML 1.0, 2.0 | `opml_1.0`, `opml_2.0` | yes | yes |

Modules: Dublin Core, Syndication, content, slash, iTunes, Media RSS, GeoRSS, Atom links, OpenSearch, Creative Commons,
Podlove Simple Chapters and threading. ROME's modules for dead services (base, yahooweather, feedburner, photocast, sle,
sse, feedpress, fyyd, portablecontacts) and activitystreams, which ROME registers no parser for, aren't included.

Java names carry over: a `getFoo()`/`setFoo()` pair is a `foo` property, including ROME's odd ones (`titleEx`,
`styleSheet`). A few classes are exported under other names because they would clash: `RssContent`, `RssCategory`,
`AtomContent`, `AtomCategory`, `MediaText`, `MediaCategory`, `ITunesCategory`, `OpmlAttribute`, `CCLicense`.

## Constraints

- HarmonyOS API 24 or later. The package is a bytecode HAR built with `compatibleSdkVersion` 24, so the app's own
  `compatibleSdkVersion` must be 24 or higher.
- No network or file access: the app fetches the feed and passes it in.
- Pure ArkTS, no native code. The only system API used is `util.TextDecoder`, for decoding bytes.
- The behaviour differences from ROME listed below.

## Differences from ROME

Everyday feeds aren't affected by these. All of them were found by comparing against ROME.

**Numbers**
- Java `long` values are `number`, so they lose precision above 2^53: enclosure lengths, `fileSize`, durations.

**Dates**
- Named zones such as `EST` or `MSK` use the zone's current offset. Java applies its historical rules, so dates before a
  zone's last rule change can differ.
- Extra date masks accept a subset of `SimpleDateFormat`'s letters (`G Y w W F u X` are rejected), and a bad mask throws
  when it's set.
- An unparseable `dc:date` is dropped, where ROME keeps a `null` in the list.

**XML**
- External DTDs and entities are never fetched, because the parser does no I/O.
- With `allowDoctypes` on, several DTD details differ: `<!ATTLIST>` defaults aren't applied, and markup inside an entity's
  replacement text isn't checked when the entity is used.
- Error columns are the parser's own. Lines and messages match Xerces, apart from a few DTD and XML 1.1 messages.

**Encodings**
- `XmlReader` doesn't decode 54 of the multi-byte charsets Java supports, and throws instead. Malformed CJK input follows
  the system decoder's (WHATWG) rules rather than Java's.
- `XMLOutputter` escapes for 45 multi-byte charsets with a generic rule rather than their real encoders.

**API shape**
- `Locale` and `validate` parameters are gone: dates use English names, as with ROME's `Locale.US`.
- `File`, `Reader`, `InputSource` and W3C DOM overloads don't exist. `XmlReader` is not a `Reader`: `read()` returns the
  whole decoded string.
- `equals`, `hashCode` and `toString` from ROME's reflection beans aren't ported unless ROME's own code calls them.
- Where Java throws `NullPointerException` or another runtime exception, the port throws a plain `Error`.

## Directory structure

```
oh_rome/
├── Index.ets              all exports
├── src/main/ets/
│   ├── feed/              models: rss/, atom/, synd/, module/ (Dublin Core, Syndication); synd/impl/ holds the
│   │                      converters
│   ├── io/                SyndFeedInput/Output, WireFeedInput/Output, XmlReader; impl/ holds the parsers,
│   │                      generators and the plugin registry
│   ├── modules/           content, itunes, mediarss, atom, thr, georss, opensearch, cc, psc, slash, each with its
│   │                      own parser and generator (mostly in <module>/io/)
│   ├── opml/              OPML models, parsers, generators and converters
│   ├── utils/             Java behaviour the port needs: numbers, dates, URLs
│   └── xml/               XML parser and writer (the JDOM API ROME uses)
└── src/test/              local unit and golden tests
```

The layout mirrors ROME's Java packages, one `.ets` file per Java file.

## Contributing

Issues and pull requests are welcome at <https://github.com/Explore-In-HMOS/library-rome>. Read `CONTRIBUTING.md` in the
repository first, then run `./scripts/check.sh`, which builds the library and the sample app and runs their local unit tests
(the on-device suite in `src/ohosTest` is run from DevEco Studio). A change in behaviour needs a reference to ROME's code or a run of
ROME.

## License

Apache-2.0, like ROME. The `LICENSE` file in this package includes the `NOTICE`, which also carries the notices of
Apache Xerces (the XML parser follows its code in OpenJDK 17), and the JDOM license, because the XML writer follows
JDOM 2.0.6.1.
