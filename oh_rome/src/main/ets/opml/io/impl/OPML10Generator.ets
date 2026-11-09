// Ported from ROME rome-opml/src/main/java/com/rometools/opml/io/impl/OPML10Generator.java (Apache-2.0)
import { Document, Element } from '../../../xml/Dom';
import { WireFeed } from '../../../feed/WireFeed';
import { BaseWireFeedGenerator } from '../../../io/impl/BaseWireFeedGenerator';
import { DateParser } from '../../../io/impl/DateParser';
import { IllegalArgumentException } from '../../../utils/Exceptions';
import { Opml } from '../../feed/opml/Opml';
import { Outline } from '../../feed/opml/Outline';

export class OPML10Generator extends BaseWireFeedGenerator {
  constructor(type: string = 'opml_1.0') {
    super(type);
  }

  generate(feed: WireFeed): Document {
    if (!(feed instanceof Opml)) {
      throw new IllegalArgumentException('Not an OPML file');
    }
    const opml = feed as Opml;
    const root = new Element('opml');
    root.setAttribute('version', '1.0');
    const doc = new Document(root);
    const head = this.generateHead(opml);
    if (head !== null) {
      root.addContent(head);
    }
    const body = new Element('body');
    root.addContent(body);
    this.generateFeedModules(opml.modules, root);
    body.addContent(this.generateOutlines(opml.outlines));
    return doc;
  }

  protected addNotNullAttribute(target: Element, name: string, value: string | null): boolean {
    if (value === null) {
      return false;
    }
    target.setAttribute(name, value);
    return true;
  }

  protected addNotNullSimpleElement(target: Element, name: string, value: string | number | null): boolean {
    if (value === null) {
      return false;
    }
    const e = new Element(name);
    e.addContent(`${value}`);
    target.addContent(e);
    return true;
  }

  protected generateHead(opml: Opml): Element | null {
    const head = new Element('head');
    let hasHead = false;
    if (opml.created !== null) {
      hasHead = this.addNotNullSimpleElement(head, 'dateCreated', DateParser.formatRFC822(opml.created)) || hasHead;
    }
    hasHead = this.addNotNullSimpleElement(head, 'expansionState', OPML10Generator.intArrayToCsvString(opml.expansionState)) ||
      hasHead;
    if (opml.modified !== null) {
      hasHead = this.addNotNullSimpleElement(head, 'dateModified', DateParser.formatRFC822(opml.modified)) || hasHead;
    }
    hasHead = this.addNotNullSimpleElement(head, 'ownerEmail', opml.ownerEmail) || hasHead;
    hasHead = this.addNotNullSimpleElement(head, 'ownerName', opml.ownerName) || hasHead;
    hasHead = this.addNotNullSimpleElement(head, 'title', opml.title) || hasHead;
    hasHead = this.addNotNullSimpleElement(head, 'vertScrollState', opml.verticalScrollState) || hasHead;
    hasHead = this.addNotNullSimpleElement(head, 'windowBottom', opml.windowBottom) || hasHead;
    hasHead = this.addNotNullSimpleElement(head, 'windowLeft', opml.windowLeft) || hasHead;
    hasHead = this.addNotNullSimpleElement(head, 'windowRight', opml.windowRight) || hasHead;
    hasHead = this.addNotNullSimpleElement(head, 'windowTop', opml.windowTop) || hasHead;
    return hasHead ? head : null;
  }

  protected generateOutline(outline: Outline): Element {
    const e = new Element('outline');
    this.addNotNullAttribute(e, 'text', outline.text);
    this.addNotNullAttribute(e, 'type', outline.type);
    this.addNotNullAttribute(e, 'title', outline.title);
    if (outline.breakpoint) {
      this.addNotNullAttribute(e, 'isBreakpoint', 'true');
    }
    if (outline.comment) {
      this.addNotNullAttribute(e, 'isComment', 'true');
    }
    for (const att of outline.attributes) {
      this.addNotNullAttribute(e, att.name, att.value);
    }
    this.generateItemModules(outline.modules, e);
    e.addContent(this.generateOutlines(outline.children));
    return e;
  }

  protected generateOutlines(outlines: Outline[]): Element[] {
    return outlines.map((outline: Outline) => this.generateOutline(outline));
  }

  private static intArrayToCsvString(value: number[] | null): string | null {
    return value === null || value.length === 0 ? null : value.join(',');
  }
}
