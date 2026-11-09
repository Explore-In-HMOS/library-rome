// Ported from ROME rome-utils/src/main/java/com/rometools/utils/Longs.java (Apache-2.0)
import { Doubles } from './Doubles';

export class Longs {
  // (long) Double.parseDouble(s): NaN and -0.0 give 0, out-of-range values saturate (Long.MAX_VALUE is 2^63 here).
  static parseDecimal(s: string | null): number | null {
    const parsed = Doubles.parse(s);
    if (parsed === null) {
      return null;
    }
    return Number.isNaN(parsed) ? 0 : Math.min(Math.max(Math.trunc(parsed), -(2 ** 63)), 2 ** 63) + 0;
  }
}
