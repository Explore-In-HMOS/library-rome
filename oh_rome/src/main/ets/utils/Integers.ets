// Ported from ROME rome-utils/src/main/java/com/rometools/utils/Integers.java (Apache-2.0)
import { parseJavaInt } from './JavaMath';

export class Integers {
  static parse(s: string | null): number | null {
    if (s === null) {
      return null;
    }
    try {
      return parseJavaInt(s);
    } catch (e) {
      return null;
    }
  }
}
