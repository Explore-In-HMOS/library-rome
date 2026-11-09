// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/Atom03Parser.java (Apache-2.0)
import { Content as XmlContent, Document, Element, Namespace } from '../../xml/Dom';
import { XMLOutputter } from '../../xml/XmlOutputter';
import { WireFeed } from '../../feed/WireFeed';
import { Content } from '../../feed/atom/Content';
import { Entry } from '../../feed/atom/Entry';
import { Feed } from '../../feed/atom/Feed';
import { Generator } from '../../feed/atom/Generator';
import { Link } from '../../feed/atom/Link';
import { Person } from '../../feed/atom/Person';
import { SyndPerson } from '../../feed/synd/SyndPerson';
import { Base64 } from './Base64';
import { BaseWireFeedParser } from './BaseWireFeedParser';
import { DateParser } from './DateParser';

const ATOM_03_URI = 'http://purl.org/atom/ns#';
const ATOM_03_NS: Namespace = Namespace.getNamespace(ATOM_03_URI);

export class Atom03Parser extends BaseWireFeedParser {
  constructor(type?: string, ns?: Namespace) {
    super(type === undefined ? 'atom_0.3' : type, ns === undefined ? ATOM_03_NS : ns);
  }

  protected getAtomNamespace(): Namespace {
    return ATOM_03_NS;
  }

  isMyType(document: Document): boolean {
    const defaultNS = document.getRootElement().getNamespace();
    return defaultNS !== null && defaultNS.equals(this.getAtomNamespace());
  }

  parse(document: Document): WireFeed {
    return this.parseFeed(document.getRootElement());
  }

  protected parseFeed(eFeed: Element): WireFeed {
    const atomNS = this.getAtomNamespace();
    const feed = new Feed(this.getType());
    feed.styleSheet = this.getStyleSheet(documentOf(eFeed));

    const title = eFeed.getChild('title', atomNS);
    if (title !== null) {
      feed.titleEx = this.parseContent(title);
    }

    const links = eFeed.getChildren('link', atomNS);
    feed.alternateLinks = this.parseLinks(links, true);
    feed.otherLinks = this.parseLinks(links, false);

    const author = eFeed.getChild('author', atomNS);
    if (author !== null) {
      feed.authors = [this.parsePerson(author)];
    }

    const contributors = eFeed.getChildren('contributor', atomNS);
    if (contributors.length > 0) {
      feed.contributors = this.parsePersons(contributors);
    }

    const tagline = eFeed.getChild('tagline', atomNS);
    if (tagline !== null) {
      feed.tagline = this.parseContent(tagline);
    }

    const id = eFeed.getChild('id', atomNS);
    if (id !== null) {
      feed.id = id.getText();
    }

    const generator = eFeed.getChild('generator', atomNS);
    if (generator !== null) {
      const gen = new Generator();
      gen.value = generator.getText();
      const url = this.getAttributeValue(generator, 'url');
      if (url !== null) {
        gen.url = url;
      }
      const version = this.getAttributeValue(generator, 'version');
      if (version !== null) {
        gen.version = version;
      }
      feed.generator = gen;
    }

    const copyright = eFeed.getChild('copyright', atomNS);
    if (copyright !== null) {
      feed.copyright = copyright.getText();
    }

    const info = eFeed.getChild('info', atomNS);
    if (info !== null) {
      feed.info = this.parseContent(info);
    }

    const modified = eFeed.getChild('modified', atomNS);
    if (modified !== null) {
      feed.modified = DateParser.parseDate(modified.getText());
    }

    feed.modules = this.parseFeedModules(eFeed);

    const entries = eFeed.getChildren('entry', atomNS);
    if (entries.length > 0) {
      feed.entries = entries.map((e: Element) => this.parseEntry(e));
    }

    const foreignMarkup = this.extractForeignMarkup(eFeed, feed, atomNS);
    if (foreignMarkup.length > 0) {
      feed.foreignMarkup = foreignMarkup;
    }

    return feed;
  }

  private parseLink(eLink: Element): Link {
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
    }
    return link;
  }

  // Unlike Atom 1.0, a link without rel is not alternate here.
  private parseLinks(eLinks: Element[], alternate: boolean): Link[] {
    const links: Link[] = [];
    for (const eLink of eLinks) {
      const isAlternate = this.getAttributeValue(eLink, 'rel') === 'alternate';
      if (isAlternate === alternate) {
        links.push(this.parseLink(eLink));
      }
    }
    return links;
  }

  private parsePerson(ePerson: Element): Person {
    const atomNS = this.getAtomNamespace();
    const person = new Person();
    const name = ePerson.getChild('name', atomNS);
    if (name !== null) {
      person.name = name.getText();
    }
    const url = ePerson.getChild('url', atomNS);
    if (url !== null) {
      person.url = url.getText();
    }
    const email = ePerson.getChild('email', atomNS);
    if (email !== null) {
      person.email = email.getText();
    }
    return person;
  }

  private parsePersons(ePersons: Element[]): SyndPerson[] {
    return ePersons.map((e: Element) => this.parsePerson(e));
  }

  private parseContent(e: Element): Content {
    let value: string | null = null;

    let type = this.getAttributeValue(e, 'type');
    if (type === null) {
      type = 'text/plain';
    }

    let mode = this.getAttributeValue(e, 'mode');
    if (mode === null) {
      mode = Content.XML;
    }

    if (mode === Content.ESCAPED) {
      value = e.getText();
    } else if (mode === Content.BASE64) {
      value = Base64.decode(e.getText());
    } else if (mode === Content.XML) {
      const contents = e.getContent();
      for (const content of contents) {
        if (content instanceof Element && this.getAtomNamespace().equals(content.getNamespace())) {
          content.setNamespace(Namespace.NO_NAMESPACE);
        }
      }
      value = new XMLOutputter().outputString(contents);
    }

    const content = new Content();
    content.type = type;
    content.mode = mode;
    content.value = value;
    return content;
  }

  private parseEntry(eEntry: Element): Entry {
    const atomNS = this.getAtomNamespace();
    const entry = new Entry();

    const title = eEntry.getChild('title', atomNS);
    if (title !== null) {
      entry.titleEx = this.parseContent(title);
    }

    const links = eEntry.getChildren('link', atomNS);
    entry.alternateLinks = this.parseLinks(links, true);
    entry.otherLinks = this.parseLinks(links, false);

    const author = eEntry.getChild('author', atomNS);
    if (author !== null) {
      entry.authors = [this.parsePerson(author)];
    }

    const contributors = eEntry.getChildren('contributor', atomNS);
    if (contributors.length > 0) {
      entry.contributors = this.parsePersons(contributors);
    }

    const id = eEntry.getChild('id', atomNS);
    if (id !== null) {
      entry.id = id.getText();
    }

    const modified = eEntry.getChild('modified', atomNS);
    if (modified !== null) {
      entry.modified = DateParser.parseDate(modified.getText());
    }

    const issued = eEntry.getChild('issued', atomNS);
    if (issued !== null) {
      entry.issued = DateParser.parseDate(issued.getText());
    }

    const created = eEntry.getChild('created', atomNS);
    if (created !== null) {
      entry.created = DateParser.parseDate(created.getText());
    }

    const summary = eEntry.getChild('summary', atomNS);
    if (summary !== null) {
      entry.summary = this.parseContent(summary);
    }

    const contents = eEntry.getChildren('content', atomNS);
    if (contents.length > 0) {
      entry.contents = contents.map((e: Element) => this.parseContent(e));
    }

    entry.modules = this.parseItemModules(eEntry);

    const foreignMarkup = this.extractForeignMarkup(eEntry, entry, atomNS);
    if (foreignMarkup.length > 0) {
      entry.foreignMarkup = foreignMarkup;
    }

    return entry;
  }
}

// JDOM's Element.getDocument(); ROME dereferences it, so a detached element fails as it does in Java.
export function documentOf(element: Element): Document {
  let current: Element = element;
  for (;;) {
    const parent = current.getParent();
    if (parent instanceof Element) {
      current = parent;
    } else if (parent instanceof Document) {
      return parent;
    } else {
      throw new Error('Cannot invoke "org.jdom2.Document.getContent(org.jdom2.filter.Filter)" because "doc" is null');
    }
  }
}
