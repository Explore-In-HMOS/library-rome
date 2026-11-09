// Replaces ROME's PluginManager, FeedParsers, FeedGenerators, ModuleParsers, ModuleGenerators, Converters
// and the rome.properties files (rome/src/main/java/com/rometools/rome/io/impl, feed/synd/impl) (Apache-2.0).
import { Converter } from '../../feed/synd/Converter';
import { ModuleGenerator } from '../ModuleGenerator';
import { ModuleParser } from '../ModuleParser';
import { WireFeedGenerator } from '../WireFeedGenerator';
import { WireFeedParser } from '../WireFeedParser';

// Registration order matters where ROME iterates lists (feed parser detection, module parse order).
// Re-registering a key replaces the earlier plugin and moves it to the end, like ROME's later
// rome.properties entries overriding earlier ones.
export class PluginRegistry {
  private feedParsers: WireFeedParser[] = [];
  private feedGenerators: WireFeedGenerator[] = [];
  private converters: Converter[] = [];
  private moduleParsers: Map<string, ModuleParser[]> = new Map<string, ModuleParser[]>();
  private moduleGenerators: Map<string, ModuleGenerator[]> = new Map<string, ModuleGenerator[]>();

  addFeedParser(parser: WireFeedParser): void {
    this.feedParsers = this.feedParsers.filter((p: WireFeedParser) => p.getType() !== parser.getType());
    this.feedParsers.push(parser);
  }

  addFeedGenerator(generator: WireFeedGenerator): void {
    this.feedGenerators = this.feedGenerators.filter((g: WireFeedGenerator) => g.getType() !== generator.getType());
    this.feedGenerators.push(generator);
  }

  addConverter(converter: Converter): void {
    this.converters = this.converters.filter((c: Converter) => c.getType() !== converter.getType());
    this.converters.push(converter);
  }

  // scope is "<feedType>.feed", "<feedType>.item" or "<feedType>.person", e.g. "rss_2.0.item".
  addModuleParser(scope: string, parser: ModuleParser): void {
    const list = (this.moduleParsers.get(scope) ?? [])
      .filter((p: ModuleParser) => p.getNamespaceUri() !== parser.getNamespaceUri());
    list.push(parser);
    this.moduleParsers.set(scope, list);
  }

  addModuleGenerator(scope: string, generator: ModuleGenerator): void {
    const list = (this.moduleGenerators.get(scope) ?? [])
      .filter((g: ModuleGenerator) => g.getNamespaceUri() !== generator.getNamespaceUri());
    list.push(generator);
    this.moduleGenerators.set(scope, list);
  }

  getFeedParsers(): WireFeedParser[] {
    return this.feedParsers.slice();
  }

  getFeedParserTypes(): string[] {
    return this.feedParsers.map((p: WireFeedParser) => p.getType());
  }

  getFeedGenerator(feedType: string): WireFeedGenerator | null {
    return this.feedGenerators.find((g: WireFeedGenerator) => g.getType() === feedType) ?? null;
  }

  getFeedGeneratorTypes(): string[] {
    return this.feedGenerators.map((g: WireFeedGenerator) => g.getType());
  }

  getConverter(feedType: string): Converter | null {
    return this.converters.find((c: Converter) => c.getType() === feedType) ?? null;
  }

  getConverterTypes(): string[] {
    return this.converters.map((c: Converter) => c.getType());
  }

  getModuleParsers(scope: string): ModuleParser[] {
    return (this.moduleParsers.get(scope) ?? []).slice();
  }

  getModuleGenerators(scope: string): ModuleGenerator[] {
    return (this.moduleGenerators.get(scope) ?? []).slice();
  }
}

let registry: PluginRegistry | null = null;
let defaultPlugins: ((registry: PluginRegistry) => void) | null = null;

// Called once by DefaultPlugins.ets when it loads. This file must not import DefaultPlugins.ets: that would
// close the cycle BaseWireFeedParser -> PluginRegistry -> DefaultPlugins -> SomeParser extends
// BaseWireFeedParser, which fails at load time with "ReferenceError: BaseWireFeedParser is not initialized".
export function setDefaultPlugins(register: (registry: PluginRegistry) => void): void {
  defaultPlugins = register;
  if (registry !== null) {
    register(registry);
  }
}

let replacement: PluginRegistry | null = null;

// Test hook (not exported from Index.ets): makes plugins() return the given registry; null restores the default.
export function usePluginRegistry(registryForTests: PluginRegistry | null): void {
  replacement = registryForTests;
}

// Plugin constructors must not call plugins().
export function plugins(): PluginRegistry {
  if (replacement !== null) {
    return replacement;
  }
  if (registry === null) {
    const created = new PluginRegistry();
    if (defaultPlugins !== null) {
      defaultPlugins(created);
    }
    registry = created;
  }
  return registry;
}
