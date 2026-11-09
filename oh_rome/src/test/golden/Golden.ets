// Golden harness driver: runs our port over a fixture the way tools/golden ran ROME, and compares with the golden.
import { expect } from '@ohos/hypium';
import { Content, Element } from '../../main/ets/xml/Dom';
import { DateParser } from '../../main/ets/io/impl/DateParser';
import { Format } from '../../main/ets/xml/Format';
import { XMLOutputter } from '../../main/ets/xml/XmlOutputter';
import { WireFeed } from '../../main/ets/feed/WireFeed';
import { SyndEntry } from '../../main/ets/feed/synd/SyndEntry';
import { SyndFeed } from '../../main/ets/feed/synd/SyndFeed';
import { SyndFeedInput } from '../../main/ets/io/SyndFeedInput';
import { WireFeedInput } from '../../main/ets/io/WireFeedInput';
import { WireFeedOutput } from '../../main/ets/io/WireFeedOutput';
import { PluginRegistry, usePluginRegistry } from '../../main/ets/io/impl/PluginRegistry';
import { registerCorePlugins, registerModulePlugins, registerOpmlPlugins } from '../../main/ets/io/impl/DefaultPlugins';
import { compareJson, GoldenDiff } from './Compare';
import { FIXTURES } from './Fixtures';
import { GoldenFixture } from './GoldenFixture';
import { JsonKind, JsonNode } from './Json';

export const PROFILES: string[] = ['core', 'opml', 'full'];

// Java runtime exceptions our port throws as a plain Error (CONTRIBUTING.md); any message is ROME's. IllegalArgumentException
// and its subclasses have classes of their own and must match by name.
const PLAIN_ERRORS: string[] = ['IllegalStateException', 'UnsupportedOperationException', 'RuntimeException'];
// Java exceptions ROME does not throw on purpose; any Error type matches, the golden carries no message.
const ANY_ERRORS: string[] = ['NullPointerException', 'ClassCastException', 'IndexOutOfBoundsException',
  'ArrayIndexOutOfBoundsException', 'StringIndexOutOfBoundsException'];

export function fixture(id: string): GoldenFixture {
  const found = FIXTURES.find((f: GoldenFixture) => f.id === id);
  if (found === undefined) {
    throw new Error(`Unknown golden fixture ${id}`);
  }
  return found;
}

export function fixtureIds(prefix: string = ''): string[] {
  return FIXTURES.filter((f: GoldenFixture) => f.id.startsWith(prefix)).map((f: GoldenFixture) => f.id);
}

// The plugins ROME had on its classpath for the profile, in rome.properties order.
export function profileRegistry(profile: string): PluginRegistry {
  if (!PROFILES.includes(profile)) {
    throw new Error(`Unknown golden profile ${profile}`);
  }
  const registry = new PluginRegistry();
  registerCorePlugins(registry);
  if (profile !== 'core') {
    registerOpmlPlugins(registry);
  }
  if (profile === 'full') {
    registerModulePlugins(registry);
  }
  return registry;
}

// Fails the current test with the list of differences.
export function assertGolden(id: string, profile: string, kind: string): void {
  expect(runGolden(id, profile, kind).lines.join('\n')).assertEqual('');
}

export function runGolden(id: string, profile: string, kind: string): GoldenDiff {
  return runGoldenOn(fixture(id), profile, kind);
}

// For harness tests that need a fixture of their own.
export function runGoldenOn(f: GoldenFixture, profile: string, kind: string): GoldenDiff {
  const id = f.id;
  const golden = f.golden(profile, kind);
  usePluginRegistry(profileRegistry(profile));
  // generate.sh runs ROME with -Duser.timezone=UTC: dates without a zone are UTC in the goldens.
  const timeZone = DateParser.getDefaultTimeZone();
  DateParser.setDefaultTimeZone('UTC');
  try {
    const diff = new GoldenDiff();
    compareOutcome(golden, evaluate(f.xml, kind), `${id} ${profile}/${kind}`, diff);
    return diff;
  } finally {
    DateParser.setDefaultTimeZone(timeZone);
    usePluginRegistry(null);
  }
}

// Our model as the golden format sees it: fields by name, Dates as ISO strings, JDOM content (elements, text,
// CDATA, ...) as raw XML, NaN and Infinity as the strings Java prints, the way BeanJson writes it.
// ROME's getModules() on SyndFeedImpl/SyndEntryImpl adds the DC module on first read, and the golden generator
// reads every bean through its getters; reading `modules` here has the same effect before the fields are written.
export function serialize(value: Object): JsonNode {
  const outputter = new XMLOutputter(Format.getRawFormat());
  const replacer = (key: string, v: Object | null): Object | null => {
    if (v instanceof SyndFeed) {
      (v as SyndFeed).modules;
    } else if (v instanceof SyndEntry) {
      (v as SyndEntry).modules;
    }
    if (typeof v === 'number' && !Number.isFinite(v as number)) {
      return String(v);
    }
    if (v instanceof Element) {
      return outputter.outputString(v);
    }
    return v instanceof Content ? outputter.outputString([v as Content]) : v;
  };
  return JsonNode.parse(JSON.stringify(value, replacer));
}

class Outcome {
  value: Object | null = null;
  error: Error | null = null;
}

function evaluate(xml: string, kind: string): Outcome {
  const outcome = new Outcome();
  const doctype = xml.includes('<!DOCTYPE');
  try {
    if (kind === 'wire') {
      outcome.value = readWire(xml, doctype);
    } else if (kind === 'wire.default') {
      outcome.value = readWire(xml, false);
    } else if (kind === 'synd') {
      outcome.value = readSynd(xml, doctype);
    } else if (kind === 'roundtrip.xml') {
      outcome.value = writeWire(readWire(xml, doctype));
    } else if (kind === 'roundtrip') {
      outcome.value = readWire(writeWire(readWire(xml, doctype)), true);
    } else if (kind.startsWith('convert.')) {
      outcome.value = readSynd(xml, doctype).createWireFeed(kind.substring('convert.'.length));
    } else {
      throw new Error(`Unknown golden kind ${kind}`);
    }
  } catch (e) {
    outcome.error = e as Error;
  }
  return outcome;
}

function compareOutcome(golden: JsonNode, outcome: Outcome, where: string, diff: GoldenDiff): void {
  const expectedException = golden.kind === JsonKind.OBJECT ? golden.get('$exception') : null;
  if (expectedException !== null) {
    const name = expectedException.str;
    const message = golden.get('message');
    if (outcome.error === null) {
      diff.add(where, `expected ${name}${message === null ? '' : `("${message.str}")`} but got a result`);
      return;
    }
    const e = outcome.error;
    const nameMatches = ANY_ERRORS.includes(name) ||
      (PLAIN_ERRORS.includes(name) ? e.name === 'Error' : e.name === name);
    if (!nameMatches) {
      diff.add(where, `expected ${name} but threw ${e.name}: ${e.message}`);
    } else if (message !== null && message.str !== e.message) {
      diff.add(where, `expected ${name}("${message.str}") but the message was "${e.message}"`);
    }
    return;
  }
  if (outcome.error !== null) {
    diff.add(where, `threw ${outcome.error.name}: ${outcome.error.message}\n${outcome.error.stack ?? ''}`);
    return;
  }
  const value = outcome.value!;
  compareJson(golden, typeof value === 'string' ? JsonNode.ofString(value as string) : serialize(value), '', diff);
}

// tools/golden reads every fixture through a fresh WireFeedInput/SyndFeedInput with allowDoctypes set as given.
function readWire(xml: string, allowDoctypes: boolean): WireFeed {
  const input = new WireFeedInput();
  input.allowDoctypes = allowDoctypes;
  return input.build(xml);
}

function readSynd(xml: string, allowDoctypes: boolean): SyndFeed {
  const input = new SyndFeedInput();
  input.allowDoctypes = allowDoctypes;
  return input.build(xml);
}

function writeWire(feed: WireFeed): string {
  return new WireFeedOutput().outputString(feed);
}
