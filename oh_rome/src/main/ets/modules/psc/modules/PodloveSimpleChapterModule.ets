// Ported from ROME rome-modules/src/main/java/com/rometools/modules/psc/modules/{PodloveSimpleChapterModule,PodloveSimpleChapterModuleImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../../feed/module/Module';
import { SimpleChapter } from '../types/SimpleChapter';

function copyChapters(chapters: SimpleChapter[]): SimpleChapter[] {
  return chapters.map((c1: SimpleChapter) => {
    const c2 = new SimpleChapter();
    c2.copyFrom(c1);
    return c2;
  });
}

export class PodloveSimpleChapterModule extends ModuleImpl {
  static readonly URI: string = 'http://podlove.org/simple-chapters';
  static readonly VERSION: string = '1.2';
  chapters: SimpleChapter[] = [];

  constructor() {
    super(PodloveSimpleChapterModule.URI);
  }

  copyFrom(obj: Module): void {
    this.chapters = copyChapters((obj as PodloveSimpleChapterModule).chapters);
  }

  clone(): PodloveSimpleChapterModule {
    const mod = new PodloveSimpleChapterModule();
    mod.chapters = copyChapters(this.chapters);
    return mod;
  }
}
