// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/UrlReference.java (Apache-2.0)
import { parseUri } from '../../../utils/JavaNet';
import { Reference } from './Reference';

export class UrlReference implements Reference {
  readonly url: string;

  constructor(url: string | null) {
    if (url === null) {
      throw new Error('url cannot be null.');
    }
    this.url = parseUri(url);
  }

  toString(): string {
    return this.url;
  }
}
