// Ported from ROME rome-opml/src/main/java/com/rometools/opml/feed/synd/impl/ConverterForOPML10.java (Apache-2.0)
import { WireFeed } from '../../../../feed/WireFeed';
import { Converter } from '../../../../feed/synd/Converter';
import { SyndCategory } from '../../../../feed/synd/SyndCategory';
import { SyndContent } from '../../../../feed/synd/SyndContent';
import { SyndEntry } from '../../../../feed/synd/SyndEntry';
import { SyndFeed } from '../../../../feed/synd/SyndFeed';
import { SyndLink } from '../../../../feed/synd/SyndLink';
import { SyndPerson } from '../../../../feed/synd/SyndPerson';
import { Attribute } from '../../opml/Attribute';
import { Opml } from '../../opml/Opml';
import { Outline } from '../../opml/Outline';
import { TreeCategoryImpl } from './TreeCategoryImpl';

class OutlineHolder {
  readonly outline: Outline;
  readonly parent: string;

  constructor(outline: Outline, parent: string) {
    this.outline = outline;
    this.parent = parent;
  }
}

// Java names nodes after Outline.hashCode(), the String hash of its reflective toString(): outlines with equal
// content share a node id. The Java String hash of the JSON form keeps that.
function nodeHash(outline: Outline): number {
  const s = JSON.stringify(outline);
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(h, 31) + s.charCodeAt(i)) | 0;
  }
  return h;
}

export class ConverterForOPML10 implements Converter {
  static readonly URI_TREE: string = 'urn:rome.tree';
  static readonly URI_ATTRIBUTE: string = 'urn:rome.attribute#';

  getType(): string {
    return 'opml_1.0';
  }

  protected addOwner(opml: Opml, syndFeed: SyndFeed): void {
    if (opml.ownerEmail !== null || opml.ownerName !== null) {
      const person = new SyndPerson();
      person.email = opml.ownerEmail;
      person.name = opml.ownerName;
      syndFeed.authors = [person];
    }
  }

  copyInto(feed: WireFeed, syndFeed: SyndFeed): void {
    const opml = feed as Opml;
    syndFeed.title = opml.title;
    this.addOwner(opml, syndFeed);
    syndFeed.publishedDate = opml.modified !== null ? opml.modified : opml.created;
    syndFeed.feedType = opml.feedType;
    syndFeed.modules = opml.modules;
    syndFeed.feedType = this.getType();
    this.createEntries([], syndFeed.entries, opml.outlines);
  }

  protected createEntries(context: number[], allEntries: SyndEntry[], outlines: Outline[]): void {
    for (const outline of outlines) {
      this.createEntry(context, allEntries, outline);
    }
  }

  protected createEntry(context: number[], allEntries: SyndEntry[], outline: Outline): SyndEntry {
    const entry = new SyndEntry();
    if (outline.type === 'rss') {
      entry.link = outline.htmlUrl !== null ? outline.htmlUrl : outline.xmlUrl;
    } else if (outline.type === 'link') {
      entry.link = outline.url;
    }
    if (outline.htmlUrl !== null) {
      entry.links.push(ConverterForOPML10.alternate('text/html', outline.htmlUrl));
      entry.link = outline.htmlUrl;
    }
    const type = outline.type === null ? null : outline.type.toUpperCase();
    if (outline.xmlUrl !== null && type === 'RSS') {
      entry.links.push(ConverterForOPML10.alternate('application/rss+xml', outline.xmlUrl));
      if (entry.link === null) {
        entry.link = outline.xmlUrl;
      }
    }
    if (outline.xmlUrl !== null && type === 'ATOM') {
      entry.links.push(ConverterForOPML10.alternate('application/atom+xml', outline.xmlUrl));
      if (entry.link === null) {
        entry.link = outline.xmlUrl;
      }
    }
    entry.title = outline.type === 'rss' ? outline.title : outline.text;
    if (outline.text === null && entry.title !== null) {
      const c = new SyndContent();
      c.value = outline.text;
      entry.description = c;
    }
    entry.publishedDate = outline.created;
    const hash = nodeHash(outline);
    entry.categories.push(ConverterForOPML10.treeCategory(`node.${hash}`));
    if (context.length > 0) {
      entry.categories.push(ConverterForOPML10.treeCategory(`parent.${context[context.length - 1]}`));
    }
    for (const a of outline.attributes) {
      const acat = new SyndCategory();
      acat.name = a.value;
      acat.taxonomyUri = ConverterForOPML10.URI_ATTRIBUTE + a.name;
      entry.categories.push(acat);
    }
    entry.modules = outline.modules;
    allEntries.push(entry);
    context.push(hash);
    this.createEntries(context, allEntries, outline.children);
    context.pop();
    return entry;
  }

  createRealFeed(syndFeed: SyndFeed): WireFeed {
    const entriesByNode = new Map<string, Outline>();
    const doAfterPass: OutlineHolder[] = [];
    const root: Outline[] = [];
    for (const entry of syndFeed.entries) {
      const o = new Outline();
      let parentFound = false;
      let category = '';
      for (const cat of entry.categories) {
        if (cat.taxonomyUri === ConverterForOPML10.URI_TREE) {
          const name = cat.name!;
          const dot = name.lastIndexOf('.');
          if (dot < 0) {
            throw new Error(`begin -1, end ${name.length}, length ${name.length}`); // StringIndexOutOfBoundsException
          }
          const nodeVal = name.substring(dot);
          if (name.startsWith('node.')) {
            entriesByNode.set(nodeVal, o);
          } else if (name.startsWith('parent.')) {
            parentFound = true;
            const parent = entriesByNode.get(nodeVal);
            if (parent !== undefined) {
              parent.children.push(o);
            } else {
              doAfterPass.push(new OutlineHolder(o, nodeVal));
            }
          }
        } else if (cat.taxonomyUri !== null && cat.taxonomyUri.startsWith(ConverterForOPML10.URI_ATTRIBUTE)) {
          const name = cat.taxonomyUri.substring(cat.taxonomyUri.indexOf('#') + 1);
          o.attributes.push(new Attribute(name, cat.name!));
        } else {
          if (category.length > 0) {
            category += ', ';
          }
          category += `${cat.name}`;
        }
      }
      if (!parentFound) {
        root.push(o);
      }
      if (category.length > 0) {
        o.attributes.push(new Attribute('category', category));
      }
      for (const link of entry.links) {
        if (link.type !== null && link.rel === 'alternate' &&
          (link.type === 'application/rss+xml' || link.type === 'application/atom+xml')) {
          o.type = 'rss';
          if (o.xmlUrl === null) {
            o.attributes.push(new Attribute('xmlUrl', link.href!));
          }
        } else if (link.type === 'text/html') {
          if (o.htmlUrl === null) {
            o.attributes.push(new Attribute('htmlUrl', link.href!));
          }
        } else {
          o.type = link.type;
        }
      }
      if (o.type === null || o.type === 'link') {
        o.text = entry.title;
      } else {
        o.title = entry.title;
      }
      if (o.text === null && entry.description !== null) {
        o.text = entry.description.value;
      }
    }
    for (const holder of doAfterPass) {
      const parent = entriesByNode.get(holder.parent);
      if (parent === undefined) {
        root.push(holder.outline);
      } else {
        parent.children.push(holder.outline);
      }
    }
    const opml = new Opml();
    opml.feedType = this.getType();
    opml.created = syndFeed.publishedDate;
    opml.title = syndFeed.title;
    for (const p of syndFeed.authors) {
      if (syndFeed.author === null || syndFeed.author === p.name) {
        opml.ownerName = p.name;
        opml.ownerEmail = p.email;
        opml.ownerId = p.uri;
      }
    }
    opml.outlines = root;
    return opml;
  }

  private static alternate(type: string, href: string): SyndLink {
    const link = new SyndLink();
    link.rel = 'alternate';
    link.type = type;
    link.href = href;
    return link;
  }

  private static treeCategory(name: string): SyndCategory {
    const cat = new TreeCategoryImpl();
    cat.taxonomyUri = ConverterForOPML10.URI_TREE;
    cat.name = name;
    return cat;
  }
}
