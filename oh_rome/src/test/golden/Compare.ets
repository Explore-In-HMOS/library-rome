// Golden harness: compares a ROME golden (tools/golden BeanJson format) with our serialized model.
import { JsonKind, JsonNode } from './Json';

// A private field `_<name>` behind an accessor `<name>` is matched to the Java property `<name>` (CONTRIBUTING.md).
// Other field names that hold a Java property under another name are listed here; the PR says why.
const KEY_RENAMES: Map<string, string> = new Map<string, string>([
  ['moduleList', 'modules']
]);

// Our fields with no Java bean property (internals). Same rule: add with the reason in the PR.
const ACTUAL_ONLY_KEYS: Set<string> = new Set<string>([
  'wireFeed', // SyndFeed: the preserved wire feed (originalWireFeed()), excluded on the Java side too
  'preserveWireFeed',
  'wireEntry',
  'uriResolved' // atom.Person: Java has only a setter and getUriResolved(String), not a bean property
]);

// Java bean properties we compute instead of storing (accessors are not serialized). Add with the reason.
const EXPECTED_ONLY_KEYS: Set<string> = new Set<string>([]);

// Java getters that fall back to another property when their own field is null
// (Alternatives.firstNotNull(resolved, raw)); our field holds the raw value, as the Java field does.
const RESOLVED_FALLBACKS: Map<string, string> = new Map<string, string>([
  ['hrefResolved', 'href'], // atom.Link
  ['schemeResolved', 'scheme'] // atom.Category
]);

const MAX_DIFFS = 25;

// rome-opml tree node ids ("node." / "parent." + a run-dependent hash, ConverterForOPML10.java:150,161) are
// numbered by first appearance in the goldens ("node.#1", "parent.#1"); ours must map onto them one to one.
const GOLDEN_NODE_ID = /^(node|parent)\.(#\d+)$/;
const NODE_ID = /^(node|parent)\.(.+)$/;

export class GoldenDiff {
  readonly lines: string[] = [];
  readonly nodeIds: Map<string, string> = new Map<string, string>();
  readonly nodeIdsBack: Map<string, string> = new Map<string, string>();

  add(path: string, message: string): void {
    if (this.lines.length < MAX_DIFFS) {
      this.lines.push(`${path.startsWith('.') || path.startsWith('[') || path === '' ? `$${path}` : path}: ${message}`);
    } else if (this.lines.length === MAX_DIFFS) {
      this.lines.push('... more differences omitted');
    }
  }

  isEmpty(): boolean {
    return this.lines.length === 0;
  }
}

export function compareJson(expected: JsonNode, actual: JsonNode, path: string, diff: GoldenDiff): void {
  if (expected.kind === JsonKind.OBJECT && expected.fields.size === 1 && expected.fields.has('$set')) {
    compareSet(expected.get('$set')!, actual, path, diff);
    return;
  }
  if (expected.kind === JsonKind.ARRAY && actual.kind === JsonKind.ARRAY && isNullSingleton(expected) &&
    actual.items.length === 0) {
    return; // Java stores [null] when a singular setter gets null; we store [] (see DCModule).
  }
  if (expected.kind !== actual.kind) {
    diff.add(path, `expected ${expected.describe()} but was ${actual.describe()}`);
    return;
  }
  switch (expected.kind) {
    case JsonKind.NULL:
      return;
    case JsonKind.BOOLEAN:
      if (expected.bool !== actual.bool) {
        diff.add(path, `expected ${expected.bool} but was ${actual.bool}`);
      }
      return;
    case JsonKind.NUMBER:
      if (expected.num !== actual.num) {
        diff.add(path, `expected ${expected.num} but was ${actual.num}`);
      }
      return;
    case JsonKind.STRING:
      if (GOLDEN_NODE_ID.test(expected.str)) {
        compareNodeId(expected.str, actual.str, path, diff);
      } else if (expected.str !== actual.str) {
        diff.add(path, stringDifference(expected.str, actual.str));
      }
      return;
    case JsonKind.ARRAY:
      if (expected.items.length !== actual.items.length) {
        diff.add(path, `expected ${expected.items.length} items but was ${actual.items.length}: ` +
          `expected ${expected.describe()} but was ${actual.describe()}`);
        return;
      }
      for (let i = 0; i < expected.items.length; i++) {
        compareJson(expected.items[i], actual.items[i], `${path}[${i}]`, diff);
      }
      return;
    default:
      compareObject(expected, actual, path, diff);
  }
}

function compareObject(expected: JsonNode, actual: JsonNode, path: string, diff: GoldenDiff): void {
  const actualFields = new Map<string, JsonNode>();
  actual.fields.forEach((value: JsonNode, key: string) => {
    if (!ACTUAL_ONLY_KEYS.has(key)) {
      actualFields.set(KEY_RENAMES.get(key) ?? (key.startsWith('_') ? key.substring(1) : key), value);
    }
  });
  const keys = Array.from(expected.fields.keys()).sort();
  for (const key of keys) {
    const actualValue = actualFields.get(key);
    if (actualValue === undefined) {
      if (!EXPECTED_ONLY_KEYS.has(key)) {
        diff.add(`${path}.${key}`, `missing, expected ${expected.get(key)!.describe()}`);
      }
      continue;
    }
    const fallback = RESOLVED_FALLBACKS.get(key);
    const value = fallback !== undefined && actualValue.isNull() ? (actualFields.get(fallback) ?? actualValue) : actualValue;
    compareJson(expected.get(key)!, value, `${path}.${key}`, diff);
  }
  const extra = Array.from(actualFields.keys()).filter((k: string) => !expected.fields.has(k)).sort();
  for (const key of extra) {
    diff.add(`${path}.${key}`, `not a ROME property (value ${actualFields.get(key)!.describe()})`);
  }
}

function compareSet(expected: JsonNode, actual: JsonNode, path: string, diff: GoldenDiff): void {
  if (actual.kind !== JsonKind.ARRAY) {
    diff.add(path, `expected a set ${expected.describe()} but was ${actual.describe()}`);
    return;
  }
  const want = expected.items.map((n: JsonNode) => n.toJson()).sort();
  const got = actual.items.map((n: JsonNode) => n.toJson()).sort();
  if (want.join('\n') !== got.join('\n')) {
    diff.add(path, `expected set ${expected.describe()} but was ${actual.describe()}`);
  }
}

function compareNodeId(expected: string, actual: string, path: string, diff: GoldenDiff): void {
  const want = GOLDEN_NODE_ID.exec(expected)!;
  const got = NODE_ID.exec(actual);
  if (got === null || got[1] !== want[1]) {
    diff.add(path, `expected a ${want[1]} id like ${expected} but was ${JSON.stringify(actual)}`);
    return;
  }
  const mapped = diff.nodeIds.get(want[2]);
  const mappedBack = diff.nodeIdsBack.get(got[2]);
  if (mapped === undefined && mappedBack === undefined) {
    diff.nodeIds.set(want[2], got[2]);
    diff.nodeIdsBack.set(got[2], want[2]);
  } else if (mapped !== got[2] || mappedBack !== want[2]) {
    diff.add(path, `tree node id ${actual} does not map one to one onto ${expected}`);
  }
}

function isNullSingleton(node: JsonNode): boolean {
  return node.items.length === 1 && node.items[0].isNull();
}

function stringDifference(expected: string, actual: string): string {
  let i = 0;
  while (i < expected.length && i < actual.length && expected.charAt(i) === actual.charAt(i)) {
    i++;
  }
  const from = Math.max(0, i - 30);
  return `strings differ at ${i} (lengths ${expected.length}/${actual.length}): expected ` +
    `${JSON.stringify(expected.substring(from, i + 50))} but was ${JSON.stringify(actual.substring(from, i + 50))}`;
}
