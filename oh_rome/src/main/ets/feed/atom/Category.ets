// Ported from ROME rome/src/main/java/com/rometools/rome/feed/atom/Category.java (Apache-2.0)
import { Alternatives } from '../../utils/Alternatives';

export class Category {
  term: string | null = null;
  scheme: string | null = null;
  private _schemeResolved: string | null = null;
  label: string | null = null;

  get schemeResolved(): string | null {
    return Alternatives.firstNotNull(this._schemeResolved, this.scheme);
  }

  set schemeResolved(schemeResolved: string | null) {
    this._schemeResolved = schemeResolved;
  }
}
