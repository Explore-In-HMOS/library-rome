// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/io/ITunesParserOldNamespace.java (Apache-2.0)
import { Namespace } from '../../../xml/Dom';
import { ITunesParser } from './ITunesParser';

const URI: string = 'http://www.itunes.com/DTDs/Podcast-1.0.dtd';

// Parses the old Apple namespace into the same modules, under the current URI.
export class ITunesParserOldNamespace extends ITunesParser {
  constructor() {
    super();
    this.ns = Namespace.getNamespace(URI);
  }

  getNamespaceUri(): string {
    return URI;
  }
}
