// Ported from ROME rome-modules/src/main/java/com/rometools/modules/slash/io/SlashModuleGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { Slash } from '../Slash';

const NAMESPACE: Namespace = Namespace.getNamespace('slash', Slash.URI);

export class SlashModuleGenerator implements ModuleGenerator {
  generate(module: Module, element: Element): void {
    if (!(module instanceof Slash)) {
      return;
    }
    const slash = module as Slash;
    if (slash.comments !== null) {
      element.addContent(this.generateSimpleElement('comments', String(slash.comments)));
    }
    if (slash.department !== null) {
      element.addContent(this.generateSimpleElement('department', slash.department));
    }
    if (slash.section !== null) {
      element.addContent(this.generateSimpleElement('section', slash.section));
    }
    if (slash.hitParade.length > 0) {
      element.addContent(this.generateSimpleElement('hit_parade', slash.hitParade.join(',')));
    }
  }

  protected generateSimpleElement(name: string, value: string): Element {
    const element = new Element(name, NAMESPACE);
    element.addContent(value);
    return element;
  }

  getNamespaces(): Namespace[] {
    return [NAMESPACE];
  }

  getNamespaceUri(): string {
    return Slash.URI;
  }
}
