// Ported from ROME rome-modules/src/main/java/com/rometools/modules/psc/io/PodloveSimpleChapterParser.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { PodloveSimpleChapterModule } from '../modules/PodloveSimpleChapterModule';
import { SimpleChapter } from '../types/SimpleChapter';
import { PodloveSimpleChapterAttribute } from './PodloveSimpleChapterAttribute';

const NS: Namespace = Namespace.getNamespace(PodloveSimpleChapterModule.URI);

export class PodloveSimpleChapterParser implements ModuleParser {
  getNamespaceUri(): string {
    return PodloveSimpleChapterModule.URI;
  }

  parse(element: Element): Module | null {
    const chaptersElement = element.getChild(PodloveSimpleChapterAttribute.CHAPTERS, NS);
    if (chaptersElement !== null) {
      const es = chaptersElement.getChildren(PodloveSimpleChapterAttribute.CHAPTER, NS);
      if (es.length > 0) {
        const m = new PodloveSimpleChapterModule();
        m.chapters = es.map((e: Element) => this.parseChapter(e));
        return m;
      }
    }
    return null;
  }

  private parseChapter(eChapter: Element): SimpleChapter {
    const chapter = new SimpleChapter();
    const start = this.getAttributeValue(eChapter, PodloveSimpleChapterAttribute.START);
    if (start !== null) {
      chapter.start = start;
    }
    const title = this.getAttributeValue(eChapter, PodloveSimpleChapterAttribute.TITLE);
    if (title !== null) {
      chapter.title = title;
    }
    const href = this.getAttributeValue(eChapter, PodloveSimpleChapterAttribute.HREF);
    if (href !== null) {
      chapter.href = href;
    }
    const image = this.getAttributeValue(eChapter, PodloveSimpleChapterAttribute.IMAGE);
    if (image !== null) {
      chapter.image = image;
    }
    return chapter;
  }

  protected getAttributeValue(e: Element, attributeName: string): string | null {
    const attr = e.getAttribute(attributeName) ?? e.getAttribute(attributeName, NS);
    return attr !== null ? attr.getValue() : null;
  }
}
