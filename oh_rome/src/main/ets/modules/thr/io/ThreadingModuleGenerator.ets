// Ported from ROME rome-modules/src/main/java/com/rometools/modules/thr/io/ThreadingModuleGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { ThreadingModule } from '../ThreadingModule';

const NAMESPACE: Namespace = Namespace.getNamespace('thr', ThreadingModule.URI);

export class ThreadingModuleGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return ThreadingModule.URI;
  }

  getNamespaces(): Namespace[] {
    return [NAMESPACE];
  }

  generate(module: Module, element: Element): void {
    if (module instanceof ThreadingModule) {
      const inReplyTo = new Element('in-reply-to', NAMESPACE);
      if (module.href !== null) {
        inReplyTo.setAttribute('href', module.href);
      }
      if (module.ref !== null) {
        inReplyTo.setAttribute('ref', module.ref);
      }
      if (module.type !== null) {
        inReplyTo.setAttribute('type', module.type);
      }
      if (module.source !== null) {
        inReplyTo.setAttribute('source', module.source);
      }
      element.addContent(inReplyTo);
    }
  }
}
