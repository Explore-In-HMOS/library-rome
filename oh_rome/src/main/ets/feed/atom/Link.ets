// Ported from ROME rome/src/main/java/com/rometools/rome/feed/atom/Link.java (Apache-2.0)
import { Alternatives } from '../../utils/Alternatives';

export class Link {
  href: string | null = null;
  private _hrefResolved: string | null = null;
  rel: string | null = 'alternate';
  type: string | null = null;
  hreflang: string | null = null;
  title: string | null = null;
  length: number = 0;

  get hrefResolved(): string | null {
    return Alternatives.firstNotNull(this._hrefResolved, this.href);
  }

  set hrefResolved(hrefResolved: string | null) {
    this._hrefResolved = hrefResolved;
  }

  // ROME clones through CloneableBean (e.g. OpenSearch's module clone): every property is read through its getter
  // and set only when not null, so a null rel stays 'alternate' and hrefResolved takes the getter's fallback.
  clone(): Link {
    const copy = new Link();
    if (this.href !== null) {
      copy.href = this.href;
    }
    const resolved = this.hrefResolved;
    if (resolved !== null) {
      copy.hrefResolved = resolved;
    }
    if (this.rel !== null) {
      copy.rel = this.rel;
    }
    if (this.type !== null) {
      copy.type = this.type;
    }
    if (this.hreflang !== null) {
      copy.hreflang = this.hreflang;
    }
    if (this.title !== null) {
      copy.title = this.title;
    }
    copy.length = this.length;
    return copy;
  }
}
