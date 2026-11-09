// Behavior of JDOM 2.0.6.1 org.jdom2.Document, ContentList checks and printDocType (JDOM license, see LICENSE-JDOM)
import { CDATA, Content, DocType, Element, Parent, Text } from './Dom';
import { isAllXMLWhitespace } from './Format';
import { IllegalAddException } from './Verifier';

// AbstractXMLOutputProcessor.printDocType, shared by the writer and DocType.toString.
export function docTypeDeclaration(docType: DocType, lineSeparator: string | null): string {
  const publicID = docType.getPublicID();
  const systemID = docType.getSystemID();
  const internalSubset = docType.getInternalSubset();
  let out = `<!DOCTYPE ${docType.getElementName()}`;
  if (publicID !== null) {
    out += ` PUBLIC "${publicID}"`;
  }
  if (systemID !== null) {
    out += `${publicID === null ? ' SYSTEM' : ''} "${systemID}"`;
  }
  if (internalSubset !== null && internalSubset !== '') {
    out += ` [${lineSeparator ?? ''}${internalSubset}]`;
  }
  return out + '>';
}

// JDOM ContentList.checkIndex. Java throws IndexOutOfBoundsException.
export function checkIndex(index: number, size: number): void {
  if (index < 0 || index > size) {
    throw new Error(`Index: ${index} Size: ${size}`);
  }
}

const JDOM_CLASSES: string[] = ['Element', 'Text', 'CDATA', 'Comment', 'ProcessingInstruction', 'DocType'];

// JDOM ContentList.checkPreConditions. JDOM casts any parented child of a document to Element here, so other
// content fails with a ClassCastException.
export function checkPreConditions(parent: Parent, child: Content): void {
  const p = child.parent;
  if (p instanceof Element) {
    throw new IllegalAddException(`The Content already has an existing parent "${p.getQualifiedName()}"`);
  }
  if (p !== null) {
    if (!(child instanceof Element)) {
      const name = JDOM_CLASSES[child.getCType() as number];
      throw new Error(`class org.jdom2.${name} cannot be cast to class org.jdom2.Element (org.jdom2.${name} and ` +
        `org.jdom2.Element are in unnamed module of loader 'app')`);
    }
    throw new IllegalAddException(`The element "${child.getQualifiedName()}" could not be added as the root of the ` +
      'document: The Content already has an existing parent document');
  }
  if (parent instanceof Element && child instanceof Element) {
    if (child === parent) {
      throw new IllegalAddException('The Element cannot be added to itself');
    }
    // A childless element is nobody's ancestor; skipping the walk keeps building deep trees linear.
    if (child.getContentSize() > 0 && child.isAncestor(parent)) {
      throw new IllegalAddException('The Element cannot be added as a descendent of itself');
    }
  }
}

export class Document implements Parent {
  private content: Content[] = [];

  constructor(root?: Element) {
    if (root !== undefined) {
      this.setRootElement(root);
    }
  }

  hasRootElement(): boolean {
    return this.content.some((c: Content) => c instanceof Element);
  }

  getRootElement(): Element {
    for (const c of this.content) {
      if (c instanceof Element) {
        return c;
      }
    }
    throw new Error('Root element not set');
  }

  setRootElement(root: Element): Document {
    const index = this.indexOfFirstElement();
    if (index < 0) {
      this.adopt(root, this.content.length);
    } else {
      this.replace(index, root);
    }
    return this;
  }

  getDocType(): DocType | null {
    const index = this.indexOfDocType();
    return index < 0 ? null : this.content[index] as DocType;
  }

  // A new doctype goes first, an existing one is replaced in place, as in JDOM.
  setDocType(docType: DocType | null): Document {
    const index = this.indexOfDocType();
    if (docType === null) {
      if (index >= 0) {
        this.content.splice(index, 1)[0].parent = null;
      }
      return this;
    }
    if (docType.parent !== null) {
      throw new IllegalAddException(`The DOCTYPE ${docType.toString()} could not be added to the document: ` +
        'The DocType already is attached to a document');
    }
    if (index < 0) {
      this.adopt(docType, 0);
    } else {
      this.replace(index, docType);
    }
    return this;
  }

  getContent(): Content[] {
    return this.content.slice();
  }

  indexOf(child: Content): number {
    return this.content.indexOf(child);
  }

  addContent(child: Content): Document {
    this.adopt(child, this.content.length);
    return this;
  }

  addContentAt(index: number, child: Content): Document {
    checkIndex(index, this.content.length);
    this.adopt(child, index);
    return this;
  }

  removeContent(child?: Content): Content[] {
    if (child === undefined) {
      const removed = this.content;
      this.content = [];
      for (const c of removed) {
        c.parent = null;
      }
      return removed;
    }
    const index = this.content.indexOf(child);
    if (index < 0) {
      return [];
    }
    this.content.splice(index, 1);
    child.parent = null;
    return [child];
  }

  private indexOfFirstElement(): number {
    return this.content.findIndex((c: Content) => c instanceof Element);
  }

  private indexOfDocType(): number {
    return this.content.findIndex((c: Content) => c instanceof DocType);
  }

  private adopt(child: Content, index: number): void {
    checkPreConditions(this, child);
    this.canContainContent(child, index, false);
    child.parent = this;
    this.content.splice(index, 0, child);
  }

  // JDOM ContentList.set.
  private replace(index: number, child: Content): void {
    checkPreConditions(this, child);
    this.canContainContent(child, index, true);
    this.content[index].parent = null;
    child.parent = this;
    this.content[index] = child;
  }

  // JDOM Document.canContainContent: one root element, one doctype before it, whitespace-only Text.
  private canContainContent(child: Content, index: number, replace: boolean): void {
    if (child instanceof Element) {
      const root = this.indexOfFirstElement();
      if (replace && root === index) {
        return;
      }
      if (root >= 0) {
        throw new IllegalAddException('Cannot add a second root element, only one is allowed');
      }
      if (this.indexOfDocType() >= index) {
        throw new IllegalAddException('A root element cannot be added before the DocType');
      }
    }
    if (child instanceof DocType) {
      const docType = this.indexOfDocType();
      if (replace && docType === index) {
        return;
      }
      if (docType >= 0) {
        throw new IllegalAddException('Cannot add a second doctype, only one is allowed');
      }
      const root = this.indexOfFirstElement();
      if (root !== -1 && root < index) {
        throw new IllegalAddException('A DocType cannot be added after the root element');
      }
    }
    if (child instanceof CDATA) {
      throw new IllegalAddException('A CDATA is not allowed at the document root');
    }
    if (child instanceof Text && !isAllXMLWhitespace(child.getText())) {
      throw new IllegalAddException('A Text is not allowed at the document root');
    }
  }
}
