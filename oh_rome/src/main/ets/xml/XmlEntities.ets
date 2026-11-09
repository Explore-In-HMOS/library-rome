// Ported from the JDK 17 Xerces com/sun/org/apache/xerces/internal/impl/XMLDTDScannerImpl.java, XMLScanner.java and
// XMLEntityManager.java (Apache-2.0): DOCTYPE, entity declarations and entity references for XmlParser, with external
// entities and DTD loading turned off. An entity's replacement text is scanned by its own EntityScanner, so errors in
// it report its own lines.
import { DocType, XmlParseException } from './Dom';
import { PUBID_RUN } from './XmlNameChars';
import { EOF_IN_ENTITY, XmlScanner } from './XmlScanner';

const ENTITY_EXPANSION_LIMIT = 64000;
const MARKUP_NOT_WELL_FORMED = 'The markup declarations contained or pointed to by the document type declaration must be well-formed.';
const ATTR_RUN_DQ = /[^"<&\r\n\t\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\uD800-\uDFFF\uFFFE\uFFFF]*/y;
const ATTR_RUN_SQ = /[^'<&\r\n\t\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\uD800-\uDFFF\uFFFE\uFFFF]*/y;
const ATTR_RUN_ENTITY = /[^<&\r\n\t\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F\uD800-\uDFFF\uFFFE\uFFFF]*/y;

export class EntityDecl {
  value: string | null = null;
  external: boolean = false;
  unparsed: boolean = false;
}

export class Entities {
  readonly general: Map<string, EntityDecl> = new Map<string, EntityDecl>();
  readonly parameter: Map<string, EntityDecl> = new Map<string, EntityDecl>();
  hasExternalSubset: boolean = false;
  expansions: number = 0;
}

export class EntityScanner extends XmlScanner {
  protected readonly entities: Entities;
  // Names of the entities being expanded, outermost first; parameter entities as "%name".
  private readonly open: string[];
  private parameterEntity: string | null = null;
  private declaring: boolean = false;

  constructor(s: string, xml11: boolean, entities: Entities, open: string[]) {
    super(s, xml11);
    this.entities = entities;
    this.open = open;
  }

  protected docType(): DocType {
    this.i += 9;
    if (!this.skipSpaces()) {
      this.fail('White space is required after "<!DOCTYPE" in the document type declaration.');
    }
    const name = this.name(true);
    if (name === '') {
      this.fail('The root element type must appear after "<!DOCTYPE" in the document type declaration.');
    }
    this.skipSpaces();
    let publicId: string | null = null;
    let systemId: string | null = null;
    if (this.startsWith('PUBLIC')) {
      this.i += 6;
      if (!this.skipSpaces()) {
        this.fail('White spaces are required after keyword PUBLIC in DOCTYPE decl.');
      }
      publicId = this.publicLiteral();
      if (!this.skipSpaces()) {
        this.fail('White spaces are required between publicId and systemId.');
      }
    }
    if (publicId !== null || this.startsWith('SYSTEM')) {
      if (publicId === null) {
        this.i += 6;
        if (!this.skipSpaces()) {
          this.fail('White space is required after keyword SYSTEM in DOCTYPE decl.');
        }
      }
      systemId = this.systemLiteral();
    }
    this.skipSpaces();
    const docType = new DocType(name, publicId, systemId);
    if (this.code(this.i) === 91) {
      this.i++;
      const start = this.i;
      this.internalSubset(true);
      docType.setInternalSubset(this.s.substring(start, this.i - 1));
      this.skipSpaces();
      if (this.i >= this.n) {
        throw new XmlParseException('Premature end of file.', -1, -1);
      }
    }
    if (this.i >= this.n) {
      this.fail(EOF_IN_ENTITY);
    }
    this.expect(62, `The document type declaration for root element type "${name}" must end with '>'.`);
    this.entities.hasExternalSubset = systemId !== null;
    return docType;
  }

  // Whitespace runs become one space and leading or trailing whitespace is dropped.
  private publicLiteral(): string {
    const quote = this.code(this.i);
    if (quote !== 34 && quote !== 39) {
      this.fail('The public identifier must begin with either a single or double quote character.');
    }
    this.i++;
    const start = this.i;
    const found = this.s.indexOf(String.fromCharCode(quote), start);
    const end = found < 0 ? this.n : found;
    this.skip(PUBID_RUN);
    if (this.i < end) {
      this.fail(`An invalid XML character (Unicode: 0x${this.code(this.i).toString(16)}) was found in the public identifier.`);
    }
    if (found < 0) {
      this.i = this.n;
      this.fail(EOF_IN_ENTITY);
    }
    this.i = end + 1;
    return this.s.substring(start, end).replace(/[ \r\n]+/g, ' ').trim();
  }

  private systemLiteral(): string {
    const quote = this.code(this.i);
    if (quote !== 34 && quote !== 39) {
      this.fail('The system identifier must begin with either a single or double quote character.');
    }
    this.i++;
    const end = this.checked(String.fromCharCode(quote), 'the system identifier');
    const literal = this.normalized(this.i, end);
    this.i = end + 1;
    return literal;
  }

  // Declarations up to and including the closing ']', or up to the end of a parameter entity's text.
  // Only ENTITY declarations are kept.
  private internalSubset(closed: boolean): void {
    while (true) {
      this.skipSpaces();
      if (this.i >= this.n) {
        if (!closed) {
          return;
        }
        throw new XmlParseException('Premature end of file.', -1, -1);
      }
      if (closed && this.code(this.i) === 93) {
        this.i++;
        return;
      }
      this.declaring = true;
      if (this.startsWith('<!--')) {
        this.comment();
      } else if (this.startsWith('<?')) {
        this.processingInstruction();
      } else if (this.startsWith('<!ENTITY')) {
        this.entityDeclaration();
      } else if (this.startsWith('<!ELEMENT') || this.startsWith('<!ATTLIST') || this.startsWith('<!NOTATION')) {
        this.skipDeclaration();
      } else if (this.code(this.i) === 37) {
        this.declaring = false;
        this.parameterReference();
      } else {
        this.fail(MARKUP_NOT_WELL_FORMED);
      }
      this.declaring = false;
    }
  }

  private skipDeclaration(): void {
    while (this.i < this.n && this.code(this.i) !== 62) {
      const c = this.code(this.i);
      if (c === 34 || c === 39) {
        this.quoted();
      } else {
        this.i++;
      }
    }
    this.i++;
  }

  private parameterReference(): void {
    this.i++;
    const name = this.name(true);
    if (name === '') {
      this.fail('The entity name must immediately follow the \'%\' in the parameter entity reference.');
    }
    if (this.code(this.i) !== 59) {
      this.fail(`The parameter entity reference "%${name};" must end with the ';' delimiter.`);
    }
    this.i++;
    const decl = this.entities.parameter.get(name);
    if (decl === undefined || decl.external) {
      return;
    }
    const scanner = this.enter(`%${name}`, decl.value!);
    scanner.parameterEntity = name;
    scanner.internalSubset(false);
  }

  private entityDeclaration(): void {
    this.i += 8;
    this.skipSpaces();
    const parameter = this.code(this.i) === 37;
    if (parameter) {
      this.i++;
      this.skipSpaces();
    }
    const name = this.name(true);
    this.skipSpaces();
    const decl = new EntityDecl();
    const c = this.code(this.i);
    if (c === 34 || c === 39) {
      decl.value = this.entityValue();
    } else {
      decl.external = true;
      const start = this.i;
      this.skipDeclaration();
      this.i--;
      decl.unparsed = /\sNDATA\s/.test(this.s.substring(start - 1, this.i));
    }
    this.skipSpaces();
    this.expect(62, `The declaration for the entity "${name}" must end with '>'.`);
    const table = parameter ? this.entities.parameter : this.entities.general;
    if (!table.has(name)) {
      table.set(name, decl);
    }
  }

  // Xerces' scanEntityValue: character references are replaced, entity references are checked and kept,
  // parameter entity references are not allowed in the internal subset.
  private entityValue(): string {
    const quote = this.code(this.i);
    this.i++;
    let value = '';
    while (true) {
      const c = this.code(this.i);
      if (c === quote) {
        this.i++;
        return value;
      }
      if (c < 0) {
        this.fail(EOF_IN_ENTITY);
      }
      if (c === 38 && this.code(this.i + 1) === 35) {
        value += this.charReference();
      } else if (c === 38) {
        value += `&${this.referenceName()};`;
      } else if (c === 37) {
        this.i++;
        const name = this.name(true);
        if (name === '') {
          this.fail('The entity name must immediately follow the \'%\' in the parameter entity reference.');
        }
        this.fail(this.code(this.i) === 59
          ? `The parameter entity reference "%${name};" cannot occur within markup in the internal subset of the DTD.`
          : `The parameter entity reference "%${name};" must end with the ';' delimiter.`);
      } else {
        const length = c >= 0xd800 && c <= 0xdfff ? this.validChar(this.i, '') : this.charLength(this.i);
        if (length === 0) {
          this.fail('InvalidCharInLiteral');
        }
        value += this.s.substring(this.i, this.i + length);
        this.i += length;
      }
    }
  }

  // A quoted attribute value, or with quote -1 an entity's whole replacement text inside one.
  protected attributeChars(quote: number, attribute: string, element: string): string {
    const run = quote === 34 ? ATTR_RUN_DQ : quote === 39 ? ATTR_RUN_SQ : ATTR_RUN_ENTITY;
    let value = '';
    while (true) {
      const start = this.i;
      this.skip(run);
      value += this.s.substring(start, this.i);
      if (this.i >= this.n) {
        if (quote < 0) {
          return value;
        }
        this.fail(EOF_IN_ENTITY);
      }
      const c = this.code(this.i);
      if (c === quote) {
        this.i++;
        return value;
      }
      if (c === 60) {
        this.fail(`The value of attribute "${attribute}" associated with an element type "${element}" must not contain the '<' character.`);
      } else if (c === 38) {
        value += this.attributeReference(attribute, element);
      } else if (c === 13 || c === 10 || c === 9) {
        value += ' ';
        this.i += c === 13 && this.code(this.i + 1) === 10 ? 2 : 1;
      } else {
        const length = this.validChar(this.i, `the value of attribute "${attribute}" and element is "${element}"`);
        value += this.s.substring(this.i, this.i + length);
        this.i += length;
      }
    }
  }

  private attributeReference(attribute: string, element: string): string {
    if (this.code(this.i + 1) === 35) {
      return this.charReference();
    }
    const name = this.referenceName();
    const predefined = this.predefined(name);
    if (predefined !== null) {
      return predefined;
    }
    const decl = this.entities.general.get(name);
    if (decl === undefined) {
      if (this.entities.hasExternalSubset) {
        return '';
      }
      this.fail(`The entity "${name}" was referenced, but not declared.`);
    }
    if (decl.external) {
      this.fail(`The external entity reference "&${name};" is not permitted in an attribute value.`);
    }
    return this.enter(name, decl.value!).attributeChars(-1, attribute, element);
  }

  // Xerces scans an internal entity's replacement text wherever it is referenced in content, so its references are
  // checked, recursion and the expansion limit apply, and only the EntityRef reaches JDOM.
  protected checkContentEntity(name: string, value: string): void {
    const scanner = this.enter(name, value);
    while (true) {
      const amp = scanner.s.indexOf('&', scanner.i);
      if (amp < 0) {
        return;
      }
      scanner.i = amp;
      if (scanner.code(amp + 1) === 35) {
        scanner.charReference();
        continue;
      }
      scanner.i++;
      const ref = scanner.name(true);
      if (scanner.i >= scanner.n) {
        scanner.fail(EOF_IN_ENTITY);
      }
      if (ref === '') {
        scanner.fail('The entity name must immediately follow the \'&\' in the entity reference.');
      }
      if (scanner.code(scanner.i) !== 59) {
        scanner.fail(`The reference to entity "${ref}" must end with the ';' delimiter.`);
      }
      scanner.i++;
      const decl = this.entities.general.get(ref);
      if (scanner.predefined(ref) !== null || decl !== undefined && decl.external) {
        continue;
      }
      if (decl === undefined) {
        if (!this.entities.hasExternalSubset) {
          scanner.fail(`The entity "${ref}" was referenced, but not declared.`);
        }
        continue;
      }
      scanner.checkContentEntity(ref, decl.value!);
    }
  }

  private enter(name: string, value: string): EntityScanner {
    const at = this.open.indexOf(name);
    if (at >= 0) {
      const path = at === this.open.length - 1 ? [name, name] : this.open.slice(at);
      this.fail(`Recursive entity reference "${name}". (Reference path: ${path.join(' -> ')} -> ${name}),`);
    }
    this.entities.expansions++;
    if (this.entities.expansions > ENTITY_EXPANSION_LIMIT) {
      this.fail(`JAXP00010001: The parser has encountered more than "${ENTITY_EXPANSION_LIMIT}" entity expansions in this document; this is the limit imposed by the JDK.`);
    }
    return new EntityScanner(value, this.xml11, this.entities, this.open.concat([name]));
  }

  // Xerces reports a declaration cut off by the end of the input as a premature end of file, and one cut off by the
  // end of a parameter entity's text as improper nesting.
  protected fail(message: string): never {
    if (this.declaring && this.i >= this.n) {
      return super.fail(this.parameterEntity === null ? 'Premature end of file.'
        : `The replacement text of parameter entity "%${this.parameterEntity}" must include properly nested declarations when the entity reference is used as a complete declaration.`);
    }
    return super.fail(message);
  }
}
