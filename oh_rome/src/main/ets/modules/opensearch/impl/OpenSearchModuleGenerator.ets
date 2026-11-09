// Ported from ROME rome-modules/src/main/java/com/rometools/modules/opensearch/impl/OpenSearchModuleGenerator.java (Apache-2.0)
import { Attribute, Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { Link } from '../../../feed/atom/Link';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { OSQuery } from '../entity/OSQuery';
import { OpenSearchModule } from '../OpenSearchModule';
import { RequiredAttributeMissingException } from '../RequiredAttributeMissingException';

const OS_NS: Namespace = Namespace.getNamespace('opensearch', OpenSearchModule.URI);

export class OpenSearchModuleGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return OpenSearchModule.URI;
  }

  getNamespaces(): Namespace[] {
    return [OS_NS];
  }

  generate(module: Module, element: Element): void {
    const osm = module as OpenSearchModule;
    if (osm.itemsPerPage > -1) {
      element.addContent(this.generateSimpleElement('itemsPerPage', String(osm.itemsPerPage)));
    }
    if (osm.totalResults > -1) {
      element.addContent(this.generateSimpleElement('totalResults', String(osm.totalResults)));
    }
    const startIndex = osm.startIndex > 0 ? osm.startIndex : 1;
    element.addContent(this.generateSimpleElement('startIndex', String(startIndex)));
    for (const query of osm.queries) {
      element.addContent(this.generateQueryElement(query));
    }
    if (osm.link !== null) {
      element.addContent(this.generateLinkElement(osm.link));
    }
  }

  protected generateQueryElement(query: OSQuery): Element {
    const qElement = new Element('Query', OS_NS);
    if (query.role === null) {
      throw new RequiredAttributeMissingException(
        'If declaring a Query element, the field \'role\' must be be specified');
    }
    qElement.setAttribute(new Attribute('role', query.role));
    if (query.osd !== null) {
      qElement.setAttribute(new Attribute('osd', query.osd));
    }
    if (query.searchTerms !== null) {
      qElement.setAttribute(new Attribute('searchTerms', query.searchTerms));
    }
    if (query.startPage > -1) {
      const startPage = query.startPage !== 0 ? query.startPage : 1;
      qElement.setAttribute(new Attribute('startPage', String(startPage)));
    }
    if (query.title !== null) {
      qElement.setAttribute(new Attribute('title', query.title));
    }
    if (query.totalResults > -1) {
      qElement.setAttribute(new Attribute('totalResults', String(query.totalResults)));
    }
    return qElement;
  }

  // ROME writes rel="search" whatever the link's rel, and drops title and length.
  protected generateLinkElement(link: Link): Element {
    const linkElement = new Element('link', OS_NS);
    if (link.rel !== null) {
      linkElement.setAttribute(new Attribute('rel', 'search'));
    }
    if (link.type !== null) {
      linkElement.setAttribute(new Attribute('type', link.type));
    }
    if (link.href !== null) {
      linkElement.setAttribute(new Attribute('href', link.href));
    }
    if (link.hreflang !== null) {
      linkElement.setAttribute(new Attribute('hreflang', link.hreflang));
    }
    return linkElement;
  }

  protected generateSimpleElement(name: string, value: string): Element {
    const element = new Element(name, OS_NS);
    element.addContent(value);
    return element;
  }
}
