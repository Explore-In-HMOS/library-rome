// Ported from ROME rome-modules/src/main/java/com/rometools/modules/atom/modules/{AtomLinkModule,AtomLinkModuleImpl}.java (Apache-2.0)
import { Module, ModuleImpl } from '../../../feed/module/Module';
import { Link } from '../../../feed/atom/Link';
import { SyndPerson } from '../../../feed/synd/SyndPerson';

function copyLinks(from: Link[], to: Link[]): void {
  for (const link of from) {
    const l = new Link();
    l.href = link.href;
    l.type = link.type;
    l.rel = link.rel;
    l.hreflang = link.hreflang;
    l.title = link.title;
    l.length = link.length;
    to.push(l);
  }
}

function copyPerson(from: SyndPerson[], to: SyndPerson[]): void {
  for (const person of from) {
    const p = new SyndPerson();
    p.name = person.name;
    p.email = person.email;
    p.uri = person.uri;
    to.push(p);
  }
}

export class AtomLinkModule extends ModuleImpl {
  static readonly URI: string = 'http://www.w3.org/2005/Atom';
  links: Link[] = [];
  authors: SyndPerson[] = [];
  contributors: SyndPerson[] = [];

  constructor() {
    super(AtomLinkModule.URI);
  }

  // Deprecated in ROME: the first of links.
  get link(): Link | null {
    return this.links.length > 0 ? this.links[0] : null;
  }

  set link(link: Link | null) {
    if (this.links.length > 0) {
      this.links[0] = link!;
    } else {
      this.links.push(link!);
    }
  }

  copyFrom(obj: Module): void {
    const other = obj as AtomLinkModule;
    copyLinks(other.links, this.links);
    copyPerson(other.authors, this.authors);
    copyPerson(other.contributors, this.contributors);
  }

  clone(): AtomLinkModule {
    const m = new AtomLinkModule();
    copyLinks(this.links, m.links);
    copyPerson(this.authors, m.authors);
    copyPerson(this.contributors, m.contributors);
    return m;
  }
}
