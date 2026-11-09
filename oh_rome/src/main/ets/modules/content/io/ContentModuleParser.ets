// Ported from ROME rome-modules/src/main/java/com/rometools/modules/content/io/ContentModuleParser.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { XMLOutputter } from '../../../xml/XmlOutputter';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { ContentItem } from '../ContentItem';
import { ContentModule } from '../ContentModule';

const CONTENT_NS: Namespace = Namespace.getNamespace('content', ContentModule.URI);
const RDF_NS: Namespace = Namespace.getNamespace('rdf', ContentModule.RDF_URI);

export class ContentModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return ContentModule.URI;
  }

  parse(element: Element): Module | null {
    let foundSomething = false;
    const cm = new ContentModule();
    const encodeds = element.getChildren('encoded', CONTENT_NS);
    const contentStrings: string[] = [];
    const encodedStrings: string[] = [];
    if (encodeds.length > 0) {
      foundSomething = true;
      for (const encodedElement of encodeds) {
        encodedStrings.push(encodedElement.getText());
        contentStrings.push(encodedElement.getText());
      }
    }
    const contentItems: ContentItem[] = [];
    for (const items of element.getChildren('items', CONTENT_NS)) {
      foundSomething = true;
      for (const li of items.getChild('Bag', RDF_NS)!.getChildren('li', RDF_NS)) {
        const ci = new ContentItem();
        const item = li.getChild('item', CONTENT_NS);
        const format = item!.getChild('format', CONTENT_NS);
        const encoding = item!.getChild('encoding', CONTENT_NS);
        const value = item!.getChild('value', RDF_NS);
        if (value !== null) {
          if (value.getAttributeValue('parseType', RDF_NS) !== null) {
            ci.contentValueParseType = value.getAttributeValue('parseType', RDF_NS);
          }
          if (ci.contentValueParseType === 'Literal') {
            ci.contentValue = this.getXmlInnerText(value);
            contentStrings.push(this.getXmlInnerText(value));
            ci.contentValueNamespaces = value.getAdditionalNamespaces();
          } else {
            ci.contentValue = value.getText();
            contentStrings.push(value.getText());
          }
          ci.contentValueDOM = value.clone().getContent();
        }
        if (format !== null) {
          ci.contentFormat = format.getAttribute('resource', RDF_NS)!.getValue();
        }
        if (encoding !== null) {
          ci.contentEncoding = encoding.getAttribute('resource', RDF_NS)!.getValue();
        }
        const about = item!.getAttribute('about', RDF_NS);
        if (about !== null) {
          ci.contentAbout = about.getValue();
        }
        contentItems.push(ci);
      }
    }
    cm.encodeds = encodedStrings;
    cm.contentItems = contentItems;
    cm.contents = contentStrings;
    return foundSomething ? cm : null;
  }

  protected getXmlInnerText(e: Element): string {
    return new XMLOutputter().outputString(e.getContent());
  }
}
