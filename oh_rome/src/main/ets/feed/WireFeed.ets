// Ported from ROME rome/src/main/java/com/rometools/rome/feed/WireFeed.java (Apache-2.0)
import { Element } from '../xml/Dom';
import { Extendable, Module, ModuleUtils } from './module/Module';

// Parent of the RSS Channel and Atom Feed beans. feedType is [FEEDNAME]_[FEEDVERSION], e.g. rss_0.9, atom_0.3.
export abstract class WireFeed implements Extendable {
  feedType: string | null;
  encoding: string | null = null;
  styleSheet: string | null = null;
  modules: Module[] = [];
  foreignMarkup: Element[] = [];

  constructor(feedType?: string) {
    this.feedType = feedType === undefined ? null : feedType;
  }

  getModule(uri: string): Module | null {
    return ModuleUtils.getModule(this.modules, uri);
  }
}
