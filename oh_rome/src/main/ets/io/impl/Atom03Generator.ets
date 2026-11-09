// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/Atom03Generator.java (Apache-2.0)
import { Attribute, Content as XmlContent, Document, Element, Namespace } from '../../xml/Dom';
import { parseXml } from '../../xml/XmlParser';
import { WireFeed } from '../../feed/WireFeed';
import { Content } from '../../feed/atom/Content';
import { Entry } from '../../feed/atom/Entry';
import { Feed } from '../../feed/atom/Feed';
import { Generator } from '../../feed/atom/Generator';
import { Link } from '../../feed/atom/Link';
import { SyndPerson } from '../../feed/synd/SyndPerson';
import { FeedException } from '../FeedException';
import { Base64 } from './Base64';
import { BaseWireFeedGenerator } from './BaseWireFeedGenerator';
import { DateParser } from './DateParser';

const ATOM_03_URI = 'http://purl.org/atom/ns#';
const ATOM_NS: Namespace = Namespace.getNamespace(ATOM_03_URI);

export class Atom03Generator extends BaseWireFeedGenerator {
  private readonly version: string;

  constructor(type?: string, version?: string) {
    super(type === undefined ? 'atom_0.3' : type);
    this.version = version === undefined ? '0.3' : version;
  }

  protected getVersion(): string {
    return this.version;
  }

  protected getFeedNamespace(): Namespace {
    return ATOM_NS;
  }

  generate(wFeed: WireFeed): Document {
    const feed = wFeed as Feed;
    const root = this.createRootElement(feed);
    this.populateFeed(feed, root);
    BaseWireFeedGenerator.purgeUnusedNamespaceDeclarations(root);
    return this.createDocument(root);
  }

  protected createDocument(root: Element): Document {
    return new Document(root);
  }

  protected createRootElement(feed: Feed): Element {
    const root = new Element('feed', this.getFeedNamespace());
    root.addNamespaceDeclaration(this.getFeedNamespace());
    root.setAttribute(new Attribute('version', this.getVersion()));
    this.generateModuleNamespaceDefs(root);
    return root;
  }

  protected populateFeed(feed: Feed, parent: Element): void {
    this.addFeed(feed, parent);
    this.addEntries(feed, parent);
  }

  protected addFeed(feed: Feed, parent: Element): void {
    const eFeed = parent;
    this.populateFeedHeader(feed, eFeed);
    this.checkFeedHeaderConstraints(eFeed);
    this.generateFeedModules(feed.modules, eFeed);
    this.generateForeignMarkup(eFeed, feed.foreignMarkup);
  }

  protected addEntries(feed: Feed, parent: Element): void {
    for (const entry of feed.entries) {
      this.addEntry(entry, parent);
    }
    this.checkEntriesConstraints(parent);
  }

  protected addEntry(entry: Entry, parent: Element): void {
    const eEntry = new Element('entry', this.getFeedNamespace());
    this.populateEntry(entry, eEntry);
    this.checkEntryConstraints(eEntry);
    this.generateItemModules(entry.modules, eEntry);
    parent.addContent(eEntry);
  }

  protected populateFeedHeader(feed: Feed, eFeed: Element): void {
    const titleEx = feed.titleEx;
    if (titleEx !== null) {
      const titleElement = new Element('title', this.getFeedNamespace());
      this.fillContentElement(titleElement, titleEx);
      eFeed.addContent(titleElement);
    }

    for (const link of feed.alternateLinks) {
      eFeed.addContent(this.generateLinkElement(link));
    }

    for (const link of feed.otherLinks) {
      eFeed.addContent(this.generateLinkElement(link));
    }

    const authors = feed.authors;
    if (authors.length > 0) {
      const authorElement = new Element('author', this.getFeedNamespace());
      this.fillPersonElement(authorElement, authors[0]);
      eFeed.addContent(authorElement);
    }

    for (const contributor of feed.contributors) {
      const contributorElement = new Element('contributor', this.getFeedNamespace());
      this.fillPersonElement(contributorElement, contributor);
      eFeed.addContent(contributorElement);
    }

    const tagline = feed.tagline;
    if (tagline !== null) {
      const taglineElement = new Element('tagline', this.getFeedNamespace());
      this.fillContentElement(taglineElement, tagline);
      eFeed.addContent(taglineElement);
    }

    const id = feed.id;
    if (id !== null) {
      eFeed.addContent(this.generateSimpleElement('id', id));
    }

    const generator = feed.generator;
    if (generator !== null) {
      eFeed.addContent(this.generateGeneratorElement(generator));
    }

    const copyright = feed.copyright;
    if (copyright !== null) {
      eFeed.addContent(this.generateSimpleElement('copyright', copyright));
    }

    const info = feed.info;
    if (info !== null) {
      const infoElement = new Element('info', this.getFeedNamespace());
      this.fillContentElement(infoElement, info);
      eFeed.addContent(infoElement);
    }

    const modified = feed.modified;
    if (modified !== null) {
      eFeed.addContent(this.generateDateElement('modified', modified));
    }
  }

  protected populateEntry(entry: Entry, eEntry: Element): void {
    const titleEx = entry.titleEx;
    if (titleEx !== null) {
      const titleElement = new Element('title', this.getFeedNamespace());
      this.fillContentElement(titleElement, titleEx);
      eEntry.addContent(titleElement);
    }

    for (const link of entry.alternateLinks) {
      eEntry.addContent(this.generateLinkElement(link));
    }

    for (const link of entry.otherLinks) {
      eEntry.addContent(this.generateLinkElement(link));
    }

    const authors = entry.authors;
    if (authors.length > 0) {
      const authorElement = new Element('author', this.getFeedNamespace());
      this.fillPersonElement(authorElement, authors[0]);
      eEntry.addContent(authorElement);
    }

    for (const contributor of entry.contributors) {
      const contributorElement = new Element('contributor', this.getFeedNamespace());
      this.fillPersonElement(contributorElement, contributor);
      eEntry.addContent(contributorElement);
    }

    const id = entry.id;
    if (id !== null) {
      eEntry.addContent(this.generateSimpleElement('id', id));
    }

    const modified = entry.modified;
    if (modified !== null) {
      eEntry.addContent(this.generateDateElement('modified', modified));
    }

    const issued = entry.issued;
    if (issued !== null) {
      eEntry.addContent(this.generateDateElement('issued', issued));
    }

    const created = entry.created;
    if (created !== null) {
      eEntry.addContent(this.generateDateElement('created', created));
    }

    const summary = entry.summary;
    if (summary !== null) {
      const summaryElement = new Element('summary', this.getFeedNamespace());
      this.fillContentElement(summaryElement, summary);
      eEntry.addContent(summaryElement);
    }

    for (const content of entry.contents) {
      const contentElement = new Element('content', this.getFeedNamespace());
      this.fillContentElement(contentElement, content);
      eEntry.addContent(contentElement);
    }

    this.generateForeignMarkup(eEntry, entry.foreignMarkup);
  }

  protected checkFeedHeaderConstraints(eFeed: Element): void {
  }

  protected checkEntriesConstraints(parent: Element): void {
  }

  protected checkEntryConstraints(eEntry: Element): void {
  }

  protected generateLinkElement(link: Link): Element {
    const linkElement = new Element('link', this.getFeedNamespace());

    const rel = link.rel;
    if (rel !== null) {
      linkElement.setAttribute(new Attribute('rel', rel));
    }

    const type = link.type;
    if (type !== null) {
      linkElement.setAttribute(new Attribute('type', type));
    }

    const href = link.href;
    if (href !== null) {
      linkElement.setAttribute(new Attribute('href', href));
    }

    return linkElement;
  }

  protected fillPersonElement(element: Element, person: SyndPerson): void {
    const name = person.name;
    if (name !== null) {
      element.addContent(this.generateSimpleElement('name', name));
    }

    const uri = person.uri;
    if (uri !== null) {
      element.addContent(this.generateSimpleElement('url', uri));
    }

    const email = person.email;
    if (email !== null) {
      element.addContent(this.generateSimpleElement('email', email));
    }
  }

  protected generateTagLineElement(tagline: Content): Element {
    const taglineElement = new Element('tagline', this.getFeedNamespace());

    const type = tagline.type;
    if (type !== null) {
      taglineElement.setAttribute(new Attribute('type', type));
    }

    const value = tagline.value;
    if (value !== null) {
      taglineElement.addContent(value);
    }

    return taglineElement;
  }

  protected fillContentElement(contentElement: Element, content: Content): void {
    const type = content.type;
    if (type !== null) {
      contentElement.setAttribute(new Attribute('type', type));
    }

    const mode = content.mode;
    if (mode !== null) {
      contentElement.setAttribute(new Attribute('mode', mode));
    }

    const value = content.value;
    if (value !== null) {
      if (mode === null || mode === Content.ESCAPED) {
        contentElement.addContent(value);
      } else if (mode === Content.BASE64) {
        contentElement.addContent(Base64.encode(value));
      } else if (mode === Content.XML) {
        contentElement.addContent(parseXmlChildren(value));
      }
    }
  }

  protected generateGeneratorElement(generator: Generator): Element {
    const generatorElement = new Element('generator', this.getFeedNamespace());

    const url = generator.url;
    if (url !== null) {
      generatorElement.setAttribute(new Attribute('url', url));
    }

    const version = generator.version;
    if (version !== null) {
      generatorElement.setAttribute(new Attribute('version', version));
    }

    const value = generator.value;
    if (value !== null) {
      generatorElement.addContent(value);
    }

    return generatorElement;
  }

  protected generateSimpleElement(name: string, value: string): Element {
    const element = new Element(name, this.getFeedNamespace());
    element.addContent(value);
    return element;
  }

  private generateDateElement(name: string, date: Date): Element {
    const element = new Element(name, this.getFeedNamespace());
    element.addContent(DateParser.formatW3CDateTime(date));
    return element;
  }
}

// The content of <tmpdoc>value</tmpdoc>, detached; ROME builds that document with SAXBuilder.
export function parseXmlChildren(value: string): XmlContent[] {
  let tmpDoc: Document;
  try {
    tmpDoc = parseXml(`<tmpdoc>${value}</tmpdoc>`);
  } catch (e) {
    throw new FeedException('Invalid XML', e as Error);
  }
  return tmpDoc.getRootElement().removeContent();
}
