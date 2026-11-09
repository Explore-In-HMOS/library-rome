import { Opml, OpmlAttribute, Outline, WireFeedInput, WireFeedOutput } from 'oh_rome';

export class Subscription {
  readonly name: string;
  readonly note: string;
  readonly url: string;
  readonly group: string;

  constructor(name: string, note: string, url: string, group: string) {
    this.name = name;
    this.note = note;
    this.url = url;
    this.group = group;
  }
}

export class OutlineRow {
  readonly depth: number;
  readonly text: string;
  readonly url: string | null;

  constructor(depth: number, text: string, url: string | null) {
    this.depth = depth;
    this.text = text;
    this.url = url;
  }
}

export function parseOpml(xml: string): Opml {
  const feed = new WireFeedInput().build(xml);
  if (!(feed instanceof Opml)) {
    throw new Error(`Not an OPML document: ${feed.feedType}`);
  }
  return feed as Opml;
}

function walk(outlines: Outline[], depth: number, rows: OutlineRow[]): void {
  for (const outline of outlines) {
    rows.push(new OutlineRow(depth, outline.text ?? outline.title ?? '', outline.xmlUrl));
    walk(outline.children, depth + 1, rows);
  }
}

export function outlineRows(opml: Opml): OutlineRow[] {
  const rows: OutlineRow[] = [];
  walk(opml.outlines, 0, rows);
  return rows;
}

function collect(outlines: Outline[], group: string, out: Subscription[]): void {
  for (const outline of outlines) {
    const url = outline.xmlUrl;
    if (url !== null) {
      out.push(new Subscription(outline.text ?? url, outline.title ?? '', url, group));
    }
    collect(outline.children, url === null ? (outline.text ?? group) : group, out);
  }
}

export function subscriptionsOf(opml: Opml): Subscription[] {
  const out: Subscription[] = [];
  collect(opml.outlines, '', out);
  return out;
}

// The subscription list written back out as OPML 2.0, the way a reader exports it.
export function exportOpml(title: string, subscriptions: Subscription[]): string {
  const opml = new Opml();
  opml.feedType = 'opml_2.0';
  opml.title = title;
  opml.outlines = subscriptions.map((s: Subscription) => {
    const outline = new Outline('rss', s.name);
    outline.title = s.note === '' ? null : s.note;
    outline.attributes.push(new OpmlAttribute('xmlUrl', s.url));
    return outline;
  });
  return new WireFeedOutput().outputString(opml);
}
