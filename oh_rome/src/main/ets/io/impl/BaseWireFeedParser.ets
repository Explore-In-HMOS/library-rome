// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/BaseWireFeedParser.java and ModuleParsers.java (Apache-2.0)
import { Attribute, Document, Element, Namespace, ProcessingInstruction } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Extendable, Module } from '../../feed/module/Module';
import { ModuleParser } from '../ModuleParser';
import { WireFeedParser } from '../WireFeedParser';
import { plugins } from './PluginRegistry';

export abstract class BaseWireFeedParser implements WireFeedParser {
  private readonly type: string;
  private readonly namespace: Namespace | null;

  constructor(type: string, namespace: Namespace | null) {
    this.type = type;
    this.namespace = namespace;
  }

  getType(): string {
    return this.type;
  }

  abstract isMyType(document: Document): boolean;

  abstract parse(document: Document): WireFeed;

  protected parseFeedModules(feedElement: Element): Module[] {
    return BaseWireFeedParser.parseModules(plugins().getModuleParsers(`${this.type}.feed`), feedElement);
  }

  protected parseItemModules(itemElement: Element): Module[] {
    return BaseWireFeedParser.parseModules(plugins().getModuleParsers(`${this.type}.item`), itemElement);
  }

  protected parsePersonModules(personElement: Element): Module[] {
    return BaseWireFeedParser.parseModules(plugins().getModuleParsers(`${this.type}.person`), personElement);
  }

  // Children outside the feed namespace that no module claimed, cloned and detached.
  protected extractForeignMarkup(e: Element, ext: Extendable, namespace: Namespace): Element[] {
    const foreignElements: Element[] = [];
    for (const element of e.getChildren()) {
      if (!namespace.equals(element.getNamespace()) && ext.getModule(element.getNamespaceURI()) === null) {
        foreignElements.push(element.clone());
      }
    }
    return foreignElements;
  }

  // Unqualified attribute first, then the same name in the parser's namespace.
  protected getAttribute(e: Element, attributeName: string): Attribute | null {
    const attribute = e.getAttribute(attributeName);
    return attribute !== null ? attribute : e.getAttribute(attributeName, this.namespace);
  }

  protected getAttributeValue(e: Element, attributeName: string): string | null {
    const attribute = this.getAttribute(e, attributeName);
    return attribute === null ? null : attribute.getValue();
  }

  protected getStyleSheet(doc: Document): string | null {
    for (const c of doc.getContent()) {
      if (c instanceof ProcessingInstruction && c.getPseudoAttributeValue('type') === 'text/xsl') {
        return c.getPseudoAttributeValue('href');
      }
    }
    return null;
  }

  private static parseModules(parsers: ModuleParser[], root: Element): Module[] {
    const modules: Module[] = [];
    for (const parser of parsers) {
      const namespace = Namespace.getNamespace(parser.getNamespaceUri());
      if (root.getChildren().some((child: Element) => namespace.equals(child.getNamespace()))) {
        const module = parser.parse(root);
        if (module !== null) {
          modules.push(module);
        }
      }
    }
    return modules;
  }
}
