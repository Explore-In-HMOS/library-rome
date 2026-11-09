// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/AbstractSchemeValue.java (Apache-2.0)

export abstract class AbstractSchemeValue {
  readonly scheme: string;
  readonly value: string;

  constructor(scheme: string | null, value: string | null) {
    if (scheme === null || value === null) {
      throw new Error('Scheme and value cannot be null.');
    }
    this.scheme = scheme;
    this.value = value;
  }
}
