// Ported from ROME rome-opml/src/main/java/com/rometools/opml/feed/synd/impl/ConverterForOPML20.java (Apache-2.0)
import { ConverterForOPML10 } from './ConverterForOPML10';

export class ConverterForOPML20 extends ConverterForOPML10 {
  getType(): string {
    return 'opml_2.0';
  }
}
