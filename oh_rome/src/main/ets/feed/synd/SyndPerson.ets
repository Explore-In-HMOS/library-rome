// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/{SyndPerson,SyndPersonImpl}.java (Apache-2.0)
import { Extendable, Module, ModuleUtils } from '../module/Module';

export class SyndPerson implements Extendable {
  name: string | null = null;
  uri: string | null = null;
  email: string | null = null;
  modules: Module[] = [];

  getModule(uri: string): Module | null {
    return ModuleUtils.getModule(this.modules, uri);
  }
}
