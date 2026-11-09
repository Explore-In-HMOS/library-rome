// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Hash.java (Apache-2.0)
import { AbstractSchemeValue } from './AbstractSchemeValue';

export class Hash extends AbstractSchemeValue {
  constructor(algorithm: string | null, value: string | null) {
    super(algorithm === null ? 'MD5' : algorithm, value);
  }

  get algorithm(): string {
    return this.scheme;
  }
}
