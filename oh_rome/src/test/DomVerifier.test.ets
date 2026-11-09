import { describe, it, expect } from '@ohos/hypium';
import {
  Attribute, CDATA, Comment, Content, DocType, Document, Element, Namespace, ProcessingInstruction, Text
} from '../main/ets/xml/Dom';
import { Verifier } from '../main/ets/xml/Verifier';
import { DOM_VERIFIER_CASES, DomVerifierCase } from './DomVerifierCases';

// Same strings as DomOracle.dump.
function dump(e: Element): string {
  const ns = e.getAdditionalNamespaces().map((n: Namespace) => `${n.getPrefix()}=${n.getURI()}`);
  const attrs = e.getAttributes().map((a: Attribute) => `${a.getQualifiedName()}{${a.getNamespaceURI()}}=${a.getValue()}`);
  return `${e.getQualifiedName()}{${e.getNamespaceURI()}} ns[${ns.join(',')}] a[${attrs.join(',')}]`;
}

function ns(prefix: string | null, uri: string | null): Namespace {
  return Namespace.getNamespace(prefix, uri);
}

function scenario(a: (string | null)[]): Element {
  const e = new Element('e', ns(a[0], a[1]));
  e.addNamespaceDeclaration(ns('p', 'urn:p'));
  e.setAttribute(new Attribute('at', 'v', ns('q', 'urn:q')));
  return e;
}

const CTYPE_NAMES: string[] = ['Element', 'Text', 'CDATA', 'Comment', 'ProcessingInstruction', 'DocType'];

// Same strings as DomOracle.dump(Document).
function dumpDocument(d: Document): string {
  return d.getContent().map((c: Content): string => {
    if (c instanceof Element) {
      return `Element:${c.getQualifiedName()}`;
    }
    if (c instanceof DocType) {
      return `DocType:${c.getElementName()}`;
    }
    return `${CTYPE_NAMES[c.getCType() as number]}:${c.getValue()}`;
  }).join(',');
}

function node(spec: string): Content {
  const text = spec.substring(spec.indexOf(':') + 1);
  switch (spec.substring(0, spec.indexOf(':'))) {
    case 'Element':
      return new Element(text);
    case 'Text':
      return new Text(text);
    case 'CDATA':
      return new CDATA(text);
    case 'Comment':
      return new Comment(text);
    case 'PI':
      return new ProcessingInstruction(text, '');
    case 'DocType':
      return new DocType(text);
    default:
      throw new Error(spec);
  }
}

function doc(a: (string | null)[], from: number): Document {
  const d = new Document();
  for (let i = from; i < a.length; i++) {
    d.addContent(node(a[i] as string));
  }
  return d;
}

// a[0]: the node, a[1]: its first parent (element or document), a[2]: where it is added again.
function addParented(a: (string | null)[]): string {
  const child = node(a[0] as string);
  const firstElement = new Element('first');
  const firstDoc = new Document();
  if (a[1] === 'element') {
    firstElement.addContent(child);
  } else {
    firstDoc.addContent(child);
  }
  const otherDoc = new Document();
  switch (a[2]) {
    case 'element':
      new Element('other').addContent(child);
      return '';
    case 'element at 5':
      new Element('other').addContentAt(5, child);
      return '';
    case 'document at 5':
      return dumpDocument(otherDoc.addContentAt(5, child));
    case 'document':
      return dumpDocument(otherDoc.addContent(child));
    case 'same element':
      firstElement.addContent(child);
      return '';
    case 'same document':
      return dumpDocument(firstDoc.addContent(child));
    case 'setRootElement':
      return dumpDocument(firstDoc.setRootElement(child as Element));
    case 'new Document':
      return dumpDocument(new Document(child as Element));
    case 'setDocType':
      return dumpDocument(otherDoc.setDocType(child as DocType));
    default:
      throw new Error(a[2] as string);
  }
}

// a[0]: the index, a[1]: the node, a[2]...: the element's content before.
function addAt(a: (string | null)[]): string {
  const e = new Element('e');
  for (let i = 2; i < a.length; i++) {
    e.addContent(node(a[i] as string));
  }
  return e.addContentAt(Number(a[0]), node(a[1] as string)).getValue();
}

// a[0]: where the attribute, already set on f:first, is set again.
function setParentedAttribute(a: (string | null)[]): string {
  const first = new Element('first', ns('f', 'urn:f'));
  const at = new Attribute('at', 'v', ns('p', 'urn:p'));
  first.setAttribute(at);
  switch (a[0]) {
    case 'other':
      new Element('other').setAttribute(at);
      return '';
    case 'colliding other':
      new Element('other', ns('p', 'urn:other')).setAttribute(at);
      return '';
    case 'same':
      first.setAttribute(at);
      return '';
    case 'detached': {
      at.detach();
      const other = new Element('other');
      other.setAttribute(at);
      return `${dump(other)} ${dump(first)}`;
    }
    case 'same name':
      first.setAttribute(new Attribute('at', 'w', ns('p', 'urn:p')));
      return `${dump(first)} ${at.getParent() === null}`;
    default:
      throw new Error(a[0] as string);
  }
}

// root > b > c; a[0] is added to a[1].
function addSelfOrAncestor(a: (string | null)[]): string {
  const root = new Element('root');
  const b = new Element('b');
  const c = new Element('c');
  root.addContent(b);
  b.addContent(c);
  const byName = (name: string | null): Element => name === 'root' ? root : name === 'b' ? b : c;
  byName(a[1]).addContent(byName(a[0]));
  return '';
}

// A list that fails at its last node; JDOM adds none of it.
function addList(a: (string | null)[]): string {
  const e = new Element('e');
  e.addContent(new Text('t'));
  const parented = new Element('p');
  new Element('x').addContent(parented);
  try {
    e.addContent([new Element(a[0] as string), new Comment(a[1] as string), parented]);
  } catch (ex) {
    return `${e.getContentSize()} ${e.getValue()} ${(ex as Error).message}`;
  }
  return 'added';
}

function setList(a: (string | null)[]): string {
  const e = new Element('e');
  const old = new Text('old');
  e.addContent(old);
  const parented = new Element('p');
  new Element('x').addContent(parented);
  try {
    e.setContent([new Text(a[0] as string), parented]);
  } catch (ex) {
    return `${e.getContentSize()} ${e.getValue()} ${old.getParent() === e} ${(ex as Error).message}`;
  }
  return 'set';
}

function runContent(op: string, a: (string | null)[]): string {
  switch (op) {
    case 'add parented':
      return addParented(a);
    case 'add self or ancestor':
      return addSelfOrAncestor(a);
    case 'Element.addContent(DocType)':
      new Element('a').addContent(new DocType('a'));
      return '';
    case 'Element.addContent(list)':
      return addList(a);
    case 'Element.setContent(list)':
      return setList(a);
    case 'Document.addContent':
      return dumpDocument(doc(a, 0));
    case 'Document.addContent(index)':
      return dumpDocument(doc(a, 2).addContentAt(Number(a[0]), node(a[1] as string)));
    case 'Element.addContent(index)':
      return addAt(a);
    case 'setAttribute(parented)':
      return setParentedAttribute(a);
    case 'Document.setRootElement':
      return dumpDocument(doc(a, 1).setRootElement(new Element(a[0] as string)));
    case 'Document.setDocType':
      return dumpDocument(doc(a, 1).setDocType(new DocType(a[0] as string)));
    default:
      throw new Error(op);
  }
}

function run(op: string, a: (string | null)[]): string {
  const s = (i: number): string => a[i] as string;
  switch (op) {
    case 'Namespace.getNamespace(uri)': {
      const n = Namespace.getNamespace(a[0]);
      return `${n.getPrefix()}|${n.getURI()}`;
    }
    case 'Namespace.getNamespace': {
      const n = ns(a[0], a[1]);
      return `${n.getPrefix()}|${n.getURI()}`;
    }
    case 'Element':
      new Element(s(0));
      return '';
    case 'Element(ns)':
      return dump(new Element(s(0), ns(a[1], a[2])));
    case 'Element.setName':
      return dump(new Element('a').setName(s(0)));
    case 'Element.setText':
      return new Element('a').setText(a[0]).getText();
    case 'Element.addContent':
      return new Element('a').addContent(s(0)).getText();
    case 'Element.setAttribute':
      return dump(new Element('a').setAttribute(s(0), s(1)));
    case 'Element.setAttribute(ns)':
      return dump(new Element('a').setAttribute(s(0), s(1), ns(a[2], a[3])));
    case 'Attribute':
      new Attribute(s(0), s(1));
      return '';
    case 'Attribute(ns)':
      return new Attribute(s(0), s(1), ns(a[2], a[3])).getQualifiedName();
    case 'Attribute.setName':
      return new Attribute('a', 'v').setName(s(0)).getName();
    case 'Attribute.setValue':
      return new Attribute('a', 'v').setValue(s(0)).getValue();
    case 'Attribute.setNamespace':
      return new Attribute('a', 'v').setNamespace(ns(a[0], a[1])).getQualifiedName();
    case 'Text':
      return new Text(s(0)).getText();
    case 'Text.setText':
      return new Text('x').setText(s(0)).getText();
    case 'Text.append': {
      const t = new Text(s(0));
      t.append(s(1));
      return t.getText();
    }
    case 'CDATA':
      return new CDATA(s(0)).getText();
    case 'CDATA.setText':
      return new CDATA('x').setText(s(0)).getText();
    case 'CDATA.append': {
      const t = new CDATA(s(0));
      t.append(s(1));
      return t.getText();
    }
    case 'Comment':
      return new Comment(s(0)).getText();
    case 'ProcessingInstruction':
      new ProcessingInstruction(s(0), s(1));
      return '';
    case 'DocType':
      new DocType(s(0), a[1], a[2]);
      return '';
    case 'addNamespaceDeclaration': {
      const e = scenario(a);
      const added = e.addNamespaceDeclaration(ns(a[2], a[3]));
      return `${added} ${dump(e)}`;
    }
    case 'setNamespace':
      return dump(scenario(a).setNamespace(ns(a[2], a[3])));
    case 'setAttribute(Attribute)':
      return dump(scenario(a).setAttribute(new Attribute(s(4), 'w', ns(a[2], a[3]))));
    case 'setAttribute(name, value, ns)':
      return dump(scenario(a).setAttribute(s(4), 'w', ns(a[2], a[3])));
    default:
      return runContent(op, a);
  }
}

function result(op: string, a: (string | null)[]): string {
  try {
    return `OK ${run(op, a)}`;
  } catch (e) {
    return `ERR ${(e as Error).name}: ${(e as Error).message}`;
  }
}

function hex4(c: number): string {
  return c.toString(16).padStart(4, '0');
}

// Same format as DomOracle.sweep: the legal code units as ranges. Sweeps call the Verifier check behind each
// constructor instead of the constructor: half a million throws overflow the test runner's log.
function sweep(check: (s: string) => string | null): string {
  const ranges: string[] = [];
  let start = -1;
  for (let c = 0; c <= 0x10000; c++) {
    const ok = c < 0x10000 && check(String.fromCharCode(c)) === null;
    if (ok && start < 0) {
      start = c;
    }
    if (!ok && start >= 0) {
      ranges.push(start === c - 1 ? hex4(start) : `${hex4(start)}-${hex4(c - 1)}`);
      start = -1;
    }
  }
  return ranges.join(',');
}

// A sweep's Verifier check and the constructor DomOracle sweeps with.
class SweepSite {
  check: (s: string) => string | null;
  construct: (s: string) => void;

  constructor(check: (s: string) => string | null, construct: (s: string) => void) {
    this.check = check;
    this.construct = construct;
  }
}

function sweepSite(op: string): SweepSite {
  switch (op) {
    case 'sweep Text':
      return new SweepSite((s: string) => Verifier.checkCharacterData(s), (s: string) => {
        new Text(s);
      });
    case 'sweep Text pair low half':
      return new SweepSite((s: string) => Verifier.checkCharacterData('\ud800' + s), (s: string) => {
        new Text('\ud800' + s);
      });
    case 'sweep Element name start':
      return new SweepSite((s: string) => Verifier.checkElementName(s), (s: string) => {
        new Element(s);
      });
    case 'sweep Element name char':
      return new SweepSite((s: string) => Verifier.checkElementName('a' + s), (s: string) => {
        new Element('a' + s);
      });
    case 'sweep DocType name start':
      return new SweepSite((s: string) => Verifier.checkXMLName(s), (s: string) => {
        new DocType(s);
      });
    case 'sweep DocType name char':
      return new SweepSite((s: string) => Verifier.checkXMLName('a' + s), (s: string) => {
        new DocType('a' + s);
      });
    case 'sweep DocType public ID':
      return new SweepSite((s: string) => Verifier.checkPublicID(s), (s: string) => {
        new DocType('a', s, null);
      });
    case 'sweep Namespace URI start':
      return new SweepSite((s: string) => Verifier.checkNamespaceURI(s + 'x'), (s: string) => {
        Namespace.getNamespace('p', s + 'x');
      });
    default:
      throw new Error(op);
  }
}

// The sweep's ranges, then whether its first illegal code unit, through the constructor, throws the check's reason.
function sweepResult(op: string): string {
  const site = sweepSite(op);
  const ranges = sweep(site.check);
  let c = 0;
  while (site.check(String.fromCharCode(c)) === null) {
    c++;
  }
  const reason = site.check(String.fromCharCode(c)) as string;
  try {
    site.construct(String.fromCharCode(c));
  } catch (e) {
    if ((e as Error).message.includes(reason)) {
      return ranges;
    }
  }
  return `${ranges} (the constructor does not throw "${reason}" for 0x${hex4(c)})`;
}

function mismatches(): string {
  const failures: string[] = [];
  DOM_VERIFIER_CASES.forEach((c: DomVerifierCase) => {
    const actual = c.op.startsWith('sweep ') ? sweepResult(c.op) : result(c.op, c.args);
    if (actual !== c.expected) {
      failures.push(`${c.op} ${JSON.stringify(c.args)}\n  expected: ${JSON.stringify(c.expected)}\n  actual:   ` +
        `${JSON.stringify(actual)}`);
    }
  });
  return failures.join('\n');
}

export default function domVerifierTest() {
  describe('DomVerifier', () => {
    it('matchesJdomOnEveryOracleCase', 0, () => {
      expect(mismatches()).assertEqual('');
    });
  });
}
