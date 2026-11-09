// Ported from ROME rome/src/main/java/com/rometools/rome/io/impl/RSS20Parser.java (Apache-2.0)
import { Document } from '../../xml/Dom';
import { Strings } from '../../utils/Strings';
import { RSS094Parser } from './RSS094Parser';

export class RSS20Parser extends RSS094Parser {
  constructor(type: string = 'rss_2.0') {
    super(type);
  }

  protected getRSSVersion(): string {
    return '2.0';
  }

  // A version attribute that only starts with the version still matches, as does a missing one.
  isMyType(document: Document): boolean {
    const rssRoot = document.getRootElement();
    const version = rssRoot.getAttribute('version');
    return rssRoot.getName() === 'rss' && (version === null || Strings.trim(version.getValue())!.startsWith(this.getRSSVersion()));
  }
}
