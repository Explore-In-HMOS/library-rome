// Ported from ROME rome/src/main/java/com/rometools/rome/feed/module/{Module,ModuleImpl,Extendable}.java
// and feed/module/impl/ModuleUtils.java (Apache-2.0)

export interface Module {
  readonly uri: string;

  clone(): Module;

  copyFrom(obj: Module): void;
}

export abstract class ModuleImpl implements Module {
  readonly uri: string;

  constructor(uri: string) {
    this.uri = uri;
  }

  abstract clone(): Module;

  abstract copyFrom(obj: Module): void;
}

export interface Extendable {
  modules: Module[];

  getModule(uri: string): Module | null;
}

export class ModuleUtils {
  static cloneModules(modules: Module[]): Module[] {
    return modules.map((m: Module) => m.clone());
  }

  static getModule(modules: Module[], uri: string): Module | null {
    for (const module of modules) {
      if (module.uri === uri) {
        return module;
      }
    }
    return null;
  }
}
