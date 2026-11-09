// Ported from ROME rome-modules/src/main/java/com/rometools/modules/atom/io/AtomModuleGenerator.java (Apache-2.0)
import { Attribute, Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { Link } from '../../../feed/atom/Link';
import { SyndPerson } from '../../../feed/synd/SyndPerson';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { AtomLinkModule } from '../modules/AtomLinkModule';
import { AtomLinkAttribute } from './AtomLinkAttribute';
import { AtomPersonElement } from './AtomPersonElement';

const NS: Namespace = Namespace.getNamespace('atom', AtomLinkModule.URI);

export class AtomModuleGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return AtomLinkModule.URI;
  }

  getNamespaces(): Namespace[] {
    return [NS];
  }

  generate(module: Module, element: Element): void {
    if (module instanceof AtomLinkModule) {
      for (const link of module.links) {
        element.addContent(this.generateLink(link));
      }
      this.generatePersons(AtomPersonElement.AUTHOR_PREFIX, module.authors, element);
      this.generatePersons(AtomPersonElement.CONTRIBUTOR_PREFIX, module.contributors, element);
    }
  }

  private generateLink(link: Link): Element {
    const linkElement = new Element('link', NS);
    if (link.href !== null) {
      linkElement.setAttribute(new Attribute(AtomLinkAttribute.HREF, link.href));
    }
    if (link.type !== null) {
      linkElement.setAttribute(new Attribute(AtomLinkAttribute.TYPE, link.type));
    }
    if (link.rel !== null) {
      linkElement.setAttribute(new Attribute(AtomLinkAttribute.REL, link.rel));
    }
    if (link.hreflang !== null) {
      linkElement.setAttribute(new Attribute(AtomLinkAttribute.HREF_LANG, link.hreflang));
    }
    if (link.title !== null) {
      linkElement.setAttribute(new Attribute(AtomLinkAttribute.TITLE, link.title));
    }
    if (link.length !== 0) {
      linkElement.setAttribute(new Attribute(AtomLinkAttribute.LENGTH, String(link.length)));
    }
    return linkElement;
  }

  private generatePersons(elementName: string, persons: SyndPerson[], parent: Element): void {
    for (const person of persons) {
      parent.addContent(this.generatePerson(elementName, person));
    }
  }

  private generatePerson(elementName: string, person: SyndPerson): Element {
    const element = new Element(elementName, NS);
    if (person.name !== null) {
      const name = new Element(AtomPersonElement.NAME_ELEMENT, NS);
      name.setText(person.name);
      element.addContent(name);
    }
    if (person.email !== null) {
      const email = new Element(AtomPersonElement.EMAIL_ELEMENT, NS);
      email.setText(person.email);
      element.addContent(email);
    }
    if (person.uri !== null) {
      const uri = new Element(AtomPersonElement.URI_ELEMENT, NS);
      uri.setText(person.uri);
      element.addContent(uri);
    }
    return element;
  }
}
