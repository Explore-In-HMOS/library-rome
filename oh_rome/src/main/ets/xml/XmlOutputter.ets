// Behavior of JDOM 2.0.6.1 org.jdom2.output.XMLOutputter and its output support classes, as used by ROME (JDOM license, see LICENSE-JDOM)
import { CDATA, Comment, Content, CType, DocType, Document, Element, Namespace, ProcessingInstruction,
  Text } from './Dom';
import { docTypeDeclaration } from './Document';
import { EscapeStrategy, Format, isAllXMLWhitespace, isXMLWhitespace, TextMode } from './Format';

class FormatStack {
  private depth: number = 0;
  readonly defaultMode: TextMode;
  readonly indent: string | null;
  readonly encoding: string;
  readonly lineSeparator: string | null;
  readonly omitDeclaration: boolean;
  readonly omitEncoding: boolean;
  readonly expandEmptyElements: boolean;
  readonly escapeStrategy: EscapeStrategy;
  private levelIndent: (string | null)[] = [null];
  private levelEOL: (string | null)[] = [null];
  private levelEOLIndent: (string | null)[] = [null];
  private termEOLIndent: (string | null)[] = [null];
  private ignoreTrAXEscapingPIs: boolean[] = [false];
  private mode: TextMode[] = [TextMode.PRESERVE];
  private escapeOutput: boolean[] = [true];

  constructor(format: Format) {
    this.indent = format.getIndent();
    this.lineSeparator = format.getLineSeparator();
    this.encoding = format.getEncoding();
    this.omitDeclaration = format.getOmitDeclaration();
    this.omitEncoding = format.getOmitEncoding();
    this.expandEmptyElements = format.getExpandEmptyElements();
    this.escapeStrategy = format.getEscapeStrategy();
    this.defaultMode = format.getTextMode();
    this.mode[0] = format.getTextMode();
    if (this.mode[0] !== TextMode.PRESERVE) {
      this.levelIndent[0] = this.indent === null ? null : '';
      this.levelEOL[0] = this.lineSeparator;
      this.levelEOLIndent[0] = this.levelIndent[0] === null ? null : this.levelEOL[0];
      this.termEOLIndent[0] = this.levelEOLIndent[0];
    }
  }

  private resetReusableIndents(): void {
    let d = this.depth + 1;
    while (d < this.levelIndent.length && this.levelIndent[d] !== null) {
      this.levelIndent[d] = null;
      d++;
    }
  }

  isIgnoreTrAXEscapingPIs(): boolean {
    return this.ignoreTrAXEscapingPIs[this.depth];
  }

  setIgnoreTrAXEscapingPIs(ignore: boolean): void {
    this.ignoreTrAXEscapingPIs[this.depth] = ignore;
  }

  getEscapeOutput(): boolean {
    return this.escapeOutput[this.depth];
  }

  setEscapeOutput(escape: boolean): void {
    this.escapeOutput[this.depth] = escape;
  }

  getPadBetween(): string | null {
    return this.levelEOLIndent[this.depth];
  }

  getPadLast(): string | null {
    return this.termEOLIndent[this.depth];
  }

  getLevelEOL(): string | null {
    return this.levelEOL[this.depth];
  }

  getTextMode(): TextMode {
    return this.mode[this.depth];
  }

  setTextMode(mode: TextMode): void {
    const depth = this.depth;
    if (this.mode[depth] === mode) {
      return;
    }
    this.mode[depth] = mode;
    if (mode === TextMode.PRESERVE) {
      this.levelEOL[depth] = null;
      this.levelIndent[depth] = null;
      this.levelEOLIndent[depth] = null;
      this.termEOLIndent[depth] = null;
    } else {
      this.levelEOL[depth] = this.lineSeparator;
      if (this.indent === null || this.lineSeparator === null) {
        this.levelEOLIndent[depth] = null;
        this.termEOLIndent[depth] = null;
      } else {
        if (depth > 0) {
          let sb = '';
          for (let i = 1; i < depth; i++) {
            sb += this.indent;
          }
          this.termEOLIndent[depth] = this.lineSeparator + sb;
          this.levelIndent[depth] = sb + this.indent;
        } else {
          this.termEOLIndent[depth] = this.lineSeparator;
          this.levelIndent[depth] = '';
        }
        this.levelEOLIndent[depth] = this.lineSeparator + this.levelIndent[depth];
      }
    }
    this.resetReusableIndents();
  }

  push(): void {
    const prev = this.depth++;
    const depth = this.depth;
    if (depth >= this.levelIndent.length) {
      this.levelIndent.push(null);
      this.levelEOL.push(null);
      this.levelEOLIndent.push(null);
      this.termEOLIndent.push(null);
      this.ignoreTrAXEscapingPIs.push(false);
      this.mode.push(TextMode.PRESERVE);
      this.escapeOutput.push(true);
    }
    this.ignoreTrAXEscapingPIs[depth] = this.ignoreTrAXEscapingPIs[prev];
    this.mode[depth] = this.mode[prev];
    this.escapeOutput[depth] = this.escapeOutput[prev];
    const prevIndent = this.levelIndent[prev];
    const prevEOL = this.levelEOL[prev];
    if (prevIndent === null || prevEOL === null) {
      this.levelIndent[depth] = null;
      this.levelEOL[depth] = null;
      this.levelEOLIndent[depth] = null;
      this.termEOLIndent[depth] = null;
    } else if (this.levelIndent[depth] === null) {
      this.levelEOL[depth] = prevEOL;
      this.termEOLIndent[depth] = prevEOL + prevIndent;
      this.levelIndent[depth] = prevIndent + this.indent;
      this.levelEOLIndent[depth] = prevEOL + this.levelIndent[depth];
    }
  }

  pop(): void {
    this.depth--;
  }
}

function sameNamespace(a: Namespace, b: Namespace): boolean {
  return a.getPrefix() === b.getPrefix() && a.getURI() === b.getURI();
}

function namespaceOf(element: Element): Namespace {
  const ns = element.getNamespace();
  return ns === null ? Namespace.NO_NAMESPACE : ns;
}

// JDOM interns namespaces and compares them by identity; here a prefix and URI pair is the identity.
class NamespaceStack {
  private scopes: Map<string, Namespace>[] = [];
  private added: Namespace[][] = [];

  constructor() {
    const seed = new Map<string, Namespace>();
    seed.set('', Namespace.NO_NAMESPACE);
    seed.set('xml', Namespace.XML_NAMESPACE);
    this.scopes.push(seed);
    this.added.push([]);
  }

  private static check(store: Namespace[], namespace: Namespace, scope: Map<string, Namespace>): void {
    const bound = scope.get(namespace.getPrefix());
    if (bound !== undefined && sameNamespace(bound, namespace)) {
      return;
    }
    store.push(namespace);
    scope.set(namespace.getPrefix(), namespace);
  }

  push(element: Element): void {
    const toadd: Namespace[] = [];
    const scope = new Map<string, Namespace>(this.scopes[this.scopes.length - 1]);
    const mns = namespaceOf(element);
    NamespaceStack.check(toadd, mns, scope);
    const mnsAdded = toadd.length > 0;
    for (const ns of element.getAdditionalNamespaces()) {
      if (!sameNamespace(ns, mns)) {
        NamespaceStack.check(toadd, ns, scope);
      }
    }
    for (const attribute of element.getAttributes()) {
      const ns = attribute.getNamespace();
      if (!sameNamespace(ns, Namespace.NO_NAMESPACE) && !sameNamespace(ns, mns)) {
        NamespaceStack.check(toadd, ns, scope);
      }
    }
    const byPrefix = (a: Namespace, b: Namespace): number =>
      a.getPrefix() < b.getPrefix() ? -1 : (a.getPrefix() > b.getPrefix() ? 1 : 0);
    const sorted = mnsAdded ? [toadd[0]].concat(toadd.slice(1).sort(byPrefix)) : toadd.sort(byPrefix);
    this.scopes.push(scope);
    this.added.push(sorted);
  }

  pop(): void {
    this.scopes.pop();
    this.added.pop();
  }

  addedForward(): Namespace[] {
    return this.added[this.added.length - 1];
  }
}

interface Walker {
  isAllText(): boolean;
  hasNext(): boolean;
  next(): Content | null;
  text(): string | null;
  isCDATA(): boolean;
}

class WalkerPreserve implements Walker {
  private readonly content: Content[];
  private index: number = 0;

  constructor(content: Content[]) {
    this.content = content;
  }

  isAllText(): boolean {
    return this.content.length === 0;
  }

  hasNext(): boolean {
    return this.index < this.content.length;
  }

  next(): Content | null {
    return this.content[this.index++];
  }

  text(): string | null {
    return null;
  }

  isCDATA(): boolean {
    return false;
  }
}

enum Trim {
  LEFT,
  RIGHT,
  BOTH,
  COMPACT,
  NONE
}

function trimText(trim: Trim, text: string): string {
  switch (trim) {
    case Trim.BOTH:
      return Format.trimBoth(text);
    case Trim.LEFT:
      return Format.trimLeft(text);
    case Trim.RIGHT:
      return Format.trimRight(text);
    case Trim.COMPACT:
      return Format.compact(text);
    default:
      return text;
  }
}

function isTextLike(c: Content): boolean {
  return c.getCType() === CType.Text || c.getCType() === CType.CDATA;
}

const CDATA_TOKEN: CDATA = new CDATA('');

// JDOM's AbstractFormattedWalker with WalkerTRIM, WalkerNORMALIZE and WalkerTRIM_FULL_WHITE. Runs of adjacent
// text are pre-rendered (trimmed, escaped, padded) and handed out as text() with a null next().
class FormattedWalker implements Walker {
  private readonly content: Content[];
  private index: number = 0;
  private readonly mode: TextMode;
  private pending: Content | null = null;
  private readonly alltext: boolean;
  private readonly newlineindent: string | null;
  private readonly endofline: string | null;
  private readonly escape: EscapeStrategy | null;
  private readonly fstack: FormatStack;
  private hasnext: boolean = true;
  private multitext: boolean = false;
  private pendingmt: boolean = false;
  private mtbuffer: string = '';
  private mtpostpad: boolean = false;
  private mtgottext: boolean = false;
  private mtsize: number = 0;
  private mtsourcesize: number = 0;
  private mtsource: Content[] = [];
  private mtdata: (Content | null)[] = [];
  private mttext: (string | null)[] = [];
  private mtpos: number = -1;
  private mtwasescape: boolean | null = null;

  constructor(content: Content[], fstack: FormatStack, doescape: boolean, mode: TextMode) {
    this.content = content;
    this.fstack = fstack;
    this.mode = mode;
    this.escape = doescape ? fstack.escapeStrategy : null;
    this.newlineindent = fstack.getPadBetween();
    this.endofline = fstack.getLevelEOL();
    if (content.length === 0) {
      this.alltext = true;
    } else {
      let atext = false;
      this.pending = this.nextContent();
      if (isTextLike(this.pending!)) {
        this.buildMultiText(true);
        this.analyzeMultiText(0, this.mtsourcesize);
        this.done();
        if (this.pending === null) {
          atext = true;
        }
        if (this.mtsize === 0) {
          this.pendingmt = false;
        }
      }
      this.alltext = atext;
    }
    this.hasnext = this.pendingmt || this.pending !== null;
  }

  private nextContent(): Content | null {
    return this.index < this.content.length ? this.content[this.index++] : null;
  }

  private closeText(): void {
    if (this.mtbuffer.length === 0) {
      return;
    }
    this.mtdata[this.mtsize] = null;
    this.mttext[this.mtsize++] = this.mtbuffer;
    this.mtbuffer = '';
  }

  private appendText(trim: Trim, text: string): void {
    if (text.length === 0) {
      return;
    }
    let toadd = trimText(trim, text);
    if (this.escape !== null && this.fstack.getEscapeOutput()) {
      toadd = Format.escapeText(this.escape, this.endofline, toadd);
    }
    this.mtbuffer += toadd;
    this.mtgottext = true;
  }

  private appendCDATA(trim: Trim, text: string): void {
    this.closeText();
    this.mtdata[this.mtsize] = CDATA_TOKEN;
    this.mttext[this.mtsize++] = trimText(trim, text);
    this.mtgottext = true;
  }

  private forceAppend(text: string): void {
    this.mtgottext = true;
    this.mtbuffer += text;
  }

  private appendRaw(c: Content): void {
    this.closeText();
    this.mttext[this.mtsize] = null;
    this.mtdata[this.mtsize++] = c;
    this.mtbuffer = '';
  }

  private done(): void {
    if (this.mtpostpad && this.newlineindent !== null) {
      this.mtbuffer += this.newlineindent;
    }
    if (this.mtgottext) {
      this.closeText();
    }
    this.mtbuffer = '';
  }

  next(): Content | null {
    if (!this.hasnext) {
      throw new Error('Cannot walk off end of Content');
    }
    if (this.multitext && this.mtpos + 1 >= this.mtsize) {
      this.multitext = false;
      this.resetMultiText();
    }
    if (this.pendingmt) {
      if (this.mtwasescape !== null && this.fstack.getEscapeOutput() !== this.mtwasescape) {
        this.mtsize = 0;
        this.mtwasescape = this.fstack.getEscapeOutput();
        this.analyzeMultiText(0, this.mtsourcesize);
        this.done();
      }
      this.multitext = true;
      this.pendingmt = false;
    }
    if (this.multitext) {
      this.mtpos++;
      const ret = this.mttext[this.mtpos] === null ? this.mtdata[this.mtpos] : null;
      this.hasnext = this.mtpos + 1 < this.mtsize || this.pending !== null;
      return ret;
    }
    const ret = this.pending;
    this.pending = this.nextContent();
    if (this.pending === null) {
      this.hasnext = false;
    } else if (isTextLike(this.pending)) {
      this.buildMultiText(false);
      this.analyzeMultiText(0, this.mtsourcesize);
      this.done();
      if (this.mtsize > 0) {
        this.hasnext = true;
      } else if (this.pending !== null && this.newlineindent !== null) {
        this.padPending(this.newlineindent);
        this.hasnext = true;
      } else {
        this.pendingmt = false;
        this.hasnext = this.pending !== null;
      }
    } else {
      if (this.newlineindent !== null) {
        this.padPending(this.newlineindent);
      }
      this.hasnext = true;
    }
    return ret;
  }

  private padPending(pad: string): void {
    this.resetMultiText();
    this.pendingmt = true;
    this.forceAppend(pad);
    this.done();
  }

  private resetMultiText(): void {
    this.mtsourcesize = 0;
    this.mtpos = -1;
    this.mtsize = 0;
    this.mtgottext = false;
    this.mtpostpad = false;
    this.mtwasescape = null;
    this.mtbuffer = '';
  }

  isAllText(): boolean {
    return this.alltext;
  }

  hasNext(): boolean {
    return this.hasnext;
  }

  private buildMultiText(first: boolean): void {
    if (!first && this.newlineindent !== null) {
      this.mtbuffer += this.newlineindent;
    }
    this.mtsourcesize = 0;
    do {
      this.mtsource[this.mtsourcesize++] = this.pending!;
      this.pending = this.nextContent();
    } while (this.pending !== null && isTextLike(this.pending));
    this.mtpostpad = this.pending !== null;
    this.mtwasescape = this.fstack.getEscapeOutput();
    this.pendingmt = true;
  }

  text(): string | null {
    if (!this.multitext || this.mtpos >= this.mtsize) {
      return null;
    }
    return this.mttext[this.mtpos];
  }

  isCDATA(): boolean {
    if (!this.multitext || this.mtpos >= this.mtsize || this.mttext[this.mtpos] === null) {
      return false;
    }
    return this.mtdata[this.mtpos] === CDATA_TOKEN;
  }

  private analyzeMultiText(offset: number, len: number): void {
    if (this.mode === TextMode.TRIM) {
      this.analyzeTrim(offset, len);
    } else if (this.mode === TextMode.NORMALIZE) {
      this.analyzeNormalize(offset, len);
    } else {
      this.analyzeTrimFullWhite(offset, len);
    }
  }

  private isWhiteText(c: Content): boolean {
    return c instanceof Text && isAllXMLWhitespace(c.getValue());
  }

  private appendContent(trim: Trim, c: Content): void {
    if (c.getCType() === CType.Text) {
      this.appendText(trim, c.getValue());
    } else if (c.getCType() === CType.CDATA) {
      this.appendCDATA(trim, c.getValue());
    } else {
      this.appendRaw(c);
    }
  }

  private analyzeTrim(start: number, length: number): void {
    let offset = start;
    let len = length;
    while (len > 0 && this.isWhiteText(this.mtsource[offset])) {
      offset++;
      len--;
    }
    while (len > 0 && this.isWhiteText(this.mtsource[offset + len - 1])) {
      len--;
    }
    for (let i = 0; i < len; i++) {
      let trim = Trim.NONE;
      if (i + 1 === len) {
        trim = Trim.RIGHT;
      }
      if (i === 0) {
        trim = Trim.LEFT;
      }
      if (len === 1) {
        trim = Trim.BOTH;
      }
      this.appendContent(trim, this.mtsource[offset + i]);
    }
  }

  private analyzeNormalize(offset: number, len: number): void {
    let needspace = false;
    let between = false;
    for (let i = 0; i < len; i++) {
      const c = this.mtsource[offset + i];
      if (c.getCType() === CType.Text || c.getCType() === CType.CDATA) {
        const ttext = c.getValue();
        if (isAllXMLWhitespace(ttext)) {
          if (between && ttext.length > 0) {
            needspace = true;
          }
        } else {
          if (between && (needspace || isXMLWhitespace(ttext.charCodeAt(0)))) {
            this.appendText(Trim.NONE, ' ');
          }
          this.appendContent(Trim.COMPACT, c);
          between = true;
          needspace = isXMLWhitespace(ttext.charCodeAt(ttext.length - 1));
        }
      } else {
        if (between && needspace) {
          this.appendText(Trim.NONE, ' ');
        }
        this.appendRaw(c);
        between = true;
        needspace = false;
      }
    }
  }

  private analyzeTrimFullWhite(offset: number, len: number): void {
    let ln = len;
    while (--ln >= 0) {
      if (!this.isWhiteText(this.mtsource[offset + ln])) {
        break;
      }
    }
    if (ln < 0) {
      return;
    }
    for (let i = 0; i < len; i++) {
      this.appendContent(Trim.NONE, this.mtsource[offset + i]);
    }
  }
}

function buildWalker(fstack: FormatStack, content: Content[], escape: boolean): Walker {
  const mode = fstack.getTextMode();
  return mode === TextMode.PRESERVE ? new WalkerPreserve(content) : new FormattedWalker(content, fstack, escape, mode);
}

const PI_DISABLE_OUTPUT_ESCAPING = 'javax.xml.transform.disable-output-escaping';
const PI_ENABLE_OUTPUT_ESCAPING = 'javax.xml.transform.enable-output-escaping';

class OutputProcessor {
  private out: string = '';

  private write(str: string | null): void {
    if (str !== null) {
      this.out += str;
    }
  }

  result(): string {
    return this.out;
  }

  printDocument(fstack: FormatStack, nstack: NamespaceStack, doc: Document): void {
    this.printDeclaration(fstack);
    const walker = buildWalker(fstack, doc.getContent(), true);
    if (!walker.hasNext()) {
      return;
    }
    while (walker.hasNext()) {
      const c = walker.next();
      if (c === null) {
        const padding = walker.text();
        if (padding !== null && isAllXMLWhitespace(padding) && !walker.isCDATA()) {
          this.write(padding);
        }
      } else if (c instanceof Comment) {
        this.printComment(c);
      } else if (c instanceof DocType) {
        this.printDocType(fstack, c);
      } else if (c instanceof Element) {
        this.printElement(fstack, nstack, c);
      } else if (c instanceof ProcessingInstruction) {
        this.printProcessingInstruction(fstack, c);
      } else if (c.getCType() === CType.Text && isAllXMLWhitespace(c.getValue())) {
        this.write(c.getValue());
      }
    }
    this.write(fstack.lineSeparator);
  }

  private printDeclaration(fstack: FormatStack): void {
    if (fstack.omitDeclaration) {
      return;
    }
    if (fstack.omitEncoding) {
      this.write('<?xml version="1.0"?>');
    } else {
      this.write(`<?xml version="1.0" encoding="${fstack.encoding}"?>`);
    }
    this.write(fstack.lineSeparator);
  }

  printDocType(fstack: FormatStack, docType: DocType): void {
    this.write(docTypeDeclaration(docType, fstack.lineSeparator));
  }

  printProcessingInstruction(fstack: FormatStack, pi: ProcessingInstruction): void {
    const target = pi.getTarget();
    if (!fstack.isIgnoreTrAXEscapingPIs()) {
      if (target === PI_DISABLE_OUTPUT_ESCAPING) {
        fstack.setEscapeOutput(false);
        return;
      }
      if (target === PI_ENABLE_OUTPUT_ESCAPING) {
        fstack.setEscapeOutput(true);
        return;
      }
    }
    const rawData = pi.getData();
    this.write(rawData !== '' ? `<?${target} ${rawData}?>` : `<?${target}?>`);
  }

  printComment(comment: Comment): void {
    this.write(`<!--${comment.getText()}-->`);
  }

  private printText(fstack: FormatStack, text: Text): void {
    if (fstack.getEscapeOutput()) {
      this.write(Format.escapeText(fstack.escapeStrategy, fstack.lineSeparator, text.getText()));
    } else {
      this.write(text.getText());
    }
  }

  private writeEmptyElement(fstack: FormatStack, element: Element): void {
    this.write(fstack.expandEmptyElements ? `></${element.getQualifiedName()}>` : ' />');
  }

  printElement(fstack: FormatStack, nstack: NamespaceStack, element: Element): void {
    nstack.push(element);
    try {
      const content = element.getContent();
      this.write('<');
      this.write(element.getQualifiedName());
      for (const ns of nstack.addedForward()) {
        this.printNamespace(fstack, ns);
      }
      for (const attribute of element.getAttributes()) {
        this.write(` ${attribute.getQualifiedName()}="`);
        this.writeAttributeValue(fstack, attribute.getValue());
        this.write('"');
      }
      if (content.length === 0) {
        this.writeEmptyElement(fstack, element);
        return;
      }
      fstack.push();
      try {
        const space = element.getAttributeValue('space', Namespace.XML_NAMESPACE);
        if (space === 'default') {
          fstack.setTextMode(fstack.defaultMode);
        } else if (space === 'preserve') {
          fstack.setTextMode(TextMode.PRESERVE);
        }
        const walker = buildWalker(fstack, content, true);
        if (!walker.hasNext()) {
          this.writeEmptyElement(fstack, element);
          return;
        }
        this.write('>');
        if (!walker.isAllText()) {
          this.write(fstack.getPadBetween());
        }
        this.printContent(fstack, nstack, walker);
        if (!walker.isAllText()) {
          this.write(fstack.getPadLast());
        }
        this.write(`</${element.getQualifiedName()}>`);
      } finally {
        fstack.pop();
      }
    } finally {
      nstack.pop();
    }
  }

  printContent(fstack: FormatStack, nstack: NamespaceStack, walker: Walker): void {
    while (walker.hasNext()) {
      const c = walker.next();
      if (c === null) {
        const t = walker.text();
        if (walker.isCDATA()) {
          this.write(`<![CDATA[${t}]]>`);
        } else {
          this.write(t);
        }
      } else if (c instanceof CDATA) {
        this.write(`<![CDATA[${c.getText()}]]>`);
      } else if (c instanceof Text) {
        this.printText(fstack, c);
      } else if (c instanceof Comment) {
        this.printComment(c);
      } else if (c instanceof DocType) {
        this.printDocType(fstack, c);
      } else if (c instanceof Element) {
        this.printElement(fstack, nstack, c);
      } else if (c instanceof ProcessingInstruction) {
        this.printProcessingInstruction(fstack, c);
      }
    }
  }

  private printNamespace(fstack: FormatStack, ns: Namespace): void {
    this.write(ns.getPrefix() === '' ? ' xmlns="' : ` xmlns:${ns.getPrefix()}="`);
    this.writeAttributeValue(fstack, ns.getURI());
    this.write('"');
  }

  private writeAttributeValue(fstack: FormatStack, value: string): void {
    this.write(fstack.getEscapeOutput() ? Format.escapeAttribute(fstack.escapeStrategy, value) : value);
  }
}

export class XMLOutputter {
  private format: Format;

  constructor(format?: Format | null) {
    this.format = format === undefined || format === null ? Format.getRawFormat() : format.clone();
  }

  setFormat(format: Format): void {
    this.format = format.clone();
  }

  getFormat(): Format {
    return this.format;
  }

  outputString(node: Document | Element | Content[] | Text | Comment | ProcessingInstruction | DocType): string {
    const processor = new OutputProcessor();
    const fstack = new FormatStack(this.format);
    if (node instanceof Document) {
      processor.printDocument(fstack, new NamespaceStack(), node);
    } else if (node instanceof Element) {
      processor.printElement(fstack, new NamespaceStack(), node);
    } else if (node instanceof Text) {
      const walker = buildWalker(fstack, [node], true);
      if (walker.hasNext()) {
        processor.printContent(fstack, new NamespaceStack(), walker);
      }
    } else if (node instanceof Comment) {
      processor.printComment(node);
    } else if (node instanceof ProcessingInstruction) {
      fstack.setIgnoreTrAXEscapingPIs(true);
      processor.printProcessingInstruction(fstack, node);
    } else if (node instanceof DocType) {
      processor.printDocType(fstack, node);
    } else {
      processor.printContent(fstack, new NamespaceStack(), buildWalker(fstack, node, true));
    }
    return processor.result();
  }

  outputElementContentString(element: Element): string {
    return this.outputString(element.getContent());
  }
}
