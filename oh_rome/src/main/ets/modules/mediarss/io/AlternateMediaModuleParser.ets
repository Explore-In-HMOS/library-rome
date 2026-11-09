// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/io/AlternateMediaModuleParser.java (Apache-2.0)
import { Namespace } from '../../../xml/Dom';
import { MediaModuleParser } from './MediaModuleParser';

const URI: string = 'http://search.yahoo.com/mrss';
const NS: Namespace = Namespace.getNamespace(URI);

export class AlternateMediaModuleParser extends MediaModuleParser {
  getNamespaceUri(): string {
    return URI;
  }

  getNS(): Namespace {
    return NS;
  }
}
