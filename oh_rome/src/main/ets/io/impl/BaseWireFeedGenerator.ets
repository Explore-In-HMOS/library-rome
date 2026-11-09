// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/BaseWireFeedGenerator.java and ModuleGenerators.java (Apache-2.0)
import { Document, Element, Namespace } from '../../xml/Dom';
import { WireFeed } from '../../feed/WireFeed';
import { Module } from '../../feed/module/Module';
import { ModuleGenerator } from '../ModuleGenerator';
import { WireFeedGenerator } from '../WireFeedGenerator';
import { plugins } from './PluginRegistry';

export abstract class BaseWireFeedGenerator implements WireFeedGenerator {
  private readonly type: string;

  constructor(type: string) {
    this.type = type;
  }

  getType(): string {
    return this.type;
  }

  abstract generate(feed: WireFeed): Document;

  // Declares every namespace of the feed, item and person module generators on the root (deduplicated by URI).
  protected generateModuleNamespaceDefs(root: Element): void {
    const namespaces: Namespace[] = [];
    for (const scope of ['feed', 'item', 'person']) {
      for (const generator of plugins().getModuleGenerators(`${this.type}.${scope}`)) {
        for (const ns of generator.getNamespaces()) {
          if (!namespaces.some((n: Namespace) => n.equals(ns))) {
            namespaces.push(ns);
          }
        }
      }
    }
    for (const ns of namespaces) {
      root.addNamespaceDeclaration(ns);
    }
  }

  protected generateFeedModules(modules: Module[], feed: Element): void {
    BaseWireFeedGenerator.generateModules(plugins().getModuleGenerators(`${this.type}.feed`), modules, feed);
  }

  generateItemModules(modules: Module[], item: Element): void {
    BaseWireFeedGenerator.generateModules(plugins().getModuleGenerators(`${this.type}.item`), modules, item);
  }

  generatePersonModules(modules: Module[], person: Element): void {
    BaseWireFeedGenerator.generateModules(plugins().getModuleGenerators(`${this.type}.person`), modules, person);
  }

  protected generateForeignMarkup(element: Element, foreignElements: Element[]): void {
    for (const foreignElement of foreignElements) {
      const parent = foreignElement.getParent();
      if (parent !== null) {
        parent.removeContent(foreignElement);
      }
      element.addContent(foreignElement);
    }
  }

  protected static purgeUnusedNamespaceDeclarations(root: Element): void {
    const usedPrefixes = new Set<string>();
    BaseWireFeedGenerator.collectUsedPrefixes(root, usedPrefixes);
    for (const ns of root.getAdditionalNamespaces()) {
      if (ns.getPrefix().length > 0 && !usedPrefixes.has(ns.getPrefix())) {
        root.removeNamespaceDeclaration(ns);
      }
    }
  }

  private static collectUsedPrefixes(el: Element, collector: Set<string>): void {
    const prefix = el.getNamespacePrefix();
    if (prefix.length > 0) {
      collector.add(prefix);
    }
    for (const kid of el.getChildren()) {
      BaseWireFeedGenerator.collectUsedPrefixes(kid, collector);
    }
  }

  // Later generators for the same namespace URI win, as in ROME's plugin map.
  private static generateModules(generators: ModuleGenerator[], modules: Module[], element: Element): void {
    for (const module of modules) {
      const generator = generators.find((g: ModuleGenerator) => g.getNamespaceUri() === module.uri);
      if (generator !== undefined) {
        generator.generate(module, element);
      }
    }
  }
}
