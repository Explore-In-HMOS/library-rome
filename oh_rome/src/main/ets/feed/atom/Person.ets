// Ported from ROME rome/src/main/java/com/rometools/rome/feed/atom/Person.java (Apache-2.0)
import { Alternatives } from '../../utils/Alternatives';
import { SyndPerson } from '../synd/SyndPerson';

export class Person extends SyndPerson {
  // Write-only in ROME: there is no getter without a parameter, only getUriResolved(resolveURI).
  uriResolved: string | null = null;

  // Atom 0.3 name of uri.
  get url(): string | null {
    return this.uri;
  }

  set url(url: string | null) {
    this.uri = url;
  }

  getUriResolved(resolveURI: string | null): string | null {
    return Alternatives.firstNotNull(this.uriResolved, this.uri);
  }
}
