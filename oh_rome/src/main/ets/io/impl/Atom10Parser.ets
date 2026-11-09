// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/Atom10Parser.java (Apache-2.0)
import { Attribute, Document, Element, Namespace, Parent } from '../../xml/Dom';
import { XMLOutputter } from '../../xml/XmlOutputter';
import { WireFeed } from '../../feed/WireFeed';
import { Category } from '../../feed/atom/Category';
import { Content } from '../../feed/atom/Content';
import { Entry } from '../../feed/atom/Entry';
import { Feed } from '../../feed/atom/Feed';
import { Generator } from '../../feed/atom/Generator';
import { Link } from '../../feed/atom/Link';
import { Person } from '../../feed/atom/Person';
import { SyndPerson } from '../../feed/synd/SyndPerson';
import { Strings } from '../../utils/Strings';
import { parseXml } from '../../xml/XmlParser';
import { FeedException } from '../FeedException';
import { WireFeedInput } from '../WireFeedInput';
import { WireFeedOutput } from '../WireFeedOutput';
import { documentOf } from './Atom03Parser';
import { BaseWireFeedParser } from './BaseWireFeedParser';
import { DateParser } from './DateParser';
import { NumberParser } from './NumberParser';

const ATOM_10_URI = 'http://www.w3.org/2005/Atom';
const ATOM_10_NS: Namespace = Namespace.getNamespace(ATOM_10_URI);

// Java's "^[a-z0-9]*:.*$" with find(): "." stops at line terminators and "$" also matches before a final one.
const ABSOLUTE_URI_PATTERN: RegExp = /^[a-z0-9]*:[^\n\r\u0085\u2028\u2029]*(?:\r\n|[\n\r\u0085\u2028\u2029])?$/;

export class Atom10Parser extends BaseWireFeedParser {
  private static resolveURIs: boolean = false;

  static setResolveURIs(resolveURIs: boolean): void {
    Atom10Parser.resolveURIs = resolveURIs;
  }

  static getResolveURIs(): boolean {
    return Atom10Parser.resolveURIs;
  }

  constructor(type?: string) {
    super(type === undefined ? 'atom_1.0' : type, ATOM_10_NS);
  }

  // Takes the text ROME reads from its Reader. External DTDs and parameter entities are never fetched, where ROME's
  // default SAXBuilder would try to. A malformed entry throws XmlParseException, ROME's JDOMParseException without its "Error on line N: " prefix.
  static parseEntry(xml: string, baseURI: string | null = null): Entry {
    const fetchedEntryElement = parseXml(xml, true).getRootElement();
    fetchedEntryElement.detach();

    const feed = new Feed();
    feed.feedType = 'atom_1.0';
    const feedDoc = new WireFeedOutput().outputJDom(feed);
    feedDoc.getRootElement().addContent(fetchedEntryElement);
    if (baseURI !== null) {
      feedDoc.getRootElement().setAttribute('base', baseURI, Namespace.XML_NAMESPACE);
    }

    const entries = (new WireFeedInput().build(feedDoc) as Feed).entries;
    if (entries.length === 0) {
      throw new Error('Index 0 out of bounds for length 0');
    }
    return entries[0];
  }

  protected getAtomNamespace(): Namespace {
    return ATOM_10_NS;
  }

  isMyType(document: Document): boolean {
    const defaultNS = document.getRootElement().getNamespace();
    return defaultNS !== null && defaultNS.equals(this.getAtomNamespace());
  }

  parse(document: Document): WireFeed {
    return this.parseFeed(document.getRootElement());
  }

  protected parseFeed(eFeed: Element): WireFeed {
    let baseURI: string | null = null;
    try {
      baseURI = this.findBaseURI(eFeed);
    } catch (e) {
      throw new FeedException('ERROR while finding base URI of feed', e as Error);
    }

    const feed = this.parseFeedMetadata(baseURI, eFeed);
    feed.styleSheet = this.getStyleSheet(documentOf(eFeed));

    const xmlBase = eFeed.getAttributeValue('base', Namespace.XML_NAMESPACE);
    if (xmlBase !== null) {
      feed.xmlBase = xmlBase;
    }

    feed.modules = this.parseFeedModules(eFeed);

    const eList = eFeed.getChildren('entry', this.getAtomNamespace());
    if (eList.length > 0) {
      feed.entries = this.parseEntries(feed, baseURI, eList);
    }

    const foreignMarkup = this.extractForeignMarkup(eFeed, feed, this.getAtomNamespace());
    if (foreignMarkup.length > 0) {
      feed.foreignMarkup = foreignMarkup;
    }
    return feed;
  }

  private parseFeedMetadata(baseURI: string | null, eFeed: Element): Feed {
    const atomNS = this.getAtomNamespace();
    const feed = new Feed(this.getType());

    const title = eFeed.getChild('title', atomNS);
    if (title !== null) {
      feed.titleEx = this.parseTextConstruct(title);
    }

    const links = eFeed.getChildren('link', atomNS);
    feed.alternateLinks = this.parseAlternateLinks(baseURI, links);
    feed.otherLinks = this.parseOtherLinks(baseURI, links);

    feed.categories = this.parseCategories(baseURI, eFeed.getChildren('category', atomNS));

    const authors = eFeed.getChildren('author', atomNS);
    if (authors.length > 0) {
      feed.authors = this.parsePersons(baseURI, authors);
    }

    const contributors = eFeed.getChildren('contributor', atomNS);
    if (contributors.length > 0) {
      feed.contributors = this.parsePersons(baseURI, contributors);
    }

    const subtitle = eFeed.getChild('subtitle', atomNS);
    if (subtitle !== null) {
      feed.subtitle = this.parseTextConstruct(subtitle);
    }

    const id = eFeed.getChild('id', atomNS);
    if (id !== null) {
      feed.id = id.getText();
    }

    const generator = eFeed.getChild('generator', atomNS);
    if (generator !== null) {
      const gen = new Generator();
      gen.value = generator.getText();
      const uri = this.getAttributeValue(generator, 'uri');
      if (uri !== null) {
        gen.url = uri;
      }
      const version = this.getAttributeValue(generator, 'version');
      if (version !== null) {
        gen.version = version;
      }
      feed.generator = gen;
    }

    const rights = eFeed.getChild('rights', atomNS);
    if (rights !== null) {
      feed.rights = this.parseTextConstructToString(rights);
    }

    const icon = eFeed.getChild('icon', atomNS);
    if (icon !== null) {
      feed.icon = icon.getText();
    }

    const logo = eFeed.getChild('logo', atomNS);
    if (logo !== null) {
      feed.logo = logo.getText();
    }

    const updated = eFeed.getChild('updated', atomNS);
    if (updated !== null) {
      feed.updated = DateParser.parseDate(updated.getText());
    }

    return feed;
  }

  private parseTextConstruct(e: Element): Content {
    const c = new Content();
    c.value = this.parseTextConstructToString(e);
    c.type = this.getAttributeValue(e, 'type');
    return c;
  }

  private parseLink(baseURI: string | null, eLink: Element): Link {
    const link = new Link();

    const rel = this.getAttributeValue(eLink, 'rel');
    if (rel !== null) {
      link.rel = rel;
    }

    const type = this.getAttributeValue(eLink, 'type');
    if (type !== null) {
      link.type = type;
    }

    const href = this.getAttributeValue(eLink, 'href');
    if (href !== null) {
      link.href = href;
      if (Atom10Parser.isRelativeURI(href)) {
        link.hrefResolved = Atom10Parser.resolveURI(baseURI, eLink, href);
      }
    }

    const title = this.getAttributeValue(eLink, 'title');
    if (title !== null) {
      link.title = title;
    }

    const hrefLang = this.getAttributeValue(eLink, 'hreflang');
    if (hrefLang !== null) {
      link.hreflang = hrefLang;
    }

    const length = this.getAttributeValue(eLink, 'length');
    if (length !== null) {
      const val = NumberParser.parseLong(length);
      if (val !== null) {
        link.length = val;
      }
    }

    return link;
  }

  // A link without rel, or with a blank one, is alternate; it is not excluded from the other links unless rel is
  // exactly "alternate", so a blank rel lands in both lists.
  private parseAlternateLinks(baseURI: string | null, eLinks: Element[]): Link[] {
    const links: Link[] = [];
    for (const eLink of eLinks) {
      const link = this.parseLink(baseURI, eLink);
      if (link.rel === null || Strings.trim(link.rel) === '' || link.rel === 'alternate') {
        links.push(link);
      }
    }
    return links;
  }

  private parseOtherLinks(baseURI: string | null, eLinks: Element[]): Link[] {
    const links: Link[] = [];
    for (const eLink of eLinks) {
      const link = this.parseLink(baseURI, eLink);
      if (link.rel !== 'alternate') {
        links.push(link);
      }
    }
    return links;
  }

  private parsePerson(baseURI: string | null, ePerson: Element): Person {
    const atomNS = this.getAtomNamespace();
    const person = new Person();

    const name = ePerson.getChild('name', atomNS);
    if (name !== null) {
      person.name = name.getText();
    }

    const uri = ePerson.getChild('uri', atomNS);
    if (uri !== null) {
      person.uri = uri.getText();
      if (Atom10Parser.isRelativeURI(uri.getText())) {
        person.uriResolved = Atom10Parser.resolveURI(baseURI, ePerson, uri.getText());
      }
    }

    const email = ePerson.getChild('email', atomNS);
    if (email !== null) {
      person.email = email.getText();
    }

    person.modules = this.parsePersonModules(ePerson);

    return person;
  }

  private parsePersons(baseURI: string | null, ePersons: Element[]): SyndPerson[] {
    return ePersons.map((e: Element) => this.parsePerson(baseURI, e));
  }

  private parseContent(e: Element): Content {
    const content = new Content();
    content.src = this.getAttributeValue(e, 'src');
    content.type = this.getAttributeValue(e, 'type');
    content.value = this.parseTextConstructToString(e);
    return content;
  }

  private parseTextConstructToString(e: Element): string {
    let type = this.getAttributeValue(e, 'type');
    if (type === null) {
      type = Content.TEXT;
    }

    if (type === Content.XHTML || type.indexOf('/xml') !== -1 || type.indexOf('+xml') !== -1) {
      const contents = e.getContent();
      for (const content of contents) {
        if (content instanceof Element && this.getAtomNamespace().equals(content.getNamespace())) {
          content.setNamespace(Namespace.NO_NAMESPACE);
        }
      }
      return new XMLOutputter().outputString(contents);
    }
    return e.getText();
  }

  protected parseEntries(feed: Feed, baseURI: string | null, eEntries: Element[]): Entry[] {
    return eEntries.map((e: Element) => this.parseEntry(feed, e, baseURI));
  }

  protected parseEntry(feed: Feed, eEntry: Element, baseURI: string | null): Entry {
    const atomNS = this.getAtomNamespace();
    const entry = new Entry();

    const xmlBase = eEntry.getAttributeValue('base', Namespace.XML_NAMESPACE);
    if (xmlBase !== null) {
      entry.xmlBase = xmlBase;
    }

    const title = eEntry.getChild('title', atomNS);
    if (title !== null) {
      entry.titleEx = this.parseTextConstruct(title);
    }

    const links = eEntry.getChildren('link', atomNS);
    entry.alternateLinks = this.parseAlternateLinks(baseURI, links);
    entry.otherLinks = this.parseOtherLinks(baseURI, links);

    const authors = eEntry.getChildren('author', atomNS);
    if (authors.length > 0) {
      entry.authors = this.parsePersons(baseURI, authors);
    }

    const contributors = eEntry.getChildren('contributor', atomNS);
    if (contributors.length > 0) {
      entry.contributors = this.parsePersons(baseURI, contributors);
    }

    const id = eEntry.getChild('id', atomNS);
    if (id !== null) {
      entry.id = id.getText();
    }

    const updated = eEntry.getChild('updated', atomNS);
    if (updated !== null) {
      entry.updated = DateParser.parseDate(updated.getText());
    }

    const published = eEntry.getChild('published', atomNS);
    if (published !== null) {
      entry.published = DateParser.parseDate(published.getText());
    }

    const summary = eEntry.getChild('summary', atomNS);
    if (summary !== null) {
      entry.summary = this.parseContent(summary);
    }

    const content = eEntry.getChild('content', atomNS);
    if (content !== null) {
      entry.contents = [this.parseContent(content)];
    }

    const rights = eEntry.getChild('rights', atomNS);
    if (rights !== null) {
      entry.rights = rights.getText();
    }

    entry.categories = this.parseCategories(baseURI, eEntry.getChildren('category', atomNS));

    const source = eEntry.getChild('source', atomNS);
    if (source !== null) {
      entry.source = this.parseFeedMetadata(baseURI, source);
    }

    entry.modules = this.parseItemModules(eEntry);

    const foreignMarkup = this.extractForeignMarkup(eEntry, entry, atomNS);
    if (foreignMarkup.length > 0) {
      entry.foreignMarkup = foreignMarkup;
    }

    return entry;
  }

  private parseCategories(baseURI: string | null, eCategories: Element[]): Category[] {
    return eCategories.map((e: Element) => this.parseCategory(baseURI, e));
  }

  private parseCategory(baseURI: string | null, eCategory: Element): Category {
    const category = new Category();

    const term = this.getAttributeValue(eCategory, 'term');
    if (term !== null) {
      category.term = term;
    }

    const scheme = this.getAttributeValue(eCategory, 'scheme');
    if (scheme !== null) {
      category.scheme = scheme;
      if (Atom10Parser.isRelativeURI(scheme)) {
        category.schemeResolved = Atom10Parser.resolveURI(baseURI, eCategory, scheme);
      }
    }

    const label = this.getAttributeValue(eCategory, 'label');
    if (label !== null) {
      category.label = label;
    }

    return category;
  }

  static isAbsoluteURI(uri: string): boolean {
    return ABSOLUTE_URI_PATTERN.test(uri);
  }

  static isRelativeURI(uri: string): boolean {
    return !Atom10Parser.isAbsoluteURI(uri);
  }

  // Resolves url against the xml:base attributes of parent and its ancestors, then baseURI. A no-op unless
  // setResolveURIs(true).
  static resolveURI(baseURI: string | null, parent: Parent | null, url: string): string {
    if (!Atom10Parser.resolveURIs) {
      return url;
    }

    if (Atom10Parser.isRelativeURI(url)) {
      if (url === '.' || url === './') {
        url = '';
      }

      if (url.startsWith('/') && baseURI !== null) {
        let base: string | null = null;
        const slashslash = baseURI.indexOf('//');
        const nextslash = baseURI.indexOf('/', slashslash + 2);
        if (nextslash !== -1) {
          base = baseURI.substring(0, nextslash);
        }
        return Atom10Parser.formURI(base, url);
      }

      if (parent instanceof Element) {
        let xmlbase = parent.getAttributeValue('base', Namespace.XML_NAMESPACE);
        if (xmlbase !== null && Strings.trim(xmlbase)!.length > 0) {
          if (Atom10Parser.isAbsoluteURI(xmlbase)) {
            if (url.startsWith('/')) {
              const slashslash = xmlbase.indexOf('//');
              const nextslash = xmlbase.indexOf('/', slashslash + 2);
              if (nextslash !== -1) {
                xmlbase = xmlbase.substring(0, nextslash);
              }
              return Atom10Parser.formURI(xmlbase, url);
            }
            if (!xmlbase.endsWith('/')) {
              xmlbase = javaSubstring(xmlbase, 0, xmlbase.lastIndexOf('/'));
            }
            return Atom10Parser.formURI(xmlbase, url);
          }
          return Atom10Parser.resolveURI(baseURI, parent.getParent(),
            `${Atom10Parser.stripTrailingSlash(xmlbase)}/${Atom10Parser.stripStartingSlash(url)}`);
        }
        return Atom10Parser.resolveURI(baseURI, parent.getParent(), url);
      } else if (parent === null || parent instanceof Document) {
        return Atom10Parser.formURI(baseURI, url);
      }
    }

    return url;
  }

  private findBaseURI(root: Element): string | null {
    let ret: string | null = null;
    const self = this.findAtomLink(root, 'self');
    if (self !== null) {
      ret = self;
      if (ret === '.' || ret === './') {
        ret = '';
      }
      if (ret.indexOf('/') !== -1) {
        ret = ret.substring(0, ret.lastIndexOf('/'));
      }
      ret = Atom10Parser.resolveURI(null, root, ret);
    }
    return ret;
  }

  // A link without rel counts as rel="alternate".
  private findAtomLink(parent: Element, rel: string): string | null {
    for (const link of parent.getChildren('link', ATOM_10_NS)) {
      const relAtt: Attribute | null = this.getAttribute(link, 'rel');
      const hrefAtt: Attribute | null = this.getAttribute(link, 'href');
      if ((relAtt === null && rel === 'alternate') || (relAtt !== null && relAtt.getValue() === rel)) {
        if (hrefAtt === null) {
          throw new Error('Cannot invoke "org.jdom2.Attribute.getValue()" because "hrefAtt" is null');
        }
        return hrefAtt.getValue();
      }
    }
    return null;
  }

  // Each ".." segment anywhere in append drops the last segment of base and the first three chars of append.
  static formURI(base: string | null, append: string): string {
    base = Atom10Parser.stripTrailingSlash(base);
    append = Atom10Parser.stripStartingSlash(append)!;
    if (append.startsWith('..')) {
      for (const part of append.split('/')) {
        if (part === '..') {
          if (base === null) {
            throw new Error('Cannot invoke "String.lastIndexOf(String)" because "base" is null');
          }
          const last = base.lastIndexOf('/');
          if (last !== -1) {
            base = base.substring(0, last);
            append = javaSubstring(append, 3, append.length);
          } else {
            break;
          }
        }
      }
    }
    return `${base}/${append}`;
  }

  static stripStartingSlash(s: string | null): string | null {
    if (s !== null && s.startsWith('/')) {
      return s.substring(1);
    }
    return s;
  }

  static stripTrailingSlash(s: string | null): string | null {
    if (s !== null && s.endsWith('/')) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }
}

// String.substring with Java's bounds check: JS clamps a negative or reversed range instead of throwing.
function javaSubstring(s: string, begin: number, end: number): string {
  if (begin < 0 || end > s.length || begin > end) {
    throw new Error(`begin ${begin}, end ${end}, length ${s.length}`);
  }
  return s.substring(begin, end);
}
