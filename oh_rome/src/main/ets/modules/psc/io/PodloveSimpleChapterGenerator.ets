// Ported from ROME rome-modules/src/main/java/com/rometools/modules/psc/io/PodloveSimpleChapterGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { PodloveSimpleChapterModule } from '../modules/PodloveSimpleChapterModule';
import { SimpleChapter } from '../types/SimpleChapter';
import { PodloveSimpleChapterAttribute } from './PodloveSimpleChapterAttribute';

const NS: Namespace = Namespace.getNamespace(PodloveSimpleChapterAttribute.PREFIX, PodloveSimpleChapterModule.URI);

function addNotNullAttribute(target: Element, name: string, value: string | null): void {
  if (value !== null) {
    target.setAttribute(name, value);
  }
}

export class PodloveSimpleChapterGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return PodloveSimpleChapterModule.URI;
  }

  getNamespaces(): Namespace[] {
    return [NS];
  }

  generate(module: Module, element: Element): void {
    if (module instanceof PodloveSimpleChapterModule) {
      const cs = new Element(PodloveSimpleChapterAttribute.CHAPTERS, NS);
      cs.setAttribute(PodloveSimpleChapterAttribute.VERSION, PodloveSimpleChapterModule.VERSION);
      for (const c of module.chapters) {
        cs.addContent(this.generateChapter(c));
      }
      element.addContent(cs);
    }
  }

  private generateChapter(c: SimpleChapter): Element {
    const e = new Element(PodloveSimpleChapterAttribute.CHAPTER, NS);
    addNotNullAttribute(e, PodloveSimpleChapterAttribute.START, c.start);
    addNotNullAttribute(e, PodloveSimpleChapterAttribute.TITLE, c.title);
    addNotNullAttribute(e, PodloveSimpleChapterAttribute.HREF, c.href);
    addNotNullAttribute(e, PodloveSimpleChapterAttribute.IMAGE, c.image);
    return e;
  }
}
