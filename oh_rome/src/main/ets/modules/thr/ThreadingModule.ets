// Ported from ROME rome-modules/src/main/java/com/rometools/modules/thr/{ThreadingModule,ThreadingModuleImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../feed/module/Module';

export class ThreadingModule extends ModuleImpl {
  static readonly URI: string = 'http://purl.org/syndication/thread/1.0';
  ref: string | null = null;
  href: string | null = null;
  type: string | null = null;
  source: string | null = null;

  constructor() {
    super(ThreadingModule.URI);
  }

  copyFrom(obj: Module): void {
    if (obj instanceof ThreadingModule) {
      this.href = obj.href;
      this.ref = obj.ref;
      this.type = obj.type;
      this.source = obj.source;
    }
  }

  clone(): ThreadingModule {
    const m = new ThreadingModule();
    m.href = this.href;
    m.ref = this.ref;
    m.source = this.source;
    m.type = this.type;
    return m;
  }
}
