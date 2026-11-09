// Ported from ROME rome-modules/src/main/java/com/rometools/modules/atom/io/AtomModuleParser.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { Link } from '../../../feed/atom/Link';
import { SyndPerson } from '../../../feed/synd/SyndPerson';
import { ModuleParser } from '../../../io/ModuleParser';
import { NumberParser } from '../../../io/impl/NumberParser';
import { Strings } from '../../../utils/Strings';
import { AtomLinkModule } from '../modules/AtomLinkModule';
import { AtomLinkAttribute } from './AtomLinkAttribute';

const NS: Namespace = Namespace.getNamespace(AtomLinkModule.URI);

export class AtomModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return AtomLinkModule.URI;
  }

  parse(element: Element): Module | null {
    if (element.getName() !== 'channel' && element.getName() !== 'item') {
      return null;
    }
    const mod = new AtomLinkModule();
    mod.links = element.getChildren('link', NS).map((link: Element) => this.parseLink(link));
    mod.authors = element.getChildren('author', NS).map((author: Element) => this.parsePerson(author));
    mod.contributors = element.getChildren('contributor', NS).map((c: Element) => this.parsePerson(c));
    return mod;
  }

  private parseLink(eLink: Element): Link {
    const link = new Link();
    const rel = this.getAttributeValue(eLink, AtomLinkAttribute.REL);
    if (rel !== null) {
      link.rel = rel;
    }
    const type = this.getAttributeValue(eLink, AtomLinkAttribute.TYPE);
    if (type !== null) {
      link.type = type;
    }
    const href = this.getAttributeValue(eLink, AtomLinkAttribute.HREF);
    if (href !== null) {
      link.href = href;
    }
    const title = this.getAttributeValue(eLink, AtomLinkAttribute.TITLE);
    if (title !== null) {
      link.title = title;
    }
    const hrefLang = this.getAttributeValue(eLink, AtomLinkAttribute.HREF_LANG);
    if (hrefLang !== null) {
      link.hreflang = hrefLang;
    }
    const length = this.getAttributeValue(eLink, AtomLinkAttribute.LENGTH);
    if (length !== null) {
      const val = NumberParser.parseLong(length);
      if (val !== null) {
        link.length = val;
      }
    }
    return link;
  }

  protected getAttributeValue(e: Element, attributeName: string): string | null {
    const attr = e.getAttribute(attributeName) ?? e.getAttribute(attributeName, NS);
    return attr !== null ? attr.getValue() : null;
  }

  private parsePerson(element: Element): SyndPerson {
    const person = new SyndPerson();
    const name = element.getChild('name', NS);
    if (name !== null) {
      person.name = Strings.trim(name.getValue());
    }
    const email = element.getChild('email', NS);
    if (email !== null) {
      person.email = Strings.trim(email.getValue());
    }
    const uri = element.getChild('uri', NS);
    if (uri !== null) {
      person.uri = Strings.trim(uri.getValue());
    }
    return person;
  }
}
