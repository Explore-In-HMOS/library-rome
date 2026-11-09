// Ported from ROME rome-opml/src/main/java/com/rometools/opml/io/impl/OPML20Generator.java (Apache-2.0)
import { Document, Element } from '../../../xml/Dom';
import { WireFeed } from '../../../feed/WireFeed';
import { DateParser } from '../../../io/impl/DateParser';
import { Strings } from '../../../utils/Strings';
import { Opml } from '../../feed/opml/Opml';
import { Outline } from '../../feed/opml/Outline';
import { OPML10Generator } from './OPML10Generator';

// Module generators come from the "opml_1.0" scopes, as in ROME: the constructor passes opml_1.0 and only
// getType() says opml_2.0.
export class OPML20Generator extends OPML10Generator {
  getType(): string {
    return 'opml_2.0';
  }

  generate(feed: WireFeed): Document {
    const document = super.generate(feed);
    document.getRootElement().setAttribute('version', '2.0');
    return document;
  }

  protected generateHead(opml: Opml): Element | null {
    const headElement = super.generateHead(opml);
    if (headElement !== null && opml.docs !== null) {
      const docsElement = new Element('docs');
      docsElement.setText(opml.docs);
      headElement.addContent(docsElement);
    }
    return headElement;
  }

  protected generateOutline(outline: Outline): Element {
    const outlineElement = super.generateOutline(outline);
    if (outline.created !== null) {
      outlineElement.setAttribute('created', DateParser.formatRFC822(outline.created));
    }
    this.addNotNullAttribute(outlineElement, 'category', OPML20Generator.generateCategoryValue(outline.categories));
    return outlineElement;
  }

  private static generateCategoryValue(categories: string[]): string | null {
    const value = categories.map((c: string) => Strings.trim(c)!).filter((c: string) => c.length > 0).join(',');
    return value.length > 0 ? value : null;
  }
}
