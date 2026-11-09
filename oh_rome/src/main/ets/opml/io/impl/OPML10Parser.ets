// Ported from ROME rome-opml/src/main/java/com/rometools/opml/io/impl/OPML10Parser.java (Apache-2.0)
import { Document, Element } from '../../../xml/Dom';
import { WireFeed } from '../../../feed/WireFeed';
import { BaseWireFeedParser } from '../../../io/impl/BaseWireFeedParser';
import { DateParser } from '../../../io/impl/DateParser';
import { Integers } from '../../../utils/Integers';
import { parseJavaInt } from '../../../utils/JavaMath';
import { Strings } from '../../../utils/Strings';
import { Attribute } from '../../feed/opml/Attribute';
import { Opml } from '../../feed/opml/Opml';
import { Outline } from '../../feed/opml/Outline';

// isBreakpoint and isComment are dropped: ROME reads them with Boolean.getBoolean, which looks up a JVM system
// property of that name, so breakpoint and comment are always false.
const NOT_ATTRIBUTES: string[] = ['isBreakpoint', 'isComment', 'title', 'text', 'type'];

export class OPML10Parser extends BaseWireFeedParser {
  constructor(type: string = 'opml_1.0') {
    super(type, null);
  }

  isMyType(document: Document): boolean {
    const e = document.getRootElement();
    const head = e.getChild('head');
    const version = e.getAttributeValue('version');
    return e.getName() === 'opml' && (head === null || head.getChild('docs') === null) &&
      (version === null || version === '1.0');
  }

  // Throws NumberFormatException for a bad vertScrollState; bad window* values and expansionState stay null.
  parse(document: Document): WireFeed {
    const opml = new Opml();
    opml.feedType = 'opml_1.0';
    const root = document.getRootElement();
    const head = root.getChild('head');
    if (head !== null) {
      opml.title = head.getChildText('title');
      const created = head.getChildText('dateCreated');
      if (created !== null) {
        opml.created = DateParser.parseRFC822(created);
      }
      const modified = head.getChildText('dateModified');
      if (modified !== null) {
        opml.modified = DateParser.parseRFC822(modified);
      }
      opml.ownerName = head.getChildTextTrim('ownerName');
      opml.ownerEmail = head.getChildTextTrim('ownerEmail');
      const vertScrollState = head.getChildText('vertScrollState');
      opml.verticalScrollState = vertScrollState === null ? null : parseJavaInt(vertScrollState);
      opml.windowBottom = Integers.parse(head.getChildText('windowBottom'));
      opml.windowLeft = Integers.parse(head.getChildText('windowLeft'));
      opml.windowRight = Integers.parse(head.getChildText('windowRight'));
      opml.windowTop = Integers.parse(head.getChildText('windowTop'));
      try {
        opml.expansionState = OPML10Parser.readIntArray(head.getChildText('expansionState'));
      } catch (e) {
        opml.expansionState = null;
      }
    }
    opml.outlines = this.parseOutlines(root.getChild('body')!.getChildren('outline'));
    opml.modules = this.parseFeedModules(root);
    return opml;
  }

  protected parseOutline(e: Element): Outline {
    if (e.getName() !== 'outline') {
      throw new Error('Not an outline element.');
    }
    const outline = new Outline();
    outline.text = e.getAttributeValue('text');
    outline.type = e.getAttributeValue('type');
    outline.title = e.getAttributeValue('title');
    for (const a of e.getAttributes()) {
      if (!NOT_ATTRIBUTES.includes(a.getName())) {
        outline.attributes.push(new Attribute(a.getName(), a.getValue()));
      }
    }
    outline.modules = this.parseItemModules(e);
    outline.children = this.parseOutlines(e.getChildren('outline'));
    return outline;
  }

  protected parseOutlines(elements: Element[]): Outline[] {
    return elements.map((e: Element) => this.parseOutline(e));
  }

  // java.util.StringTokenizer on ',' skips empty tokens.
  private static readIntArray(value: string | null): number[] | null {
    if (value === null) {
      return null;
    }
    return value.split(',').filter((t: string) => t.length > 0).map((t: string) => parseJavaInt(Strings.trim(t)!));
  }
}
