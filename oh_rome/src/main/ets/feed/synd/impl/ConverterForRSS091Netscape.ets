// Ported from ROME rome/src/main/java/com/rometools/rome/feed/synd/impl/ConverterForRSS091Netscape.java (Apache-2.0)
import { ConverterForRSS091Userland } from './ConverterForRSS091Userland';

export class ConverterForRSS091Netscape extends ConverterForRSS091Userland {
  constructor(type: string = 'rss_0.91N') {
    super(type);
  }
}
