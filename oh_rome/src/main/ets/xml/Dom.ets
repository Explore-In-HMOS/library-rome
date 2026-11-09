// XML object model replacing the subset of JDOM 2 (org.jdom2) that ROME uses.
// Method names and semantics follow JDOM so ported ROME code reads the same.
import { Strings } from '../utils/Strings';
import { checkIndex, checkPreConditions, docTypeDeclaration } from './Document';
import {
  IllegalAddException, illegalAddAttribute, illegalAddNamespace, IllegalDataException, IllegalNameException,
  IllegalTargetException, Verifier
} from './Verifier';

export { Document } from './Document';

const XML_URI = 'http://www.w3.org/XML/1998/namespace';
const XMLNS_URI = 'http://www.w3.org/2000/xmlns/';

export class Namespace {
  static readonly NO_NAMESPACE: Namespace = new Namespace('', '');
  static readonly XML_NAMESPACE: Namespace = new Namespace('xml', XML_URI);

  private readonly prefix: string;
  private readonly uri: string;

  private constructor(prefix: string, uri: string) {
    this.prefix = prefix;
    this.uri = uri;
  }

  // JDOM: getNamespace(uri) has an empty prefix; getNamespace(prefix, uri) sets both.
  static getNamespace(prefixOrUri: string | null, uri?: string | null): Namespace {
    const prefix = uri === undefined || prefixOrUri === null ? '' : prefixOrUri;
    const nsUri = uri === undefined ? prefixOrUri : uri;
    if (nsUri === null || nsUri === '') {
      if (prefix === '') {
        return Namespace.NO_NAMESPACE;
      }
      throw new IllegalNameException('', 'namespace', 'Namespace URIs must be non-null and non-empty Strings');
    }
    const uriReason = Verifier.checkNamespaceURI(nsUri);
    if (uriReason !== null) {
      throw new IllegalNameException(nsUri, 'Namespace URI', uriReason);
    }
    if (prefix === 'xml' && nsUri === XML_URI) {
      return Namespace.XML_NAMESPACE;
    }
    if (prefix === 'xmlns' && nsUri === XMLNS_URI) {
      return new Namespace(prefix, nsUri);
    }
    if (nsUri === XML_URI || nsUri === XMLNS_URI) {
      const bound = nsUri === XML_URI ? 'xml' : 'xmlns';
      throw new IllegalNameException(nsUri, 'Namespace URI', `The ${nsUri} must be bound to only the '${bound}' prefix.`);
    }
    if (prefix === 'xml' || prefix === 'xmlns') {
      const bound = prefix === 'xml' ? XML_URI : XMLNS_URI;
      throw new IllegalNameException(nsUri, 'Namespace prefix',
        `The prefix ${prefix} (any case) can only be bound to only the '${bound}' uri.`);
    }
    const prefixReason = Verifier.checkNamespacePrefix(prefix);
    if (prefixReason !== null) {
      throw new IllegalNameException(prefix, 'Namespace prefix', prefixReason);
    }
    return new Namespace(prefix, nsUri);
  }

  getPrefix(): string {
    return this.prefix;
  }

  getURI(): string {
    return this.uri;
  }

  // JDOM namespaces are equal when their URIs are equal; the prefix is ignored.
  equals(other: Namespace | null): boolean {
    return other !== null && other.uri === this.uri;
  }
}

export class Attribute {
  private name: string = '';
  private value: string = '';
  private namespace: Namespace = Namespace.NO_NAMESPACE;
  parent: Element | null = null;

  constructor(name: string, value: string, namespace?: Namespace | null) {
    this.setName(name);
    this.setValue(value);
    this.setNamespace(namespace === undefined ? null : namespace);
  }

  getName(): string {
    return this.name;
  }

  setName(name: string): Attribute {
    const reason = Verifier.checkAttributeName(name);
    if (reason !== null) {
      throw new IllegalNameException(name, 'attribute', reason);
    }
    this.name = name;
    return this;
  }

  getValue(): string {
    return this.value;
  }

  setValue(value: string): Attribute {
    const reason = Verifier.checkCharacterData(value);
    if (reason !== null) {
      throw new IllegalDataException(value, 'attribute', reason);
    }
    this.value = value;
    return this;
  }

  getNamespace(): Namespace {
    return this.namespace;
  }

  setNamespace(namespace: Namespace | null): Attribute {
    const ns = namespace === null ? Namespace.NO_NAMESPACE : namespace;
    if (ns !== Namespace.NO_NAMESPACE && ns.getPrefix() === '') {
      throw new IllegalNameException('', 'attribute namespace',
        'An attribute namespace without a prefix can only be the NO_NAMESPACE namespace');
    }
    this.namespace = ns;
    return this;
  }

  getNamespacePrefix(): string {
    return this.namespace.getPrefix();
  }

  getNamespaceURI(): string {
    return this.namespace.getURI();
  }

  getQualifiedName(): string {
    const prefix = this.namespace.getPrefix();
    return prefix === '' ? this.name : `${prefix}:${this.name}`;
  }

  getParent(): Element | null {
    return this.parent;
  }

  detach(): Attribute {
    if (this.parent !== null) {
      this.parent.removeAttribute(this.name, this.namespace);
    }
    return this;
  }

  clone(): Attribute {
    return new Attribute(this.name, this.value, this.namespace);
  }
}

export enum CType {
  Element,
  Text,
  CDATA,
  Comment,
  ProcessingInstruction,
  DocType,
  EntityRef
}

export interface Parent {
  getContent(): Content[];
  indexOf(child: Content): number;
  removeContent(child?: Content): Content[];
}

export abstract class Content {
  parent: Parent | null = null;

  abstract getCType(): CType;

  abstract getValue(): string;

  abstract clone(): Content;

  getParent(): Parent | null {
    return this.parent;
  }

  getParentElement(): Element | null {
    return this.parent instanceof Element ? this.parent : null;
  }

  detach(): Content {
    if (this.parent !== null) {
      this.parent.removeContent(this);
    }
    return this;
  }
}

export class Text extends Content {
  protected text: string = '';

  constructor(text: string) {
    super();
    this.setText(text);
  }

  getCType(): CType {
    return CType.Text;
  }

  getText(): string {
    return this.text;
  }

  getTextTrim(): string {
    return Strings.trimToEmpty(this.text);
  }

  setText(text: string): Text {
    const reason = Verifier.checkCharacterData(text);
    if (reason !== null) {
      throw new IllegalDataException(text, 'character content', reason);
    }
    this.text = text;
    return this;
  }

  append(text: string): void {
    const reason = Verifier.checkCharacterData(text);
    if (reason !== null) {
      throw new IllegalDataException(text, 'character content', reason);
    }
    this.text += text;
  }

  getValue(): string {
    return this.text;
  }

  clone(): Text {
    return new Text(this.text);
  }
}

export class CDATA extends Text {
  constructor(text: string) {
    super(text);
  }

  getCType(): CType {
    return CType.CDATA;
  }

  setText(text: string): CDATA {
    const reason = Verifier.checkCDATASection(text);
    if (reason !== null) {
      throw new IllegalDataException(text, 'CDATA section', reason);
    }
    this.text = text;
    return this;
  }

  // JDOM checks the joined text, since "]" + "]>" ends the section too. The text so far already passed, so checking the
  // appended part after the text's trailing "]"s gives the same result. The message names only the appended part.
  append(text: string): void {
    const tail = this.text.endsWith(']]') ? ']]' : this.text.endsWith(']') ? ']' : '';
    const reason = Verifier.checkCDATASection(tail + text);
    if (reason !== null) {
      throw new IllegalDataException(text, 'CDATA section', reason);
    }
    this.text += text;
  }

  clone(): CDATA {
    return new CDATA(this.text);
  }
}

export class Comment extends Content {
  private text: string;

  constructor(text: string) {
    super();
    const reason = Verifier.checkCommentData(text);
    if (reason !== null) {
      throw new IllegalDataException(text, 'comment', reason);
    }
    this.text = text;
  }

  getCType(): CType {
    return CType.Comment;
  }

  getText(): string {
    return this.text;
  }

  getValue(): string {
    return this.text;
  }

  clone(): Comment {
    return new Comment(this.text);
  }
}

const PSEUDO_ATTRIBUTE: RegExp = /([^\s=]+)\s*=\s*("([^"]*)"|'([^']*)')/g;

export class ProcessingInstruction extends Content {
  private target: string;
  private data: string;

  constructor(target: string, data: string) {
    super();
    const targetReason = Verifier.checkProcessingInstructionTarget(target);
    if (targetReason !== null) {
      throw new IllegalTargetException(target, targetReason);
    }
    const dataReason = Verifier.checkProcessingInstructionData(data);
    if (dataReason !== null) {
      throw new IllegalDataException(data, dataReason);
    }
    this.target = target;
    this.data = data;
  }

  getCType(): CType {
    return CType.ProcessingInstruction;
  }

  getTarget(): string {
    return this.target;
  }

  getData(): string {
    return this.data;
  }

  // Reads name="value" pairs from the data, e.g. type="text/xsl" in <?xml-stylesheet ...?>.
  getPseudoAttributeValue(name: string): string | null {
    PSEUDO_ATTRIBUTE.lastIndex = 0;
    let match = PSEUDO_ATTRIBUTE.exec(this.data);
    while (match !== null) {
      if (match[1] === name) {
        return match[3] !== undefined ? match[3] : match[4];
      }
      match = PSEUDO_ATTRIBUTE.exec(this.data);
    }
    return null;
  }

  getValue(): string {
    return this.data;
  }

  clone(): ProcessingInstruction {
    return new ProcessingInstruction(this.target, this.data);
  }
}

export class DocType extends Content {
  private elementName: string;
  private publicID: string | null;
  private systemID: string | null;
  private internalSubset: string | null = null;

  constructor(elementName: string, publicID?: string | null, systemID?: string | null) {
    super();
    const nameReason = Verifier.checkXMLName(elementName);
    if (nameReason !== null) {
      throw new IllegalNameException(elementName, 'DocType', nameReason);
    }
    this.elementName = elementName;
    this.publicID = publicID === undefined ? null : publicID;
    if (this.publicID !== null) {
      const reason = Verifier.checkPublicID(this.publicID);
      if (reason !== null) {
        throw new IllegalDataException(this.publicID, 'DocType', reason);
      }
    }
    this.systemID = systemID === undefined ? null : systemID;
    if (this.systemID !== null) {
      const reason = Verifier.checkSystemLiteral(this.systemID);
      if (reason !== null) {
        throw new IllegalDataException(this.systemID, 'DocType', reason);
      }
    }
  }

  getCType(): CType {
    return CType.DocType;
  }

  getElementName(): string {
    return this.elementName;
  }

  getPublicID(): string | null {
    return this.publicID;
  }

  getSystemID(): string | null {
    return this.systemID;
  }

  getInternalSubset(): string | null {
    return this.internalSubset;
  }

  setInternalSubset(internalSubset: string | null): DocType {
    this.internalSubset = internalSubset;
    return this;
  }

  getValue(): string {
    return '';
  }

  // JDOM: "[DocType: " + new XMLOutputter().outputString(this) + "]", with the raw format's "\r\n".
  toString(): string {
    return `[DocType: ${docTypeDeclaration(this, '\r\n')}]`;
  }

  clone(): DocType {
    return new DocType(this.elementName, this.publicID, this.systemID).setInternalSubset(this.internalSubset);
  }
}

// An entity reference left unexpanded (ROME parses with setExpandEntities(false)). Its value is empty, as in JDOM.
export class EntityRef extends Content {
  private readonly name: string;

  constructor(name: string) {
    super();
    const reason = Verifier.checkXMLName(name);
    if (reason !== null) {
      throw new IllegalNameException(name, 'EntityRef', reason);
    }
    this.name = name;
  }

  getCType(): CType {
    return CType.EntityRef;
  }

  getName(): string {
    return this.name;
  }

  getValue(): string {
    return '';
  }

  clone(): EntityRef {
    return new EntityRef(this.name);
  }
}

export class Element extends Content implements Parent {
  private name: string = '';
  private namespace: Namespace = Namespace.NO_NAMESPACE;
  private additionalNamespaces: Namespace[] = [];
  private attributes: Attribute[] = [];
  private content: Content[] = [];

  constructor(name: string, namespace?: Namespace | null) {
    super();
    this.setName(name);
    this.setNamespace(namespace === undefined ? null : namespace);
  }

  getCType(): CType {
    return CType.Element;
  }

  getName(): string {
    return this.name;
  }

  setName(name: string): Element {
    const reason = Verifier.checkElementName(name);
    if (reason !== null) {
      throw new IllegalNameException(name, 'element', reason);
    }
    this.name = name;
    return this;
  }

  // No argument: this element's namespace. With a prefix: the namespace bound to it in scope, or null.
  getNamespace(prefix?: string): Namespace | null {
    if (prefix === undefined) {
      return this.namespace;
    }
    if (prefix === 'xml') {
      return Namespace.XML_NAMESPACE;
    }
    if (prefix === this.namespace.getPrefix()) {
      return this.namespace;
    }
    for (const ns of this.additionalNamespaces) {
      if (ns.getPrefix() === prefix) {
        return ns;
      }
    }
    for (const attribute of this.attributes) {
      if (attribute.getNamespacePrefix() === prefix) {
        return attribute.getNamespace();
      }
    }
    const parent = this.getParentElement();
    return parent === null ? null : parent.getNamespace(prefix);
  }

  setNamespace(namespace: Namespace | null): Element {
    const ns = namespace === null ? Namespace.NO_NAMESPACE : namespace;
    const reason = Verifier.checkDeclarationCollision(ns, this) ?? Verifier.checkAttributeCollision(ns, this);
    if (reason !== null) {
      throw new IllegalAddException(illegalAddNamespace(this, ns, reason));
    }
    this.namespace = ns;
    return this;
  }

  getNamespacePrefix(): string {
    return this.namespace.getPrefix();
  }

  getNamespaceURI(): string {
    return this.namespace.getURI();
  }

  getQualifiedName(): string {
    const prefix = this.namespace.getPrefix();
    return prefix === '' ? this.name : `${prefix}:${this.name}`;
  }

  // JDOM returns false for an already declared namespace instance; JDOM interns namespaces by prefix and URI.
  addNamespaceDeclaration(namespace: Namespace): boolean {
    for (const ns of this.additionalNamespaces) {
      if (ns.getPrefix() === namespace.getPrefix() && ns.getURI() === namespace.getURI()) {
        return false;
      }
    }
    const reason = Verifier.checkElementCollision(namespace, this);
    if (reason !== null) {
      throw new IllegalAddException(illegalAddNamespace(this, namespace, reason));
    }
    this.additionalNamespaces.push(namespace);
    return true;
  }

  removeNamespaceDeclaration(namespace: Namespace): void {
    this.additionalNamespaces = this.additionalNamespaces.filter((ns: Namespace) => ns !== namespace);
  }

  getAdditionalNamespaces(): Namespace[] {
    return this.additionalNamespaces.slice();
  }

  // Direct text and CDATA children concatenated; nested elements are ignored.
  getText(): string {
    let text = '';
    for (const child of this.content) {
      if (child instanceof Text) {
        text += child.getText();
      }
    }
    return text;
  }

  getTextTrim(): string {
    return Strings.trimToEmpty(this.getText());
  }

  setText(text: string | null): Element {
    this.removeContent();
    if (text !== null) {
      this.addContent(new Text(text));
    }
    return this;
  }

  // All descendant text, in document order (XPath string value).
  getValue(): string {
    let value = '';
    for (const child of this.content) {
      if (child instanceof Element || child instanceof Text) {
        value += child.getValue();
      }
    }
    return value;
  }

  // Without a namespace argument only children in NO_NAMESPACE match, as in JDOM.
  getChild(name: string, namespace?: Namespace | null): Element | null {
    const ns = namespace === undefined || namespace === null ? Namespace.NO_NAMESPACE : namespace;
    for (const child of this.content) {
      if (child instanceof Element && child.name === name && child.namespace.equals(ns)) {
        return child;
      }
    }
    return null;
  }

  // No arguments: all child elements. With a name: children with that name in the given namespace
  // (NO_NAMESPACE when omitted).
  getChildren(name?: string, namespace?: Namespace | null): Element[] {
    const ns = namespace === undefined || namespace === null ? Namespace.NO_NAMESPACE : namespace;
    const children: Element[] = [];
    for (const child of this.content) {
      if (child instanceof Element && (name === undefined || (child.name === name && child.namespace.equals(ns)))) {
        children.push(child);
      }
    }
    return children;
  }

  getChildText(name: string, namespace?: Namespace | null): string | null {
    const child = this.getChild(name, namespace);
    return child === null ? null : child.getText();
  }

  getChildTextTrim(name: string, namespace?: Namespace | null): string | null {
    const child = this.getChild(name, namespace);
    return child === null ? null : child.getTextTrim();
  }

  removeChild(name: string, namespace?: Namespace | null): boolean {
    const child = this.getChild(name, namespace);
    if (child === null) {
      return false;
    }
    child.detach();
    return true;
  }

  getAttributes(): Attribute[] {
    return this.attributes.slice();
  }

  hasAttributes(): boolean {
    return this.attributes.length > 0;
  }

  getAttribute(name: string, namespace?: Namespace | null): Attribute | null {
    const ns = namespace === undefined || namespace === null ? Namespace.NO_NAMESPACE : namespace;
    for (const attribute of this.attributes) {
      if (attribute.getName() === name && attribute.getNamespace().equals(ns)) {
        return attribute;
      }
    }
    return null;
  }

  getAttributeValue(name: string, namespace?: Namespace | null): string | null {
    const attribute = this.getAttribute(name, namespace);
    return attribute === null ? null : attribute.getValue();
  }

  // setAttribute(attribute) replaces a same-named attribute; setAttribute(name, value, namespace?) sets the value of an
  // existing one, keeping its prefix, as in JDOM.
  setAttribute(nameOrAttribute: string | Attribute, value?: string, namespace?: Namespace | null): Element {
    if (nameOrAttribute instanceof Attribute) {
      return this.addAttribute(nameOrAttribute);
    }
    const text = value === undefined ? '' : value;
    const existing = this.getAttribute(nameOrAttribute, namespace);
    if (existing !== null) {
      existing.setValue(text);
      return this;
    }
    return this.addAttribute(new Attribute(nameOrAttribute, text, namespace));
  }

  private addAttribute(attribute: Attribute): Element {
    if (attribute.parent !== null) {
      throw new IllegalAddException(
        `The attribute already has an existing parent "${attribute.parent.getQualifiedName()}"`);
    }
    const reason = attribute.getNamespacePrefix() === ''
      ? null
      : Verifier.checkElementCollision(attribute.getNamespace(), this);
    if (reason !== null) {
      throw new IllegalAddException(illegalAddAttribute(this, attribute, reason));
    }
    const index = this.attributes.findIndex((a: Attribute) =>
      a.getName() === attribute.getName() && a.getNamespace().equals(attribute.getNamespace()));
    attribute.parent = this;
    if (index >= 0) {
      this.attributes[index].parent = null;
      this.attributes[index] = attribute;
    } else {
      this.attributes.push(attribute);
    }
    return this;
  }

  removeAttribute(name: string, namespace?: Namespace | null): boolean {
    const attribute = this.getAttribute(name, namespace);
    if (attribute === null) {
      return false;
    }
    attribute.parent = null;
    this.attributes = this.attributes.filter((a: Attribute) => a !== attribute);
    return true;
  }

  getContent(): Content[] {
    return this.content.slice();
  }

  getContentSize(): number {
    return this.content.length;
  }

  indexOf(child: Content): number {
    return this.content.indexOf(child);
  }

  // A string is added as a Text node. A list is added whole or not at all, as in JDOM.
  addContent(child: Content | string | Content[]): Element {
    if (typeof child === 'string') {
      this.adopt(new Text(child), this.content.length);
    } else if (child instanceof Content) {
      this.adopt(child, this.content.length);
    } else {
      const start = this.content.length;
      try {
        for (const c of child) {
          this.adopt(c, this.content.length);
        }
      } catch (e) {
        for (const c of this.content.splice(start)) {
          c.parent = null;
        }
        throw e as Error;
      }
    }
    return this;
  }

  addContentAt(index: number, child: Content): Element {
    checkIndex(index, this.content.length);
    this.adopt(child, index);
    return this;
  }

  // Keeps the old content when a child cannot be added, as in JDOM.
  setContent(children: Content[]): Element {
    const old = this.removeContent();
    try {
      return this.addContent(children);
    } catch (e) {
      this.content = old;
      for (const c of old) {
        c.parent = this;
      }
      throw e as Error;
    }
  }

  isAncestor(element: Element): boolean {
    let p = element.getParent();
    while (p instanceof Element) {
      if (p === this) {
        return true;
      }
      p = p.getParent();
    }
    return false;
  }

  // No argument: removes and returns all content. With a child: removes it, returning [child] or [].
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

  detach(): Element {
    super.detach();
    return this;
  }

  clone(): Element {
    const copy = new Element(this.name, this.namespace);
    copy.additionalNamespaces = this.additionalNamespaces.slice();
    for (const attribute of this.attributes) {
      copy.setAttribute(attribute.clone());
    }
    for (const child of this.content) {
      copy.adopt(child.clone(), copy.content.length);
    }
    return copy;
  }

  private adopt(child: Content, index: number): void {
    checkPreConditions(this, child);
    if (child instanceof DocType) {
      throw new IllegalAddException('A DocType is not allowed except at the document level');
    }
    child.parent = this;
    this.content.splice(index, 0, child);
  }
}

// Thrown by the XML parser for malformed input; ParsingFeedException exposes its position. inBuilding marks errors
// Xerces raises as a plain SAXException, which JDOM reports as "Error in building" instead of "Error on line N".
export class XmlParseException extends Error {
  readonly lineNumber: number;
  readonly columnNumber: number;
  readonly inBuilding: boolean;

  constructor(message: string, lineNumber: number, columnNumber: number, inBuilding: boolean = false) {
    super(message);
    this.name = 'XmlParseException';
    this.lineNumber = lineNumber;
    this.columnNumber = columnNumber;
    this.inBuilding = inBuilding;
  }
}
