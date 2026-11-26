# Contributing to oh_rome

ArkTS port of [ROME](https://github.com/rometools/rome) (Java RSS/Atom/OPML library) for HarmonyOS, shipped
to OHPM as `@explore-in-hmos/oh_rome` (the HAR module `oh_rome`). The `entry` module is the library's sample app.

Changes keep the port faithful to ROME.

## Source of truth

- ROME at commit `6b4a7e8` (2023-06-21, the latest master). Clone it outside this repo:
  `git clone https://github.com/rometools/rome && git -C rome checkout 6b4a7e8`
- Port behavior, not Java shape. Behavior changes are backed by ROME's code or a run of ROME.
- Faithful means the same output for the same input: same parsed values, same defaults, same error messages.

## Scope

- In: `rome` (every feed format: RSS 0.90-2.0, RSS 1.0, Atom 0.3/1.0, parsers, generators, converters),
  `rome-utils`, `rome-opml`, and these `rome-modules`: content, itunes, mediarss, atom, thr, georss,
  opensearch, cc, slash, psc.
- Out: modules base, yahooweather, feedburner, photocast, sle, sse, feedpress, fyyd, portablecontacts (dead
  services); activitystreams (model classes only, ROME registers no parser or generator for it);
  `DelegatingModuleParser`/`DelegatingModuleGenerator` (only sse used them); HTTP fetching (ROME has none
  either; callers pass a string or bytes).

## Layout

`oh_rome/src/main/ets` mirrors the Java packages:

| Java | ArkTS |
|---|---|
| `rome/.../com/rometools/rome/<path>/X.java` | `<path>/X.ets` (e.g. `io/impl/RSS20Parser.ets`) |
| `rome-utils/.../com/rometools/utils/X.java` | `utils/X.ets` |
| `rome-opml/.../com/rometools/opml/<path>/X.java` | `opml/<path>/X.ets` |
| `rome-modules/.../com/rometools/modules/<m>/<path>/X.java` | `modules/<m>/<path>/X.ets` |
| `org.jdom2.*` | `xml/Dom.ets` |

- One ArkTS file per Java file. An interface and its `Impl` merge into one file named after the interface.
- First line of every ported file: `// Ported from ROME <path of the Java file(s)> (Apache-2.0)`. This is the
  Apache-2.0 change notice; do not drop it.
- Export everything public from `oh_rome/Index.ets`.
- Tests: `oh_rome/src/test/<Name>.test.ets`, registered in `oh_rome/src/test/List.test.ets`.

## Java to ArkTS rules

| Java | ArkTS |
|---|---|
| Plain getter/setter pair (`getFoo`/`setFoo`, `isFoo`) | Public field named `foo` |
| Getter/setter with logic (delegation, defaults) | `get foo()`/`set foo()` over a private field |
| `Lists.createWhenNull` getters | Field initialized to `[]` |
| Other object fields | `T \| null`, initialized to `null` |
| `int`/`long`/`double` and boxed versions | `number` (`number \| null` for boxed) |
| `java.util.Date` | `Date` |
| Interface + `Impl` (`SyndFeed` + `SyndFeedImpl`) | One class named after the interface |
| Interface with several implementations (`Module`, parsers, generators, `Converter`) | Keep the interface |
| `equals`/`hashCode`/`toString` through reflection beans | Not ported unless ROME code (not tests) calls them |
| `clone`/`copyFrom` | Written by hand where ROME code calls them. `Module.clone()` is required: converters clone modules |
| `Locale` and `validate` parameters | Dropped. `validate` is a no-op in ROME; dates use English names, as ROME's default `Locale.US` |
| `IllegalArgumentException` and its subclasses (`NumberFormatException`, JDOM's `Illegal*Exception`) | The class of the same name from `utils/Exceptions.ets` / `xml/Verifier.ets`, same message (`WireFeedInput.build` rethrows these raw) |
| Other runtime exceptions | `throw new Error(<ROME's message>)` |
| `FeedException`, `ParsingFeedException` | `io/FeedException.ets` |
| `Serializable`, `Cloneable`, slf4j logging | Dropped |
| `PluginManager` + `rome.properties` | `io/impl/PluginRegistry.ets` (see below) |

Keep Java property names exactly, including odd ones (`titleEx`, `rightsList`, `styleSheet`). Golden tests
compare our models to ROME's by these names.

### XML (`xml/Dom.ets`)

Same class and method names as JDOM, so ported code reads like the Java. Differences:

- `addContent(int, Content)` is `addContentAt(index, content)`.
- `removeContent(child)` returns the removed nodes (`[child]` or `[]`) instead of a boolean.
- `getChild(name)`, `getChildren(name)`, `getAttribute(name)` without a namespace match only `NO_NAMESPACE`,
  exactly like JDOM. ROME depends on this.
- `Namespace.equals` compares URIs only, like JDOM.
- No `XMLOutputter`/`SAXBuilder` here: the XML parser and writer live in their own files in `xml/`.

### Plugins (`io/impl/PluginRegistry.ets`)

- `plugins()` returns the registry: feed parsers, feed generators, converters, module parsers and generators.
- Built-ins are registered in `io/impl/DefaultPlugins.ets`, in `rome.properties` order. Order matters: feed
  parsers are tried in order, module parsers run in order. Re-registering a type or namespace replaces the
  earlier plugin, like a later `rome.properties` entry.
- Insert each registration at its position in the `rome.properties` it comes from (core, then `rome-opml`,
  then `rome-modules`), in every scope it appears in. Never just append: module parse/generate order shows up in the
  goldens.
- Module scopes are `"<feedType>.feed"`, `"<feedType>.item"`, `"<feedType>.person"`, e.g. `"rss_2.0.item"`.

### Import cycles crash at load time

`class A extends B` fails with `ReferenceError: B is not initialized` when B's file is part of an import cycle
with A's file that is entered from B's side. The whole test bundle then fails to load and no test runs.
That is why `PluginRegistry.ets` must not import `DefaultPlugins.ets`: `DefaultPlugins.ets` registers itself
via `setDefaultPlugins` and is imported only by `Index.ets` and `List.test.ets`. Rules:

- Plugin constructors must not call `plugins()`.
- Before adding an import to a base class's file, check that it cannot lead back to a subclass.

## Build and test

- `./scripts/check.sh` builds the HAR and the sample app and runs both modules' local unit tests. It is the only trustworthy pass/fail
  signal: hvigor exits 0 and prints `BUILD SUCCESSFUL` even when tests fail or the test bundle crashes.
- Local tests run on the computer, without a device, in about a minute. System APIs (`@ohos.*`, `@kit.*`:
  `xml.XmlPullParser`, `util.TextDecoder`, `fileIo`, ...) are mocked there and silently return nothing.
  Keep the library pure ArkTS. The only system API use is decoding bytes to a string
  (`util.TextDecoder`); it is tested with instrument tests on a device (`oh_rome/src/ohosTest`).
- Local tests cannot read files, so test fixtures are embedded as generated `.ets` string constants.
- Use `/usr/bin/diff`: the `diff` DevEco puts on PATH rejects most options, prints nothing and exits 0.
- Oracles and the golden generator run on Temurin 17.0.17+10, because URL, Currency, charset and zone data differ
  between JDKs.

## Golden tests

ROME's own output is the expected output. `tools/golden/generate.sh` runs ROME `6b4a7e8` over every fixture
feed in `fixtures/` (list: `fixtures/index.tsv`) and generates `oh_rome/src/test/golden/fixtures/*.ets` (fixture
text plus its goldens) and `golden/Fixtures.ets`. Generated files are committed and never
edited by hand: regenerate instead (needs Temurin 17.0.17+10, see the script).

- `AllFixtures.test.ets`, first in `List.test.ets`, runs every golden of every fixture. Suites add goldens for clearer
  failures, not for coverage.
- Use `assertGolden(fixtureId, profile, kind)` from `oh_rome/src/test/golden/Golden.ets`, e.g.
  `assertGolden('rome/rss_2.0.xml', 'core', 'wire')`. Fixture ids are `rome/<file>`, `opml/<file>`,
  `modules/<path>` and `repo/<path>`: feeds the repo owns (edge cases ROME's test feeds miss), kept in
  `tools/golden/repo-fixtures/` because `fixtures/` is rebuilt on every run; they get `core` and `full` goldens.
- Profiles: `core` (core plugins only), `opml` (core + rome-opml), `full` (core + rome-opml + in-scope modules).
  The harness builds a registry with `registerCorePlugins`/`registerOpmlPlugins`/`registerModulePlugins` for
  each profile, so core behavior is tested without modules.
- Kinds: `wire` (WireFeedInput, healer on), `wire.default` (fixtures with a DOCTYPE, default config: rejected),
  `synd` (SyndFeedInput), `roundtrip.xml` (the WireFeedOutput string), `roundtrip` (that string parsed again),
  `convert.<type>` (`createWireFeed(type)` on the synd feed), including RSS↔Atom conversions.
- Format: Java bean properties read through getters; our side is `JSON.stringify` of the model, which emits
  fields only. So every Java property must be a field with the Java name, or a private field `_<name>` behind
  an accessor `<name>`. Other mismatches go in the lists at the top of `golden/Compare.ets`, with the reason in
  the PR. Dates are ISO strings, XML elements raw XML; `URL`/`URI`/`BigDecimal` and type-safe-enum classes
  (mediarss `Expression`, `Restriction.Relationship`/`Type`) their `toString()`, `Currency` its code, enums their
  name. Exceptions compare the class (`IllegalArgumentException` and its subclasses by name, a plain `Error` for
  other Java runtime exceptions) and ROME's own message; XML parser messages are not compared.

## Workflow

- One topic per pull request. `List.test.ets` is append-only; `DefaultPlugins.ets` registrations go at their
  `rome.properties` position (see Plugins).
- A change is done when its behavior is covered by tests (golden tests and/or ported ROME unit tests),
  `./scripts/check.sh` passes, and there are no ArkTS warnings.
- No deprecated APIs.

## ArkTS notes

- ArkTS is stricter than TypeScript: no `any`/`unknown`, no structural typing, object literals need a declared
  type, no indexed access on class instances, no `for..in`.
- `JSON.stringify` works on class instances: it emits own fields in declaration order (private fields
  included, accessors excluded) and `Date` as an ISO UTC string.
