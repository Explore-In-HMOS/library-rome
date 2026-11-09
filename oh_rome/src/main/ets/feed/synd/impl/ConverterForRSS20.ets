// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS20.java (Apache-2.0)
import { ConverterForRSS094 } from './ConverterForRSS094';

export class ConverterForRSS20 extends ConverterForRSS094 {
  constructor(type: string = 'rss_2.0') {
    super(type);
  }
}
