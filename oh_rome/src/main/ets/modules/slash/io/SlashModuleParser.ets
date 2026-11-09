// Ported from ROME rome-modules/src/main/java/com/rometools/modules/slash/io/SlashModuleParser.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { parseJavaInt } from '../../../utils/JavaMath';
import { Strings } from '../../../utils/Strings';
import { Slash } from '../Slash';

const NS: Namespace = Namespace.getNamespace(Slash.URI);

export class SlashModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return Slash.URI;
  }

  // Always returns a module: ROME's hitParade getter is never null.
  parse(element: Element): Module | null {
    const si = new Slash();
    let tag = element.getChild('hit_parade', NS);
    if (tag !== null) {
      si.hitParade = tag.getText().split(',').filter((t: string) => t.length > 0).map((t: string) => parseJavaInt(t));
    }
    tag = element.getChild('comments', NS);
    if (tag !== null && Strings.trim(tag.getText())!.length > 0) {
      si.comments = parseJavaInt(Strings.trim(tag.getText())!);
    }
    tag = element.getChild('department', NS);
    if (tag !== null) {
      si.department = Strings.trim(tag.getText());
    }
    tag = element.getChild('section', NS);
    if (tag !== null) {
      si.section = Strings.trim(tag.getText());
    }
    return si;
  }
}
