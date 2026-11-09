// Ported from ROME rome/src/main/java/com/rometools/rome/io/WireFeedInput.java (createSAXBuilder) and SAXBuilder.java (Apache-2.0)
// Replaces JDOM's SAXBuilder on the JDK's Xerces, configured as ROME configures it: non-validating, namespace
// aware, no external entities or DTD loading, setExpandEntities(false), DOCTYPE disallowed unless allowed.
// Trees and error messages match that setup; tools/xml-oracle produces the expected values for the tests.
// The document scanning follows the JDK 17 Xerces XMLDocumentScannerImpl.java, XMLDocumentFragmentScannerImpl.java and
// XMLNSDocumentScannerImpl.java (Apache-2.0).
import {
  Attribute, CDATA, Comment, Document, Element, EntityRef, Namespace, ProcessingInstruction, Text, XmlParseException
} from './Dom';
import { Entities, EntityScanner } from './XmlEntities';
import { EOF_IN_ENTITY, grouped } from './XmlScanner';

const XML_NS_URI = 'http://www.w3.org/XML/1998/namespace';
const XMLNS_URI = 'http://www.w3.org/2000/xmlns/';
const PSEUDO_ATTRIBUTES = ['version', 'encoding', 'standalone'];
const SPACE_BEFORE_ENCODING = 'White space is required before the encoding pseudo attribute in the XML declaration.';
const MAX_ATTRIBUTES = 10000;
// Sticky runs of characters that need no individual handling; the hot loops jump over them natively.
const TEXT_RUN = /[^<&\r\]\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\uD800-\uDFFF\uFFFE\uFFFF]*/y;

class RawAttribute {
  qname: string = '';
  value: string = '';
}

class OpenElement {
  readonly element: Element;
  readonly qname: string;
  readonly prefixes: string[];
  readonly empty: boolean;

  constructor(element: Element, qname: string, prefixes: string[], empty: boolean) {
    this.element = element;
    this.qname = qname;
    this.prefixes = prefixes;
    this.empty = empty;
  }
}

export function parseXml(xml: string, allowDoctypes?: boolean): Document {
  return new XmlParser(xml, allowDoctypes === true).parse();
}

class XmlParser extends EntityScanner {
  private readonly allowDoctypes: boolean;
  private readonly doc: Document = new Document();
  private seenDocType: boolean = false;
  // Text buffering mirrors JDOM's SAXHandler (flushCharacters/startCDATA/endCDATA), including its quirks.
  private buffer: string = '';
  private inCDATA: boolean = false;
  private previousCDATA: boolean = false;
  private readonly stack: OpenElement[] = [];
  private readonly namespaces: Map<string, Namespace> = new Map<string, Namespace>();
  // Prefix to the URIs it is bound to, innermost last.
  private readonly bindings: Map<string, string[]> = new Map<string, string[]>();

  constructor(xml: string, allowDoctypes: boolean) {
    super(xml, false, new Entities(), []);
    this.allowDoctypes = allowDoctypes;
  }

  parse(): Document {
    this.xmlDeclaration();
    this.misc(true);
    if (this.i >= this.n) {
      this.fail('Premature end of file.');
    }
    this.bindings.set('', ['']);
    this.bindings.set('xml', [XML_NS_URI]);
    this.doc.setRootElement(this.element());
    this.misc(false);
    return this.doc;
  }

  // Xerces' scanXMLDeclOrTextDecl. XML 1.1 line ends (NEL, U+2028, CR NEL) are normalized up front.
  private xmlDeclaration(): void {
    if (!this.s.startsWith('<?xml', 0) || !this.isSpace(this.code(5))) {
      return;
    }
    this.i = 5;
    let sawSpace = this.skipSpaces();
    this.uncountedLines = this.s.substring(5, this.i).replace(/\r\n/g, '\n').replace(/[^\r\n]/g, '').length;
    let state = 0;
    let version: string | null = null;
    while (this.code(this.i) !== 63) {
      if (this.i >= this.n) {
        this.fail(EOF_IN_ENTITY);
      }
      const name = this.pseudoAttributeName();
      this.skipSpaces();
      this.expect(61, `The ' = ' character must follow "${name}" in the XML declaration.`);
      this.skipSpaces();
      const quote = this.code(this.i);
      if (quote !== 34 && quote !== 39) {
        this.fail(`The value following "${name}" in the XML declaration must be a quoted string.`);
      }
      this.i++;
      const end = this.checked(String.fromCharCode(quote), 'the XML declaration');
      const value = this.s.substring(this.i, end);
      this.i = end + 1;
      if (state === 0) {
        if (name !== 'version') {
          this.fail('The version is required in the XML declaration.');
        }
        if (value !== '1.0' && value !== '1.1') {
          this.fail(`XML version "${value}" is not supported, only XML 1.0 is supported.`);
        }
        version = value;
        state = 1;
      } else if (state === 1 && name === 'encoding' || state < 3 && name === 'standalone') {
        if (!sawSpace) {
          this.fail(SPACE_BEFORE_ENCODING);
        }
        if (name === 'standalone' && value !== 'yes' && value !== 'no') {
          this.fail(`The standalone document declaration value must be "yes" or "no", not "${value}".`);
        }
        state = name === 'encoding' ? 2 : 3;
      } else {
        this.fail(state === 1 ? 'The encoding declaration is required in the text declaration.'
          : state === 2 ? 'The standalone name in XML declaration may be misspelled.' : 'No more pseudo attributes are allowed.');
      }
      sawSpace = this.skipSpaces();
    }
    if (version === null) {
      this.fail('The version is required in the XML declaration.');
    }
    this.i++;
    this.expect(62, 'The XML declaration must end with "?>".');
    if (version === '1.1') {
      this.xml11 = true;
      this.s = this.s.substring(0, this.i) + this.s.substring(this.i).replace(/\r[\n\u0085]?|[\u0085\u2028]/g, '\n');
      this.n = this.s.length;
    }
  }

  private pseudoAttributeName(): string {
    for (const name of PSEUDO_ATTRIBUTES) {
      if (this.startsWith(name)) {
        this.i += name.length;
        return name;
      }
    }
    return this.fail('A pseudo attribute name is expected.');
  }

  private misc(prolog: boolean): void {
    while (this.i < this.n) {
      const c = this.code(this.i);
      if (this.isSpace(c)) {
        this.i++;
      } else if (c === 60) {
        if (prolog || this.i + 1 === this.n) {
          this.eofInMarkup();
        }
        if (this.startsWith('<?')) {
          this.doc.addContent(this.processingInstructionNode());
        } else if (this.startsWith('<!--')) {
          const comment = this.comment();
          if (comment.length > 0) {
            this.doc.addContent(new Comment(comment));
          }
        } else if (prolog && this.startsWith('<!DOCTYPE')) {
          if (!this.allowDoctypes) {
            this.fail('DOCTYPE is disallowed when the feature "http://apache.org/xml/features/disallow-doctype-decl" set to true.');
          }
          if (this.seenDocType) {
            this.fail('Already seen doctype.');
          }
          this.seenDocType = true;
          this.doc.addContent(this.docType());
        } else if (prolog && this.isNameStart(this.i + 1)) {
          return;
        } else if (!prolog && this.startsWith('<!')) {
          this.fail('Comment must start with "<!--".');
        } else {
          this.fail(`The markup in the document ${prolog ? 'preceding' : 'following'} the root element must be well-formed.`);
        }
      } else if (c === 38 && prolog) {
        this.fail('Reference is not allowed in prolog.');
      } else {
        this.fail(`Content is not allowed in ${prolog ? 'prolog' : 'trailing section'}.`);
      }
    }
  }

  // Parses an element and its content without recursion, so deep documents cannot overflow the stack.
  private element(): Element {
    const root = this.startTag();
    if (root.empty) {
      return root.element;
    }
    const stack = this.stack;
    stack.push(root);
    while (stack.length > 0) {
      const top = stack[stack.length - 1];
      if (this.i >= this.n) {
        this.fail(EOF_IN_ENTITY);
      }
      const c = this.code(this.i);
      if (c === 60) {
        this.eofInMarkup();
        const next = this.code(this.i + 1);
        if (next === 47) {
          this.flush(false);
          this.endTag(top);
          this.unbind(stack.pop()!);
        } else if (next === 33 && this.startsWith('<!--')) {
          this.flush(false);
          const comment = this.comment();
          // JDOM drops empty comments.
          if (comment.length > 0) {
            top.element.addContent(new Comment(comment));
          }
        } else if (next === 33 && this.startsWith('<!DOCTYPE')) {
          throw new XmlParseException('Scanner State 24 not Recognized ', -1, -1, true);
        } else if (next === 33 && this.startsWith('<![CDATA[')) {
          this.cdata();
        } else if (next === 63) {
          this.flush(false);
          top.element.addContent(this.processingInstructionNode());
        } else if (this.isNameStart(this.i + 1)) {
          this.flush(false);
          const child = this.startTag();
          top.element.addContent(child.element);
          if (child.empty) {
            this.unbind(child);
          } else {
            stack.push(child);
          }
        } else {
          this.fail('The content of elements must consist of well-formed character data or markup.');
        }
      } else if (c === 38) {
        this.contentReference(top.element);
      } else {
        this.characters(this.text());
      }
    }
    return root.element;
  }

  // Xerces reaches the end of the input before deciding what "<", "<!" or "<!-" starts.
  private eofInMarkup(): void {
    if (this.n - this.i < 4 && '<!--'.startsWith(this.s.substring(this.i))) {
      this.fail(EOF_IN_ENTITY);
    }
  }

  private startTag(): OpenElement {
    this.i++;
    const qname = this.qname();
    const raw: RawAttribute[] = [];
    const names = new Set<string>();
    while (true) {
      const hadSpace = this.skipSpaces();
      if (this.i >= this.n) {
        this.fail(EOF_IN_ENTITY);
      }
      const c = this.code(this.i);
      if (c === 62 || (c === 47 && this.code(this.i + 1) === 62)) {
        break;
      }
      if (!hadSpace || !this.isNameStart(this.i)) {
        this.fail(`Element type "${qname}" must be followed by either attribute specifications, ">" or "/>".`);
      }
      const attribute = new RawAttribute();
      attribute.qname = this.qname();
      if (names.has(attribute.qname)) {
        this.fail(`Attribute "${attribute.qname}" was already specified for element "${qname}".`);
      }
      names.add(attribute.qname);
      this.skipSpaces();
      this.expect(61, `Attribute name "${attribute.qname}" associated with an element type "${qname}" must be followed by the ' = ' character.`);
      this.skipSpaces();
      const quote = this.code(this.i);
      if (quote !== 34 && quote !== 39) {
        this.fail(`Open quote is expected for attribute "${attribute.qname}" associated with an  element type  "${qname}".`);
      }
      this.i++;
      attribute.value = this.attributeChars(quote, attribute.qname, qname);
      raw.push(attribute);
      if (raw.length > MAX_ATTRIBUTES) {
        this.fail(`JAXP00010002:  Element "${qname}" has more than "${grouped(MAX_ATTRIBUTES)}" attributes, "${grouped(MAX_ATTRIBUTES)}" is the limit imposed by the JDK.`);
      }
    }
    const empty = this.code(this.i) === 47;
    this.i += empty ? 2 : 1;
    return this.buildElement(qname, raw, empty);
  }

  // Namespace checks of XMLNSDocumentScannerImpl, then the tree JDOM's SAXHandler builds from the SAX events.
  private buildElement(qname: string, raw: RawAttribute[], empty: boolean): OpenElement {
    const prefixes: string[] = [];
    const declared: Namespace[] = [];
    for (const a of raw) {
      if (a.qname !== 'xmlns' && !a.qname.startsWith('xmlns:')) {
        continue;
      }
      const prefix = a.qname === 'xmlns' ? '' : a.qname.substring(6);
      if (prefix === 'xmlns' || a.value === XMLNS_URI) {
        this.fail('The prefix "xmlns" cannot be bound to any namespace explicitly; neither can the namespace for "xmlns" be bound to any prefix explicitly.');
      }
      if ((prefix === 'xml') !== (a.value === XML_NS_URI)) {
        this.fail('The prefix "xml" cannot be bound to any namespace other than its usual namespace; neither can the namespace for "xml" be bound to any prefix other than "xml".');
      }
      if (prefix !== '' && a.value === '' && !this.xml11) {
        this.fail(`The value of the attribute "prefix="xmlns",localpart="${prefix}",rawname="${a.qname}"" is invalid. Prefixed namespace bindings may not be empty.`);
      }
      // xml is bound already, so Xerces reports no prefix mapping for it.
      if (prefix === 'xml') {
        continue;
      }
      const uris = this.bindings.get(prefix);
      if (uris === undefined) {
        this.bindings.set(prefix, [a.value]);
      } else {
        uris.push(a.value);
      }
      prefixes.push(prefix);
      declared.push(this.namespace(prefix, a.value));
    }
    const colon = qname.indexOf(':', 1);
    const prefix = colon < 0 ? '' : qname.substring(0, colon);
    if (prefix === 'xmlns') {
      this.fail(`Element "${qname}" cannot have "xmlns" as its prefix.`);
    }
    const uri = this.lookup(prefix);
    if (uri === undefined) {
      this.fail(`The prefix "${prefix}" for element "${qname}" is not bound.`);
    }
    const namespace = this.namespace(prefix, uri);
    const element = new Element(colon < 0 ? qname : qname.substring(colon + 1), namespace);
    for (const ns of declared) {
      if (ns.getPrefix() !== namespace.getPrefix() || ns.getURI() !== namespace.getURI()) {
        element.addNamespaceDeclaration(ns);
      }
    }
    const expanded = new Set<string>();
    for (const a of raw) {
      if (a.qname === 'xmlns' || a.qname.startsWith('xmlns:')) {
        continue;
      }
      const ac = a.qname.indexOf(':', 1);
      const ap = ac < 0 ? '' : a.qname.substring(0, ac);
      const auri = ap === '' ? '' : this.lookup(ap);
      if (auri === undefined) {
        this.fail(`The prefix "${ap}" for attribute "${a.qname}" associated with an element type "${qname}" is not bound.`);
      }
      const local = ac < 0 ? a.qname : a.qname.substring(ac + 1);
      if (ap !== '') {
        const key = `${auri} ${local}`;
        if (expanded.has(key)) {
          this.fail(`Attribute "${local}" bound to namespace "${auri}" was already specified for element "${qname}".`);
        }
        expanded.add(key);
      }
      // JDOM's SAXHandler skips attributes named like a namespace declaration.
      if (local !== 'xmlns') {
        element.setAttribute(new Attribute(local, a.value, this.namespace(ap, auri)));
      }
    }
    return new OpenElement(element, qname, prefixes, empty);
  }

  private lookup(prefix: string): string | undefined {
    const uris = this.bindings.get(prefix);
    return uris === undefined || uris.length === 0 ? undefined : uris[uris.length - 1];
  }

  private unbind(open: OpenElement): void {
    for (const prefix of open.prefixes) {
      this.bindings.get(prefix)!.pop();
    }
  }

  private namespace(prefix: string, uri: string): Namespace {
    const key = `${prefix} ${uri}`;
    let ns = this.namespaces.get(key);
    if (ns === undefined) {
      ns = Namespace.getNamespace(prefix, uri);
      this.namespaces.set(key, ns);
    }
    return ns;
  }

  private endTag(open: OpenElement): void {
    this.i += 2;
    if (!this.startsWith(open.qname)) {
      this.fail(`The element type "${open.qname}" must be terminated by the matching end-tag "</${open.qname}>".`);
    }
    this.i += open.qname.length;
    this.skipSpaces();
    if (this.i >= this.n) {
      this.fail(EOF_IN_ENTITY);
    }
    this.expect(62, `The end-tag for element type "${open.qname}" must end with a '>' delimiter.`);
  }

  private text(): string {
    let text = '';
    while (true) {
      const start = this.i;
      this.skip(TEXT_RUN);
      text += this.s.substring(start, this.i);
      const c = this.code(this.i);
      if (c === 60 || c === 38 || c < 0) {
        return text;
      }
      if (c === 13) {
        text += '\n';
        this.i += this.code(this.i + 1) === 10 ? 2 : 1;
      } else if (c === 93) {
        if (this.startsWith(']]>')) {
          this.fail('The character sequence "]]>" must not appear in content unless used to mark the end of a CDATA section.');
        }
        text += ']';
        this.i++;
      } else {
        const length = this.validChar(this.i, 'the element content of the document');
        text += this.s.substring(this.i, this.i + length);
        this.i += length;
      }
    }
  }

  private contentReference(parent: Element): void {
    if (this.code(this.i + 1) === 35) {
      this.characters(this.charReference());
      return;
    }
    const name = this.referenceName();
    const predefined = this.predefined(name);
    if (predefined !== null) {
      this.characters(predefined);
      return;
    }
    const decl = this.entities.general.get(name);
    if (decl === undefined && !this.entities.hasExternalSubset) {
      this.fail(`The entity "${name}" was referenced, but not declared.`);
    }
    if (decl !== undefined && decl.unparsed) {
      this.fail(`The unparsed entity reference "&${name};" is not permitted.`);
    }
    this.flush(false);
    parent.addContent(new EntityRef(name));
    if (decl !== undefined && !decl.external) {
      const value = decl.value!;
      this.checkContentEntity(name, value);
      // Xerces delivers the text of a single-line, markup-free internal entity after JDOM's EntityRef, so it stays.
      if (/^[^<&\n\r]*$/.test(value)) {
        this.characters(value);
      }
    }
  }

  private cdata(): void {
    this.i += 9;
    this.inCDATA = true;
    const end = this.checked(']]>', 'the CDATA section');
    this.characters(this.normalized(this.i, end));
    this.i = end + 3;
    this.previousCDATA = true;
    this.flush(true);
    this.previousCDATA = false;
    this.inCDATA = false;
  }

  private processingInstructionNode(): ProcessingInstruction {
    const pi = this.processingInstruction();
    return new ProcessingInstruction(pi[0], pi[1]);
  }

  private characters(text: string): void {
    if (text.length === 0) {
      return;
    }
    if (this.previousCDATA !== this.inCDATA) {
      this.flush(false);
    }
    this.buffer += text;
  }

  // endCDATA flushes even an empty buffer, as a CDATA node; every other flush skips an empty buffer.
  private flush(force: boolean): void {
    if (this.buffer.length === 0 && !force) {
      this.previousCDATA = this.inCDATA;
      return;
    }
    const data = this.buffer;
    this.buffer = '';
    const parent = this.stack[this.stack.length - 1].element;
    parent.addContent(this.previousCDATA ? new CDATA(data) : new Text(data));
    this.previousCDATA = this.inCDATA;
  }
}
