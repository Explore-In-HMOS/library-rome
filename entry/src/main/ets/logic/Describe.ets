import {
  AtomLinkModule, CCLicense, ContentModule, CreativeCommons, DCModule, EntryInformation, FeedInformation, GeoRSSModule, ITunes,
  ITunesCategory, LineString, MediaContent, MediaEntryModule, MediaModule, Module, Point, PodloveSimpleChapterModule,
  Polygon, SimpleChapter, Slash, SyModule, SyndCategory, SyndEnclosure, SyndEntry, SyndFeed, SyndPerson, ThreadingModule,
  Thumbnail, UrlReference
} from '@explore-in-hmos/oh_rome';
import { formatBytes, formatDate, plainText } from './Text';

export class DetailRow {
  readonly label: string;
  readonly value: string;

  constructor(label: string, value: string) {
    this.label = label;
    this.value = value;
  }
}

export class Section {
  readonly title: string;
  readonly rows: DetailRow[];

  constructor(title: string, rows: DetailRow[]) {
    this.title = title;
    this.rows = rows;
  }
}

const TEXT_MAX = 400;
const LIST_MAX = 5;

// Module URIs the demo shows in detail; anything else is listed by URI.
const MODULE_NAMES: Map<string, string> = new Map<string, string>([
  [DCModule.URI, 'Dublin Core'],
  [SyModule.URI, 'Syndication'],
  [AtomLinkModule.URI, 'Atom links'],
  [ITunes.URI, 'iTunes'],
  [MediaModule.URI, 'Media RSS'],
  [GeoRSSModule.GEORSS_GEORSS_URI, 'GeoRSS'],
  [GeoRSSModule.GEORSS_W3CGEO_URI, 'W3C Geo'],
  [GeoRSSModule.GEORSS_GML_URI, 'GeoRSS GML'],
  [ContentModule.URI, 'Content'],
  [Slash.URI, 'Slash'],
  [ThreadingModule.URI, 'Threading'],
  [CreativeCommons.URI, 'Creative Commons'],
  [PodloveSimpleChapterModule.URI, 'Podlove chapters']
]);

export function moduleName(uri: string): string {
  return MODULE_NAMES.get(uri) ?? uri;
}

// Builds a section from optional values: empty values are left out, so a section only lists what the feed has.
class Rows {
  readonly rows: DetailRow[] = [];

  add(label: string, value: string | number | boolean | null | undefined): Rows {
    if (value !== null && value !== undefined && String(value) !== '') {
      this.rows.push(new DetailRow(label, String(value)));
    }
    return this;
  }

  addList(label: string, values: string[]): Rows {
    const shown = values.filter((v: string) => v !== '');
    if (shown.length > 0) {
      const more = shown.length > LIST_MAX ? ` (+${shown.length - LIST_MAX} more)` : '';
      this.rows.push(new DetailRow(label, shown.slice(0, LIST_MAX).join(', ') + more));
    }
    return this;
  }

  section(title: string, out: Section[]): void {
    if (this.rows.length > 0) {
      out.push(new Section(title, this.rows));
    }
  }
}

function people(list: SyndPerson[]): string[] {
  return list.map((p: SyndPerson) => p.name ?? p.email ?? p.uri ?? '');
}

function categories(list: SyndCategory[]): string[] {
  return list.map((c: SyndCategory) => c.name ?? '');
}

function dcSection(module: Module | null, out: Section[]): void {
  if (module === null) {
    return;
  }
  const dc = module as DCModule;
  new Rows()
    .addList('Creator', dc.creators)
    .addList('Subject', dc.subjects.map((s) => s.value ?? ''))
    .add('Date', dc.date === null ? null : formatDate(dc.date))
    .addList('Publisher', dc.publishers)
    .addList('Rights', dc.rightsList)
    .addList('Language', dc.languages)
    .section('Dublin Core', out);
}

function itunesFeedSection(module: Module | null, out: Section[]): void {
  if (!(module instanceof FeedInformation)) {
    return;
  }
  const info = module as FeedInformation;
  new Rows()
    .add('Author', info.author)
    .add('Owner', info.ownerName)
    .add('Type', info.type)
    .add('Explicit', info.explicitNullable)
    .addList('Categories', info.categories.map((c: ITunesCategory) => c.name ?? ''))
    .add('Image', info.image)
    .add('Summary', plainText(info.summary, TEXT_MAX))
    .section('iTunes', out);
}

function itunesEntrySection(module: Module | null, out: Section[]): void {
  if (!(module instanceof EntryInformation)) {
    return;
  }
  const info = module as EntryInformation;
  new Rows()
    .add('Duration', info.duration === null ? null : info.duration.toString())
    .add('Season', info.season)
    .add('Episode', info.episode)
    .add('Episode type', info.episodeType)
    .add('Author', info.author)
    .add('Explicit', info.explicitNullable)
    .add('Subtitle', plainText(info.subtitle, TEXT_MAX))
    .section('iTunes', out);
}

function contentUrl(content: MediaContent): string {
  const reference = content.reference;
  return reference instanceof UrlReference ? (reference as UrlReference).url : 'player';
}

function mediaSection(module: Module | null, out: Section[]): void {
  if (!(module instanceof MediaEntryModule)) {
    return;
  }
  const media = module as MediaEntryModule;
  const rows = new Rows()
    .add('Contents', media.mediaContents.length > 0 ? media.mediaContents.length : null)
    .add('Groups', media.mediaGroups.length > 0 ? media.mediaGroups.length : null);
  const first: MediaContent | undefined = media.mediaContents[0];
  if (first !== undefined) {
    rows.add('First URL', contentUrl(first))
      .add('Type', first.type)
      .add('Medium', first.medium)
      .add('Duration (s)', first.duration)
      .add('Size', first.fileSize === null ? null : formatBytes(first.fileSize));
  }
  const metadata = media.metadata;
  if (metadata !== null) {
    rows.add('Title', metadata.title)
      .add('Description', plainText(metadata.description, TEXT_MAX))
      .addList('Thumbnails', metadata.thumbnail.map((t: Thumbnail) => t.url ?? ''))
      .addList('Keywords', metadata.keywords);
  }
  rows.section('Media RSS', out);
}

function geoSection(entry: SyndEntry, out: Section[]): void {
  const uris = [GeoRSSModule.GEORSS_GEORSS_URI, GeoRSSModule.GEORSS_W3CGEO_URI, GeoRSSModule.GEORSS_GML_URI];
  for (const uri of uris) {
    const module = entry.getModule(uri);
    if (module instanceof GeoRSSModule) {
      const geo = module as GeoRSSModule;
      const position = geo.position;
      const geometry = geo.geometry;
      const shape = geometry instanceof Point ? 'Point' : geometry instanceof LineString ? 'Line' :
        geometry instanceof Polygon ? 'Polygon' : geometry === null ? null : 'Other';
      new Rows()
        .add('Shape', shape)
        .add('Latitude', position === null ? null : position.latitude)
        .add('Longitude', position === null ? null : position.longitude)
        .add('Elevation', geo.elev)
        .add('Feature', geo.featureNameTag)
        .section(moduleName(uri), out);
    }
  }
}

function otherEntryModules(entry: SyndEntry, out: Section[]): void {
  const content = entry.getModule(ContentModule.URI);
  if (content instanceof ContentModule) {
    const encodeds = (content as ContentModule).encodeds;
    new Rows()
      .add('Encoded', encodeds.length > 0 ? `${encodeds.length} block(s), ${encodeds[0].length} chars` : null)
      .add('Text', plainText(encodeds[0] ?? null, TEXT_MAX))
      .section('Content', out);
  }
  const slash = entry.getModule(Slash.URI);
  if (slash instanceof Slash) {
    const s = slash as Slash;
    new Rows().add('Section', s.section).add('Department', s.department).add('Comments', s.comments).section('Slash', out);
  }
  const thr = entry.getModule(ThreadingModule.URI);
  if (thr instanceof ThreadingModule) {
    const t = thr as ThreadingModule;
    new Rows().add('In reply to', t.ref).add('Link', t.href).section('Threading', out);
  }
  const cc = entry.getModule(CreativeCommons.URI);
  if (cc instanceof CreativeCommons) {
    new Rows().addList('Licenses', ((cc as CreativeCommons).licenses ?? []).map((l: CCLicense) => l.value))
      .section('Creative Commons', out);
  }
  const psc = entry.getModule(PodloveSimpleChapterModule.URI);
  if (psc instanceof PodloveSimpleChapterModule) {
    new Rows().addList('Chapters', (psc as PodloveSimpleChapterModule).chapters
      .map((c: SimpleChapter) => `${c.start ?? '?'} ${c.title ?? ''}`)).section('Podlove chapters', out);
  }
}

function moduleList(modules: Module[]): string[] {
  return modules.map((m: Module) => moduleName(m.uri));
}

export function feedSections(feed: SyndFeed): Section[] {
  const out: Section[] = [];
  new Rows()
    .add('Type', feed.feedType)
    .add('Title', feed.title)
    .add('Link', feed.link)
    .add('Description', plainText(feed.description, TEXT_MAX))
    .add('Language', feed.language)
    .add('Published', feed.publishedDate === null ? null : formatDate(feed.publishedDate))
    .addList('Authors', people(feed.authors))
    .addList('Categories', categories(feed.categories))
    .add('Copyright', feed.copyright)
    .add('Generator', feed.generator)
    .add('Image', feed.image === null ? null : feed.image.url)
    .add('Encoding', feed.encoding)
    .add('Entries', feed.entries.length)
    .addList('Modules', moduleList(feed.modules))
    .section('Feed', out);
  itunesFeedSection(feed.getModule(ITunes.URI), out);
  dcSection(feed.getModule(DCModule.URI), out);
  return out;
}

export function entrySections(entry: SyndEntry): Section[] {
  const out: Section[] = [];
  new Rows()
    .add('Title', entry.title)
    .add('Link', entry.link)
    .add('URI', entry.uri)
    .add('Published', entry.publishedDate === null ? null : formatDate(entry.publishedDate))
    .add('Updated', entry.updatedDate === null ? null : formatDate(entry.updatedDate))
    .add('Author', entry.author)
    .addList('Categories', categories(entry.categories))
    .add('Description', plainText(entry.description === null ? null : entry.description.value, TEXT_MAX))
    .addList('Enclosures', entry.enclosures.map((e: SyndEnclosure) =>
      `${e.url ?? ''}${e.type === null ? '' : ` (${e.type})`}`))
    .addList('Modules', moduleList(entry.modules))
    .section('Entry', out);
  itunesEntrySection(entry.getModule(ITunes.URI), out);
  mediaSection(entry.getModule(MediaModule.URI), out);
  geoSection(entry, out);
  otherEntryModules(entry, out);
  dcSection(entry.getModule(DCModule.URI), out);
  return out;
}

// One line under an entry's title in a list: its date, and the iTunes duration when there is one.
export function entrySummary(entry: SyndEntry): string {
  const date = formatDate(entry.publishedDate ?? entry.updatedDate);
  const itunes = entry.getModule(ITunes.URI);
  const duration = itunes instanceof EntryInformation ? (itunes as EntryInformation).duration : null;
  return duration === null ? date : `${date} · ${duration.toString()}`;
}

export function entryKey(entry: SyndEntry, index: number): string {
  return `${index}:${entry.uri ?? entry.link ?? entry.title ?? ''}`;
}
