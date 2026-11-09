// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Rating.java (Apache-2.0)
import { AbstractSchemeValue } from './AbstractSchemeValue';

export class Rating extends AbstractSchemeValue {
  static readonly ADULT: Rating = new Rating('urn:simple', 'adult');
  static readonly NONADULT: Rating = new Rating('urn:simple', 'nonadult');

  constructor(scheme: string | null, value: string | null) {
    super(scheme, value);
  }

  equals(other: Rating | null): boolean {
    return other !== null && this.scheme === other.scheme && this.value === other.value;
  }
}
