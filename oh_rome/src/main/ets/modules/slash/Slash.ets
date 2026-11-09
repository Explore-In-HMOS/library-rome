// Ported from ROME rome-modules/src/main/java/com/rometools/modules/slash/{Slash,SlashImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../feed/module/Module';

export class Slash extends ModuleImpl {
  static readonly URI: string = 'http://purl.org/rss/1.0/modules/slash/';
  section: string | null = null;
  department: string | null = null;
  comments: number | null = null;
  hitParade: number[] = [];

  constructor() {
    super(Slash.URI);
  }

  clone(): Slash {
    const copy = new Slash();
    copy.copyFrom(this);
    return copy;
  }

  copyFrom(obj: Module): void {
    const source = obj as Slash;
    this.hitParade = source.hitParade.slice();
    this.comments = source.comments;
    this.department = source.department;
    this.section = source.section;
  }
}
