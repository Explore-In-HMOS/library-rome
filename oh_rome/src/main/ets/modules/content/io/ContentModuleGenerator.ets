// Ported from ROME rome-modules/src/main/java/com/rometools/modules/content/io/ContentModuleGenerator.java (Apache-2.0)
import { Attribute, CDATA, Content, Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { ContentModule } from '../ContentModule';

const CONTENT_NS: Namespace = Namespace.getNamespace('content', ContentModule.URI);
const RDF_NS: Namespace = Namespace.getNamespace('rdf', ContentModule.RDF_URI);

export class ContentModuleGenerator implements ModuleGenerator {
  generate(module: Module, element: Element): void {
    let root = element;
    while (root.getParent() instanceof Element) {
      root = root.getParent() as Element;
    }
    root.addNamespaceDeclaration(CONTENT_NS);
    if (!(module instanceof ContentModule)) {
      return;
    }
    const cm = module as ContentModule;
    for (const encoded of cm.encodeds) {
      element.addContent(this.generateCDATAElement('encoded', encoded));
    }
    if (cm.contentItems.length === 0) {
      return;
    }
    const items = new Element('items', CONTENT_NS);
    const bag = new Element('Bag', RDF_NS);
    items.addContent(bag);
    for (const contentItem of cm.contentItems) {
      const li = new Element('li', RDF_NS);
      const item = new Element('item', CONTENT_NS);
      if (contentItem.contentAbout !== null) {
        item.setAttribute(new Attribute('about', contentItem.contentAbout, RDF_NS));
      }
      if (contentItem.contentFormat !== null) {
        const format = new Element('format', CONTENT_NS);
        format.setAttribute(new Attribute('resource', contentItem.contentFormat, RDF_NS));
        item.addContent(format);
      }
      if (contentItem.contentEncoding !== null) {
        const encoding = new Element('encoding', CONTENT_NS);
        encoding.setAttribute(new Attribute('resource', contentItem.contentEncoding, RDF_NS));
        item.addContent(encoding);
      }
      if (contentItem.contentValue !== null) {
        const value = new Element('value', RDF_NS);
        if (contentItem.contentValueParseType !== null) {
          value.setAttribute(new Attribute('parseType', contentItem.contentValueParseType, RDF_NS));
        }
        if (contentItem.contentValueNamespaces !== null) {
          for (const namespace of contentItem.contentValueNamespaces) {
            value.addNamespaceDeclaration(namespace);
          }
        }
        value.setContent(contentItem.contentValueDOM!.map((c: Content) => c.clone().detach()));
        item.addContent(value);
      }
      li.addContent(item);
      bag.addContent(li);
    }
    element.addContent(items);
  }

  protected generateSimpleElement(name: string, value: string): Element {
    const element = new Element(name, CONTENT_NS);
    element.addContent(value);
    return element;
  }

  protected generateCDATAElement(name: string, value: string): Element {
    const element = new Element(name, CONTENT_NS);
    element.addContent(new CDATA(value));
    return element;
  }

  getNamespaceUri(): string {
    return ContentModule.URI;
  }

  getNamespaces(): Namespace[] {
    return [CONTENT_NS];
  }
}
