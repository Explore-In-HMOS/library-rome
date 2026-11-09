// Ported from ROME rome-utils/src/main/java/com/rometools/utils/URIs.java (Apache-2.0)
import { parseUri } from './JavaNet';

export class URIs {
  static parse(str: string): string {
    return parseUri(str.split(' ').join('%20'));
  }
}
