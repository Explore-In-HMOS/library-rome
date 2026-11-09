// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/Atom10Generator.java (Apache-2.0)
import { Attribute, Document, Element, Namespace } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Category } from '../../feed/atom/Category';
import { Content } from '../../feed/atom/Content';
import { Entry } from '../../feed/atom/Entry';
import { Feed } from '../../feed/atom/Feed';
import { Generator } from '../../feed/atom/Generator';
import { Link } from '../../feed/atom/Link';
import { SyndPerson } from '../../feed/synd/SyndPerson';
import { XMLOutputter } from '../../xml/XmlOutputter';
import { parseXmlChildren } from './Atom03Generator';
import { BaseWireFeedGenerator } from './BaseWireFeedGenerator';
import { DateParser } from './DateParser';
import { plugins } from './PluginRegistry';

const ATOM_10_URI = 'http://www.w3.org/2005/Atom';
const ATOM_NS: Namespace = Namespace.getNamespace(ATOM_10_URI);

export class Atom10Generator extends BaseWireFeedGenerator {
  private readonly version: string;

  constructor(type?: string, version?: string) {
    super(type === undefined ? 'atom_1.0' : type);
    this.version = version === undefined ? '1.0' : version;
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

    const xmlBase = feed.xmlBase;
    if (xmlBase !== null) {
      root.setAttribute('base', xmlBase, Namespace.XML_NAMESPACE);
    }

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
    this.generateForeignMarkup(eFeed, feed.foreignMarkup);
    this.checkFeedHeaderConstraints(eFeed);
    this.generateFeedModules(feed.modules, eFeed);
  }

  protected addEntries(feed: Feed, parent: Element): void {
    for (const entry of feed.entries) {
      this.addEntry(entry, parent);
    }
    this.checkEntriesConstraints(parent);
  }

  protected addEntry(entry: Entry, parent: Element): void {
    const eEntry = new Element('entry', this.getFeedNamespace());

    const xmlBase = entry.xmlBase;
    if (xmlBase !== null) {
      eEntry.setAttribute('base', xmlBase, Namespace.XML_NAMESPACE);
    }

    this.populateEntry(entry, eEntry);
    this.generateForeignMarkup(eEntry, entry.foreignMarkup);
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

    for (const category of feed.categories) {
      eFeed.addContent(this.generateCategoryElement(category));
    }

    for (const author of feed.authors) {
      const authorElement = new Element('author', this.getFeedNamespace());
      this.fillPersonElement(authorElement, author);
      eFeed.addContent(authorElement);
    }

    for (const contributor of feed.contributors) {
      const contributorElement = new Element('contributor', this.getFeedNamespace());
      this.fillPersonElement(contributorElement, contributor);
      eFeed.addContent(contributorElement);
    }

    const subtitle = feed.subtitle;
    if (subtitle !== null) {
      const subtitleElement = new Element('subtitle', this.getFeedNamespace());
      this.fillContentElement(subtitleElement, subtitle);
      eFeed.addContent(subtitleElement);
    }

    const id = feed.id;
    if (id !== null) {
      eFeed.addContent(this.generateSimpleElement('id', id));
    }

    const generator = feed.generator;
    if (generator !== null) {
      eFeed.addContent(this.generateGeneratorElement(generator));
    }

    const rights = feed.rights;
    if (rights !== null) {
      eFeed.addContent(this.generateSimpleElement('rights', rights));
    }

    const icon = feed.icon;
    if (icon !== null) {
      eFeed.addContent(this.generateSimpleElement('icon', icon));
    }

    const logo = feed.logo;
    if (logo !== null) {
      eFeed.addContent(this.generateSimpleElement('logo', logo));
    }

    const updated = feed.updated;
    if (updated !== null) {
      eFeed.addContent(this.generateDateElement('updated', updated));
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

    for (const category of entry.categories) {
      eEntry.addContent(this.generateCategoryElement(category));
    }

    for (const author of entry.authors) {
      const authorElement = new Element('author', this.getFeedNamespace());
      this.fillPersonElement(authorElement, author);
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

    const updated = entry.updated;
    if (updated !== null) {
      eEntry.addContent(this.generateDateElement('updated', updated));
    }

    const published = entry.published;
    if (published !== null) {
      eEntry.addContent(this.generateDateElement('published', published));
    }

    const contents = entry.contents;
    if (contents.length > 0) {
      const contentElement = new Element('content', this.getFeedNamespace());
      this.fillContentElement(contentElement, contents[0]);
      eEntry.addContent(contentElement);
    }

    const summary = entry.summary;
    if (summary !== null) {
      const summaryElement = new Element('summary', this.getFeedNamespace());
      this.fillContentElement(summaryElement, summary);
      eEntry.addContent(summaryElement);
    }

    const source = entry.source;
    if (source !== null) {
      const sourceElement = new Element('source', this.getFeedNamespace());
      this.populateFeedHeader(source, sourceElement);
      eEntry.addContent(sourceElement);
    }

    const rights = entry.rights;
    if (rights !== null) {
      eEntry.addContent(this.generateSimpleElement('rights', rights));
    }
  }

  protected checkFeedHeaderConstraints(eFeed: Element): void {
  }

  protected checkEntriesConstraints(parent: Element): void {
  }

  protected checkEntryConstraints(eEntry: Element): void {
  }

  protected generateCategoryElement(cat: Category): Element {
    const catElement = new Element('category', this.getFeedNamespace());

    const term = cat.term;
    if (term !== null) {
      catElement.setAttribute(new Attribute('term', term));
    }

    const label = cat.label;
    if (label !== null) {
      catElement.setAttribute(new Attribute('label', label));
    }

    const scheme = cat.scheme;
    if (scheme !== null) {
      catElement.setAttribute(new Attribute('scheme', scheme));
    }

    return catElement;
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

    const hreflang = link.hreflang;
    if (hreflang !== null) {
      linkElement.setAttribute(new Attribute('hreflang', hreflang));
    }

    const linkTitle = link.title;
    if (linkTitle !== null) {
      linkElement.setAttribute(new Attribute('title', linkTitle));
    }

    if (link.length !== 0) {
      linkElement.setAttribute(new Attribute('length', link.length.toString()));
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
      element.addContent(this.generateSimpleElement('uri', uri));
    }

    const email = person.email;
    if (email !== null) {
      element.addContent(this.generateSimpleElement('email', email));
    }

    this.generatePersonModules(person.modules, element);
  }

  protected generateTagLineElement(tagline: Content): Element {
    const taglineElement = new Element('subtitle', this.getFeedNamespace());

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
    let atomType = type;

    if (type !== null) {
      // Content types set by converters or callers are mapped to Atom text types (ROME issue #39).
      if (type === 'text/plain') {
        atomType = Content.TEXT;
      } else if (type === 'text/html') {
        atomType = Content.HTML;
      } else if (type === 'application/xhtml+xml') {
        atomType = Content.XHTML;
      }
      contentElement.setAttribute(new Attribute('type', atomType!));
    }

    const href = content.src;
    if (href !== null) {
      contentElement.setAttribute(new Attribute('src', href));
    }

    const value = content.value;
    if (value !== null) {
      if (atomType !== null &&
        (atomType === Content.XHTML || atomType.indexOf('/xml') !== -1 || atomType.indexOf('+xml') !== -1)) {
        contentElement.addContent(parseXmlChildren(value));
      } else {
        contentElement.addContent(value);
      }
    }
  }

  protected generateGeneratorElement(generator: Generator): Element {
    const generatorElement = new Element('generator', this.getFeedNamespace());

    const url = generator.url;
    if (url !== null) {
      generatorElement.setAttribute(new Attribute('uri', url));
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

  // ROME writes to a Writer; this returns the string. The feed goes through the registered atom_1.0 generator, as
  // WireFeedOutput.outputJDom does.
  static serializeEntry(entry: Entry): string {
    const feed1 = new Feed();
    feed1.feedType = 'atom_1.0';
    feed1.entries = [entry];

    const generator = plugins().getFeedGenerator('atom_1.0');
    if (generator === null) {
      throw new Error('Invalid feed type [atom_1.0]');
    }
    const feedDoc = generator.generate(feed1);

    const entryElement = feedDoc.getRootElement().getChildren()[0];
    return new XMLOutputter().outputString(entryElement);
  }

  private generateDateElement(name: string, date: Date): Element {
    const element = new Element(name, this.getFeedNamespace());
    element.addContent(DateParser.formatW3CDateTime(date));
    return element;
  }
}
