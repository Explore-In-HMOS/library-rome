// Ported from ROME rome-opml/src/main/java/com/rometools/opml/io/impl/OPML20Parser.java (Apache-2.0)
import { Document, Element } from '../../../xml/Dom';
import { WireFeed } from '../../../feed/WireFeed';
import { DateParser } from '../../../io/impl/DateParser';
import { Attribute } from '../../feed/opml/Attribute';
import { Opml } from '../../feed/opml/Opml';
import { Outline } from '../../feed/opml/Outline';
import { OPML10Parser } from './OPML10Parser';

// Java String.split(","): no separator gives the whole string, otherwise trailing empty strings are dropped.
function javaSplitComma(value: string): string[] {
  const parts = value.split(',');
  if (parts.length === 1) {
    return parts;
  }
  while (parts.length > 0 && parts[parts.length - 1].length === 0) {
    parts.pop();
  }
  return parts;
}

export class OPML20Parser extends OPML10Parser {
  constructor() {
    super('opml_2.0');
  }

  isMyType(document: Document): boolean {
    const e = document.getRootElement();
    const head = e.getChild('head');
    return e.getName() === 'opml' && (head !== null && head.getChild('docs') !== null ||
      e.getAttributeValue('version') === '2.0' || head !== null && head.getChild('ownerId') !== null);
  }

  parse(document: Document): WireFeed {
    const opml = super.parse(document) as Opml;
    const head = document.getRootElement().getChild('head');
    if (head !== null) {
      opml.ownerId = head.getChildTextTrim('ownerId');
      opml.docs = head.getChildTextTrim('docs');
      if (opml.docs === null) {
        opml.docs = 'http://www.opml.org/spec2';
      }
    }
    opml.feedType = 'opml_2.0';
    return opml;
  }

  protected parseOutline(e: Element): Outline {
    const outline = super.parseOutline(e);
    outline.attributes = outline.attributes.filter((attribute: Attribute) => {
      if (attribute.name === 'created') {
        outline.created = DateParser.parseRFC822(attribute.value);
        return false;
      }
      if (attribute.name === 'category') {
        outline.categories = javaSplitComma(attribute.value);
        return false;
      }
      return true;
    });
    return outline;
  }
}
