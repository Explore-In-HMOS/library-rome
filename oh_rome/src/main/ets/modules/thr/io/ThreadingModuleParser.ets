// Ported from ROME rome-modules/src/main/java/com/rometools/modules/thr/io/ThreadingModuleParser.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { ThreadingModule } from '../ThreadingModule';

const NS: Namespace = Namespace.getNamespace(ThreadingModule.URI);

export class ThreadingModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return ThreadingModule.URI;
  }

  parse(element: Element): Module | null {
    const inReplyTo = element.getChild('in-reply-to', NS);
    if (inReplyTo === null) {
      return null;
    }
    const tm = new ThreadingModule();
    tm.href = inReplyTo.getAttributeValue('href');
    tm.ref = inReplyTo.getAttributeValue('ref');
    tm.source = inReplyTo.getAttributeValue('source');
    tm.type = inReplyTo.getAttributeValue('type');
    return tm;
  }
}
