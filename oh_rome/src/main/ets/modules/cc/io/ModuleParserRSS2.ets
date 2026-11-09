// Ported from ROME rome-modules/src/main/java/com/rometools/modules/cc/io/ModuleParserRSS2.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { CreativeCommons } from '../CreativeCommons';
import { License } from '../types/License';

const NS: Namespace = Namespace.getNamespace(CreativeCommons.RSS2_URI);

function licensesOf(element: Element): License[] {
  return element.getChildren('license', NS).map((tag: Element) => License.findByValue(tag.getTextTrim()));
}

export class ModuleParserRSS2 implements ModuleParser {
  // allLicenses collects the licenses of every item of the channel, or of the entries without a namespace of the feed
  // (so none of a real Atom feed); the module is returned only when both lists are non-empty.
  parse(element: Element): Module | null {
    const module = new CreativeCommons();
    let root = element;
    while (root.getName() !== 'channel' && root.getName() !== 'feed') {
      root = root.getParentElement()!;
    }
    const items = root.getName() === 'channel' ? root.getChildren('item') : root.getChildren('entry');
    const allLicenses: License[] = [];
    for (const item of items) {
      for (const license of licensesOf(item)) {
        allLicenses.push(license);
      }
    }
    if (allLicenses.length > 0) {
      module.allLicenses = allLicenses;
    }

    const licenses = licensesOf(element);
    if (licenses.length > 0) {
      module.licenses = licenses;
    }
    return module.licenses !== null && module.allLicenses !== null ? module : null;
  }

  getNamespaceUri(): string {
    return CreativeCommons.RSS2_URI;
  }
}
