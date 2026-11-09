// Behavior of JDOM 2.0.6.1 org.jdom2.Verifier and its Illegal*Exception classes (JDOM license, see LICENSE-JDOM)
import { IllegalArgumentException } from '../utils/Exceptions';
import { Attribute, Element, Namespace } from './Dom';

// Character roles per UTF-16 code unit, run-length encoded: VALCONST[i] applies to the next LENCONST[i] chars.
const VALCONST: number[] = [
  0x00, 0x01, 0x00, 0x01, 0x00, 0x01, 0x41, 0x01, 0x41, 0x49, 0x41, 0x59, 0x41, 0x01, 0x41, 0x01, 0x41, 0x4f, 0x01,
  0x4d, 0x01, 0x4f, 0x01, 0x41, 0x01, 0x09, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x09, 0x01, 0x29, 0x01, 0x29, 0x01,
  0x0f, 0x09, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01,
  0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29,
  0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x09, 0x0f, 0x29, 0x01, 0x19, 0x01, 0x29, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x29, 0x0f, 0x29, 0x01, 0x29, 0x01, 0x19, 0x01, 0x29, 0x01, 0x0f,
  0x01, 0x29, 0x0f, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x29, 0x01, 0x19, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01,
  0x0f, 0x29, 0x01, 0x19, 0x0f, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x19, 0x29, 0x0f, 0x01,
  0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x0f, 0x29,
  0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x19, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01,
  0x0f, 0x01, 0x0f, 0x01, 0x29, 0x0f, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x19,
  0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01,
  0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x19, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x19, 0x01,
  0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x19, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01,
  0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x19, 0x01, 0x0f, 0x01, 0x0f, 0x29, 0x0f, 0x29, 0x01, 0x0f, 0x09,
  0x29, 0x01, 0x19, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x29, 0x0f, 0x29, 0x01, 0x29, 0x0f, 0x01, 0x0f, 0x01,
  0x09, 0x01, 0x29, 0x01, 0x19, 0x01, 0x29, 0x01, 0x19, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x0f, 0x01,
  0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01,
  0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01,
  0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01,
  0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x29, 0x01, 0x0f, 0x01, 0x0f,
  0x01, 0x0f, 0x01, 0x0f, 0x01, 0x09, 0x01, 0x0f, 0x01, 0x0f, 0x29, 0x01, 0x09, 0x01, 0x0f, 0x01, 0x29, 0x01, 0x09,
  0x01, 0x0f, 0x01, 0x09, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x0f, 0x01, 0x00, 0x01, 0x00
];

const LENCONST: number[] = [
  9, 2, 2, 1, 18, 1, 1, 2, 9, 2, 1, 10, 1, 2, 1, 1, 2, 26, 4, 1, 1, 26, 3, 1, 56, 1, 8, 23, 1, 31, 1, 58, 2, 11, 2,
  8, 1, 53, 1, 68, 9, 36, 3, 2, 4, 30, 56, 89, 18, 7, 14, 2, 46, 70, 26, 2, 36, 1, 1, 3, 1, 1, 1, 20, 1, 44, 1, 7, 3,
  1, 1, 1, 1, 1, 1, 1, 1, 18, 13, 12, 1, 66, 1, 12, 1, 36, 1, 4, 9, 53, 2, 2, 2, 2, 3, 28, 2, 8, 2, 2, 55, 38, 2, 1,
  7, 38, 10, 17, 1, 23, 1, 3, 1, 1, 1, 2, 1, 1, 11, 27, 5, 3, 46, 26, 5, 1, 10, 8, 13, 10, 6, 1, 71, 2, 5, 1, 15, 1,
  4, 1, 1, 15, 2, 2, 1, 4, 2, 10, 519, 3, 1, 53, 2, 1, 1, 16, 3, 4, 3, 10, 2, 2, 10, 17, 3, 1, 8, 2, 2, 2, 22, 1, 7,
  1, 1, 3, 4, 2, 1, 1, 7, 2, 2, 2, 3, 9, 1, 4, 2, 1, 3, 2, 2, 10, 2, 16, 1, 2, 6, 4, 2, 2, 22, 1, 7, 1, 2, 1, 2, 1,
  2, 2, 1, 1, 5, 4, 2, 2, 3, 11, 4, 1, 1, 7, 10, 2, 3, 12, 3, 1, 7, 1, 1, 1, 3, 1, 22, 1, 7, 1, 2, 1, 5, 2, 1, 1, 8,
  1, 3, 1, 3, 18, 1, 5, 10, 17, 3, 1, 8, 2, 2, 2, 22, 1, 7, 1, 2, 2, 4, 2, 1, 1, 6, 3, 2, 2, 3, 8, 2, 4, 2, 1, 3, 4,
  10, 18, 2, 1, 6, 3, 3, 1, 4, 3, 2, 1, 1, 1, 2, 3, 2, 3, 3, 3, 8, 1, 3, 4, 5, 3, 3, 1, 4, 9, 1, 15, 9, 17, 3, 1, 8,
  1, 3, 1, 23, 1, 10, 1, 5, 4, 7, 1, 3, 1, 4, 7, 2, 9, 2, 4, 10, 18, 2, 1, 8, 1, 3, 1, 23, 1, 10, 1, 5, 4, 7, 1, 3,
  1, 4, 7, 2, 7, 1, 1, 2, 4, 10, 18, 2, 1, 8, 1, 3, 1, 23, 1, 16, 4, 6, 2, 3, 1, 4, 9, 1, 8, 2, 4, 10, 145, 46, 1, 1,
  1, 2, 7, 5, 6, 1, 8, 1, 10, 39, 2, 1, 1, 2, 2, 1, 1, 2, 1, 6, 4, 1, 7, 1, 3, 1, 1, 1, 1, 2, 2, 1, 2, 1, 1, 1, 2, 6,
  1, 2, 1, 2, 5, 1, 1, 1, 6, 2, 10, 62, 2, 6, 10, 11, 1, 1, 1, 1, 1, 4, 2, 8, 1, 33, 7, 20, 1, 6, 4, 6, 1, 1, 1, 21,
  3, 7, 1, 1, 230, 38, 10, 39, 9, 1, 1, 2, 1, 3, 1, 1, 1, 2, 1, 5, 41, 1, 1, 1, 1, 1, 11, 1, 1, 1, 1, 1, 3, 2, 3, 1,
  5, 3, 1, 1, 1, 1, 1, 1, 1, 1, 3, 2, 3, 2, 1, 1, 40, 1, 9, 1, 2, 1, 2, 2, 7, 2, 1, 1, 1, 7, 40, 1, 4, 1, 8, 1, 3078,
  156, 4, 90, 6, 22, 2, 6, 2, 38, 2, 6, 2, 8, 1, 1, 1, 1, 1, 1, 1, 31, 2, 53, 1, 7, 1, 1, 3, 3, 1, 7, 3, 4, 2, 6, 4,
  13, 5, 3, 1, 7, 211, 13, 4, 1, 68, 1, 3, 2, 2, 1, 81, 3, 3714, 1, 1, 1, 25, 9, 6, 1, 5, 11, 84, 4, 2, 2, 2, 2, 90,
  1, 3, 6, 40, 7379, 20902, 3162, 11172, 92, 2048, 8190, 2
];

const MASKXMLSTARTCHAR: number = 1 << 2;
const MASKXMLNAMECHAR: number = 1 << 3;

const CHARFLAGS: Uint8Array = buildBitFlags();

function buildBitFlags(): Uint8Array {
  const flags = new Uint8Array(0x10000);
  let index = 0;
  for (let i = 0; i < VALCONST.length; i++) {
    flags.fill(VALCONST[i], index, index + LENCONST[i]);
    index += LENCONST[i];
  }
  return flags;
}

const DECIMAL_DIGIT: RegExp = /^\p{Nd}$/u;

// Fast paths for strings the table loops would pass; anything else still goes through the loops for their message.
// Surrogate pairs are outside ILLEGAL_CHAR's legal class, so they take the loop.
const ILLEGAL_CHAR: RegExp = /[^\t\n\r\u0020-\ud7ff\ue000-\ufffd]/;
const ASCII_JDOM_NAME: RegExp = /^[A-Za-z_][A-Za-z0-9._-]*$/;
const ASCII_XML_NAME: RegExp = /^[A-Za-z_:][A-Za-z0-9._:-]*$/;
const ASCII_LETTER: RegExp = /^[A-Za-z]/;

function hex(c: number, width: number): string {
  return c.toString(16).padStart(width, '0');
}

export class IllegalNameException extends IllegalArgumentException {
  constructor(name: string, construct: string, reason: string) {
    super(`The name "${name}" is not legal for JDOM/XML ${construct}s: ${reason}.`);
    this.name = 'IllegalNameException';
  }
}

// JDOM's three constructors: (data, construct, reason), (data, construct) and (message). ProcessingInstruction passes
// its reason as the construct.
export class IllegalDataException extends IllegalArgumentException {
  constructor(data: string, construct?: string, reason?: string) {
    super(construct === undefined ? data : reason === undefined
      ? `The data "${data}" is not legal for a JDOM ${construct}.`
      : `The data "${data}" is not legal for a JDOM ${construct}: ${reason}.`);
    this.name = 'IllegalDataException';
  }
}

export class IllegalTargetException extends IllegalArgumentException {
  constructor(target: string, reason: string) {
    super(`The target "${target}" is not legal for JDOM/XML Processing Instructions: ${reason}.`);
    this.name = 'IllegalTargetException';
  }
}

export class IllegalAddException extends IllegalArgumentException {
  constructor(message: string) {
    super(message);
    this.name = 'IllegalAddException';
  }
}

export function illegalAddAttribute(element: Element, attribute: Attribute, reason: string): string {
  return `The attribute "${attribute.getQualifiedName()}" could not be added to the element ` +
    `"${element.getQualifiedName()}": ${reason}`;
}

export function illegalAddNamespace(element: Element, namespace: Namespace, reason: string): string {
  const declaration = namespace.getPrefix() === '' ? 'xmlns=' : `xmlns:${namespace.getPrefix()}=`;
  return `The namespace ${declaration}"${namespace.getURI()}" could not be added as a namespace to ` +
    `"${element.getQualifiedName()}": ${reason}`;
}

export class Verifier {
  // Element and attribute local names: XML names without ':'. Non-first characters are checked from the end.
  private static checkJDOMName(name: string): string | null {
    if (ASCII_JDOM_NAME.test(name)) {
      return null;
    }
    if (name.length === 0) {
      return 'XML names cannot be empty';
    }
    if ((CHARFLAGS[name.charCodeAt(0)] & MASKXMLSTARTCHAR) === 0) {
      return `XML name '${name}' cannot begin with the character "${name.charAt(0)}"`;
    }
    for (let i = name.length - 1; i >= 1; i--) {
      if ((CHARFLAGS[name.charCodeAt(i)] & MASKXMLNAMECHAR) === 0) {
        return `XML name '${name}' cannot contain the character "${name.charAt(i)}"`;
      }
    }
    return null;
  }

  static checkElementName(name: string): string | null {
    return Verifier.checkJDOMName(name);
  }

  static checkAttributeName(name: string): string | null {
    if (name === 'xmlns') {
      return 'An Attribute name may not be "xmlns"; use the Namespace class to manage namespaces';
    }
    return Verifier.checkJDOMName(name);
  }

  static checkCharacterData(text: string): string | null {
    const first = text.search(ILLEGAL_CHAR);
    if (first < 0) {
      return null;
    }
    for (let i = first; i < text.length; i++) {
      const c = text.charCodeAt(i);
      if (CHARFLAGS[c] !== 0) {
        continue;
      }
      if (!Verifier.isHighSurrogate(c)) {
        return `0x${hex(c, 4)} is not a legal XML character`;
      }
      i++;
      if (i >= text.length) {
        return `Truncated Surrogate Pair 0x${hex(c, 4)}????`;
      }
      if (!Verifier.isLowSurrogate(text.charCodeAt(i))) {
        return `Illegal Surrogate Pair 0x${hex(c, 4)}${hex(text.charCodeAt(i), 4)}`;
      }
    }
    return null;
  }

  static checkCDATASection(data: string): string | null {
    const reason = Verifier.checkCharacterData(data);
    if (reason !== null) {
      return reason;
    }
    return data.includes(']]>') ? 'CDATA cannot internally contain a CDATA ending delimiter (]]>)' : null;
  }

  static checkNamespacePrefix(prefix: string): string | null {
    return prefix === '' ? null : Verifier.checkJDOMName(prefix);
  }

  static checkNamespaceURI(uri: string): string | null {
    if (uri === '' || ASCII_LETTER.test(uri)) {
      return null;
    }
    const first = uri.charAt(0);
    if (DECIMAL_DIGIT.test(first)) {
      return 'Namespace URIs cannot begin with a number';
    }
    if (first === '$') {
      return 'Namespace URIs cannot begin with a dollar sign ($)';
    }
    if (first === '-') {
      return 'Namespace URIs cannot begin with a hyphen (-)';
    }
    if (Verifier.isXMLWhitespace(first)) {
      return 'Namespace URIs cannot begin with white-space';
    }
    return null;
  }

  static checkProcessingInstructionTarget(target: string): string | null {
    const reason = Verifier.checkXMLName(target);
    if (reason !== null) {
      return reason;
    }
    if (target.includes(':')) {
      return 'Processing instruction targets cannot contain colons';
    }
    if (target.toLowerCase() === 'xml') {
      return 'Processing instructions cannot have a target of "xml" in any combination of case. (Note that the ' +
        '"<?xml ... ?>" declaration at the beginning of a document is not a processing instruction and should ' +
        'not be added as one; it is written automatically during output, e.g. by XMLOutputter.)';
    }
    return null;
  }

  static checkProcessingInstructionData(data: string): string | null {
    const reason = Verifier.checkCharacterData(data);
    if (reason === null && data.includes('?>')) {
      return 'Processing instructions cannot contain the string "?>"';
    }
    return reason;
  }

  static checkCommentData(data: string): string | null {
    const reason = Verifier.checkCharacterData(data);
    if (reason !== null) {
      return reason;
    }
    if (data.includes('--')) {
      return 'Comments cannot contain double hyphens (--)';
    }
    return data.endsWith('-') ? 'Comment data cannot end with a hyphen.' : null;
  }

  static checkNamespaceCollision(namespace: Namespace, prefix: string, uri: string): string | null {
    return namespace.getPrefix() === prefix && namespace.getURI() !== uri
      ? `The namespace prefix "${prefix}" collides`
      : null;
  }

  // JDOM checkNamespaceCollision(Namespace, Element): the element's own namespace, its declarations, its attributes.
  static checkElementCollision(namespace: Namespace, element: Element): string | null {
    const reason = Verifier.checkNamespaceCollision(namespace, element.getNamespacePrefix(), element.getNamespaceURI());
    if (reason !== null) {
      return `${reason} with the element namespace prefix`;
    }
    return Verifier.checkDeclarationCollision(namespace, element) ?? Verifier.checkAttributeCollision(namespace, element);
  }

  static checkDeclarationCollision(namespace: Namespace, element: Element): string | null {
    for (const ns of element.getAdditionalNamespaces()) {
      const reason = Verifier.checkNamespaceCollision(namespace, ns.getPrefix(), ns.getURI());
      if (reason !== null) {
        return `${reason} with an additional namespace declared by the element`;
      }
    }
    return null;
  }

  static checkAttributeCollision(namespace: Namespace, element: Element): string | null {
    for (const attribute of element.getAttributes()) {
      const reason = attribute.getNamespaceURI() === ''
        ? null
        : Verifier.checkNamespaceCollision(namespace, attribute.getNamespacePrefix(), attribute.getNamespaceURI());
      if (reason !== null) {
        return `${reason} with an attribute namespace prefix on the element`;
      }
    }
    return null;
  }

  static isXMLPublicIDCharacter(c: string): boolean {
    return (c >= 'a' && c <= 'z') || (c >= '?' && c <= 'Z') || (c >= '\'' && c <= ';') || ' !=#$_%\n\r\t'.includes(c);
  }

  static checkPublicID(publicID: string): string | null {
    for (const c of publicID.split('')) {
      if (!Verifier.isXMLPublicIDCharacter(c)) {
        return `${c} is not a legal character in public IDs`;
      }
    }
    return null;
  }

  static checkSystemLiteral(systemLiteral: string): string | null {
    if (systemLiteral.includes('\'') && systemLiteral.includes('"')) {
      return 'System literals cannot simultaneously contain both single and double quotes.';
    }
    return Verifier.checkCharacterData(systemLiteral);
  }

  // Any XML name, ':' included (DocType names, processing instruction targets).
  static checkXMLName(name: string): string | null {
    if (ASCII_XML_NAME.test(name)) {
      return null;
    }
    if (name.length === 0) {
      return 'XML names cannot be empty';
    }
    if (!Verifier.isXMLNameStartCharacter(name.charCodeAt(0))) {
      return `XML names cannot begin with the character "${name.charAt(0)}"`;
    }
    for (let i = 1; i < name.length; i++) {
      if (!Verifier.isXMLNameCharacter(name.charCodeAt(i))) {
        return `XML names cannot contain the character "${name.charAt(i)}"`;
      }
    }
    return null;
  }

  static isHighSurrogate(c: number): boolean {
    return c >= 0xd800 && c <= 0xdbff;
  }

  static isLowSurrogate(c: number): boolean {
    return c >= 0xdc00 && c <= 0xdfff;
  }

  static isXMLNameCharacter(c: number): boolean {
    return (CHARFLAGS[c] & MASKXMLNAMECHAR) !== 0 || c === 0x3a;
  }

  static isXMLNameStartCharacter(c: number): boolean {
    return (CHARFLAGS[c] & MASKXMLSTARTCHAR) !== 0 || c === 0x3a;
  }

  static isXMLWhitespace(c: string): boolean {
    return c === ' ' || c === '\n' || c === '\t' || c === '\r';
  }
}
