package romeharmony.golden;

import com.rometools.rome.feed.WireFeed;
import com.rometools.rome.feed.impl.ConfigurableClassLoader;
import com.rometools.rome.feed.synd.SyndFeed;
import com.rometools.rome.io.SyndFeedInput;
import com.rometools.rome.io.WireFeedInput;
import com.rometools.rome.io.WireFeedOutput;
import com.rometools.rome.io.XmlReader;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Runs ROME over the fixture feeds and writes the goldens the ArkTS harness compares against.
 *
 * <pre>
 *   list &lt;romeDir&gt; &lt;repoDir&gt;          select fixtures (ROME's and repoDir/tools/golden/repo-fixtures), copy them to
 *                                      repoDir/fixtures, write fixtures/index.tsv
 *   dump &lt;profile&gt; &lt;repoDir&gt; &lt;outDir&gt; run every fixture of the profile, write outDir/&lt;profile&gt;.tsv
 *   emit &lt;repoDir&gt; &lt;outDir&gt;            write oh_rome/src/test/golden/fixtures/*.ets from the dumps
 * </pre>
 *
 * Run with -Duser.timezone=UTC -Duser.language=en -Duser.country=US (generate.sh does).
 */
public final class GoldenMain {

    static final List<String> OUT_OF_SCOPE_MODULES = List.of("base", "yahooweather", "feedburner", "photocast", "sle", "sse",
            "feedpress", "fyyd", "portablecontacts", "activitystreams");

    // Fixture origin -> (resources dir in ROME, profiles its goldens are produced for).
    static final Map<String, String> ORIGIN_DIRS = new LinkedHashMap<>();
    static final Map<String, List<String>> ORIGIN_PROFILES = new LinkedHashMap<>();

    // Feeds the repo owns (edge cases ROME's test feeds miss); listed after ROME's under the origin "repo".
    static final String REPO_FIXTURES = "tools/golden/repo-fixtures";

    static {
        ORIGIN_DIRS.put("rome", "rome/src/test/resources");
        ORIGIN_DIRS.put("opml", "rome-opml/src/test/resources");
        ORIGIN_DIRS.put("modules", "rome-modules/src/test/resources");
        ORIGIN_PROFILES.put("rome", List.of("core", "full"));
        ORIGIN_PROFILES.put("opml", List.of("opml"));
        ORIGIN_PROFILES.put("modules", List.of("full"));
        ORIGIN_PROFILES.put("repo", List.of("core", "full"));
    }

    // Module goldens and very large fixtures check conversion on one RSS and one Atom target only, to keep the
    // generated files small; every target type is still covered by the other core and opml fixtures.
    static final List<String> REDUCED_CONVERT_TYPES = List.of("rss_2.0", "atom_1.0");
    static final int LARGE_FIXTURE_CHARS = 100_000;

    private GoldenMain() {
    }

    public static void main(final String[] args) throws Exception {
        checkEnvironment();
        switch (args[0]) {
            case "list":
                list(Paths.get(args[1]), Paths.get(args[2]));
                break;
            case "dump":
                dump(args[1], Paths.get(args[2]), Paths.get(args[3]));
                break;
            case "emit":
                Emitter.emit(Paths.get(args[1]), Paths.get(args[2]));
                SelfTest.emit(Paths.get(args[1]));
                break;
            default:
                throw new IllegalArgumentException("unknown mode " + args[0]);
        }
    }

    static String jdkIdentity() {
        return (System.getProperty("java.vendor.version", "") + " " + System.getProperty("java.runtime.version")).trim();
    }

    private static void checkEnvironment() {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        if (!"UTC".equals(java.util.TimeZone.getDefault().getID()) || !"en_US".equals(java.util.Locale.getDefault().toString())) {
            throw new IllegalStateException("run with -Duser.timezone=UTC -Duser.language=en -Duser.country=US, got "
                    + java.util.TimeZone.getDefault().getID() + " " + java.util.Locale.getDefault());
        }
    }

    // ---- list -------------------------------------------------------------------------------------------------

    private static void list(final Path rome, final Path repo) throws IOException {
        final Map<String, Set<String>> referencedBy = testReferences(rome);
        final Path fixturesDir = repo.resolve("fixtures");
        final StringBuilder index = new StringBuilder();
        int excluded = 0;
        final Map<String, Path> bases = new LinkedHashMap<>();
        ORIGIN_DIRS.forEach((key, dir) -> bases.put(key, rome.resolve(dir)));
        bases.put("repo", repo.resolve(REPO_FIXTURES));
        for (final Map.Entry<String, Path> origin : bases.entrySet()) {
            final Path base = origin.getValue();
            final List<Path> files;
            try (Stream<Path> walk = Files.walk(base)) {
                files = walk.filter(Files::isRegularFile).filter(GoldenMain::isFeedFile).sorted().collect(Collectors.toList());
            }
            for (final Path f : files) {
                final String rel = base.relativize(f).toString().replace('\\', '/');
                final Set<String> users = referencedBy.getOrDefault(origin.getKey() + "/" + rel, Collections.emptySet());
                if (!users.isEmpty() && users.stream().allMatch(OUT_OF_SCOPE_MODULES::contains)) {
                    excluded++;
                    continue;
                }
                final String id = origin.getKey() + "/" + rel;
                final Path target = fixturesDir.resolve(id);
                Files.createDirectories(target.getParent());
                Files.copy(f, target, StandardCopyOption.REPLACE_EXISTING);
                index.append(id).append('\t').append(String.join(",", ORIGIN_PROFILES.get(origin.getKey()))).append('\n');
            }
        }
        Files.writeString(fixturesDir.resolve("index.tsv"), index.toString());
        System.out.println("fixtures: " + index.toString().split("\n").length + ", excluded (out-of-scope modules only): " + excluded);
    }

    private static boolean isFeedFile(final Path p) {
        final String n = p.getFileName().toString();
        return (n.endsWith(".xml") || n.endsWith(".rss")) && !n.equals("logback-test.xml");
    }

    // Fixture id -> names of the test groups whose sources mention it ("core", "opml" or the module name).
    private static Map<String, Set<String>> testReferences(final Path rome) throws IOException {
        final Map<String, Set<String>> result = new TreeMap<>();
        final Pattern literal = Pattern.compile("\"([^\"\\n]+)\"");
        final Map<String, String> testDirs = new LinkedHashMap<>();
        testDirs.put("rome", "rome/src/test/java");
        testDirs.put("opml", "rome-opml/src/test/java");
        testDirs.put("modules", "rome-modules/src/test/java");
        for (final Map.Entry<String, String> td : testDirs.entrySet()) {
            final Path resources = rome.resolve(ORIGIN_DIRS.get(td.getKey()));
            final List<String> fixtures;
            try (Stream<Path> walk = Files.walk(resources)) {
                fixtures = walk.filter(Files::isRegularFile).map(p -> resources.relativize(p).toString().replace('\\', '/'))
                        .collect(Collectors.toList());
            }
            final List<Path> sources;
            try (Stream<Path> walk = Files.walk(rome.resolve(td.getValue()))) {
                sources = walk.filter(p -> p.toString().endsWith(".java")).collect(Collectors.toList());
            }
            for (final Path src : sources) {
                final String group = testGroup(td.getKey(), src.toString().replace('\\', '/'));
                final Matcher m = literal.matcher(Files.readString(src));
                while (m.find()) {
                    String lit = m.group(1).replaceFirst("^src/test/resources/", "").replaceFirst("^/", "");
                    for (final String fx : fixtures) {
                        final String dir = lit.endsWith("/") ? lit : lit + "/";
                        if (fx.equals(lit) || fx.endsWith("/" + lit) || fx.startsWith(dir)) {
                            result.computeIfAbsent(td.getKey() + "/" + fx, k -> new TreeSet<>()).add(group);
                        }
                    }
                }
            }
        }
        return result;
    }

    private static String testGroup(final String origin, final String path) {
        if (!origin.equals("modules")) {
            return origin;
        }
        final Matcher m = Pattern.compile("/com/rometools/modules/([^/]+)/").matcher(path);
        return m.find() ? m.group(1) : "modules";
    }

    // ---- dump -------------------------------------------------------------------------------------------------

    private static void dump(final String profile, final Path repo, final Path out) throws Exception {
        final ClassLoader loader = ProfileLoader.create(profile, GoldenMain.class.getClassLoader());
        ConfigurableClassLoader.INSTANCE.setClassLoader(loader);
        Thread.currentThread().setContextClassLoader(loader);

        // One line per golden: fixture id, kind, JSON (the JSON writer escapes tabs and newlines).
        final StringBuilder tsv = new StringBuilder();
        int count = 0;
        for (final String line : Files.readAllLines(repo.resolve("fixtures/index.tsv"))) {
            final String[] cols = line.split("\t");
            if (!List.of(cols[1].split(",")).contains(profile)) {
                continue;
            }
            count++;
            final Map<String, Object> kinds;
            try {
                kinds = run(profile, fixtureText(repo.resolve("fixtures").resolve(cols[0])));
            } catch (final RuntimeException e) {
                throw new IllegalStateException("harness failed on " + cols[0] + " (" + profile + ")", e);
            }
            for (final Map.Entry<String, Object> kind : kinds.entrySet()) {
                tsv.append(cols[0]).append('\t').append(kind.getKey()).append('\t').append(Json.write(kind.getValue())).append('\n');
            }
        }
        Files.createDirectories(out);
        Files.writeString(out.resolve(profile + ".tsv"), tsv.toString());
        System.out.println(profile + ": " + count + " fixtures");
    }

    // The text both sides start from: ROME's own byte decoding (BOM, prolog, lenient fallback).
    static String fixtureText(final Path file) throws IOException {
        final byte[] bytes = Files.readAllBytes(file);
        try (Reader r = new XmlReader(new ByteArrayInputStream(bytes))) {
            final StringWriter w = new StringWriter();
            r.transferTo(w);
            return w.toString();
        }
    }

    /** A ROME call; only what it throws is a golden. Exceptions from serializing its result are harness bugs. */
    private interface RomeCall {
        Object call() throws Exception;
    }

    private static final class Result {
        final Object value;
        final Exception error;

        Result(final Object value, final Exception error) {
            this.value = value;
            this.error = error;
        }
    }

    private static Result rome(final RomeCall call) {
        try {
            return new Result(call.call(), null);
        } catch (final Exception e) {
            return new Result(null, e);
        }
    }

    private static Object golden(final BeanJson json, final Result r) {
        return r.error != null ? BeanJson.exception(r.error) : canonicalNodeIds(json.value(r.value), new HashMap<>());
    }

    // rome-opml names tree nodes "node." + Outline.hashCode() and refers to a parent as "parent." + the same hash
    // (ConverterForOPML10.java:150,161). The hash comes from a reflective toString() that differs from run to run,
    // so only which categories share a hash is behavior: hashes are numbered by first appearance ("node.#1",
    // "parent.#1"), and golden/Compare.ets checks that ours map onto them one to one.
    private static final Pattern NODE_ID = Pattern.compile("(node|parent)\\.(-?\\d+)");

    @SuppressWarnings("unchecked")
    static Object canonicalNodeIds(final Object v, final Map<String, String> ids) {
        if (v instanceof String) {
            final Matcher m = NODE_ID.matcher((String) v);
            return m.matches() ? m.group(1) + "." + ids.computeIfAbsent(m.group(2), k -> "#" + (ids.size() + 1)) : v;
        }
        if (v instanceof List<?>) {
            final List<Object> out = new ArrayList<>();
            for (final Object o : (List<Object>) v) {
                out.add(canonicalNodeIds(o, ids));
            }
            return out;
        }
        if (v instanceof Map<?, ?>) {
            final Map<String, Object> out = new TreeMap<>();
            for (final Map.Entry<String, Object> e : ((Map<String, Object>) v).entrySet()) {
                out.put(e.getKey(), canonicalNodeIds(e.getValue(), ids));
            }
            return out;
        }
        return v;
    }

    private static Map<String, Object> run(final String profile, final String text) {
        final Map<String, Object> kinds = new TreeMap<>();
        final boolean doctype = text.contains("<!DOCTYPE");
        final BeanJson json = new BeanJson();

        final Result wire = rome(() -> {
            final WireFeedInput in = new WireFeedInput();
            in.setAllowDoctypes(doctype);
            return in.build(new StringReader(text));
        });
        kinds.put("wire", golden(json, wire));
        if (doctype) {
            kinds.put("wire.default", golden(json, rome(() -> new WireFeedInput().build(new StringReader(text)))));
        }

        if (wire.error == null) {
            final Result xml = rome(() -> new WireFeedOutput().outputString((WireFeed) wire.value));
            kinds.put("roundtrip.xml", golden(json, xml));
            if (xml.error == null) {
                kinds.put("roundtrip", golden(json, rome(() -> {
                    final WireFeedInput in = new WireFeedInput();
                    in.setAllowDoctypes(true);
                    return in.build(new StringReader((String) xml.value));
                })));
            }
        }

        final Result synd = rome(() -> {
            final SyndFeedInput in = new SyndFeedInput();
            in.setAllowDoctypes(doctype);
            return in.build(new StringReader(text));
        });
        kinds.put("synd", golden(json, synd));
        if (synd.error == null) {
            final SyndFeed feed = (SyndFeed) synd.value;
            for (final String type : new TreeSet<>(feed.getSupportedFeedTypes())) {
                if ((profile.equals("full") || text.length() > LARGE_FIXTURE_CHARS) && !REDUCED_CONVERT_TYPES.contains(type)) {
                    continue;
                }
                kinds.put("convert." + type, golden(json, rome(() -> feed.createWireFeed(type))));
            }
        }
        return kinds;
    }

    // ---- profiles ---------------------------------------------------------------------------------------------

    /** Hides the rome.properties files a profile must not see; for "full" serves rome-modules' file without out-of-scope modules. */
    static final class ProfileLoader extends ClassLoader {
        private final List<URL> extraProperties;

        private ProfileLoader(final ClassLoader parent, final List<URL> extraProperties) {
            super(parent);
            this.extraProperties = extraProperties;
        }

        static ClassLoader create(final String profile, final ClassLoader parent) throws IOException {
            final List<URL> extras = new ArrayList<>();
            for (final URL u : Collections.list(parent.getResources("rome.properties"))) {
                final String s = u.toString();
                if (s.contains("rome-opml")) {
                    if (!profile.equals("core")) {
                        extras.add(u);
                    }
                } else if (s.contains("rome-modules")) {
                    if (profile.equals("full")) {
                        extras.add(filtered(u));
                    }
                } else {
                    throw new IllegalStateException("unexpected rome.properties on the classpath: " + s);
                }
            }
            if (!List.of("core", "opml", "full").contains(profile)) {
                throw new IllegalArgumentException("unknown profile " + profile);
            }
            return new ProfileLoader(parent, extras);
        }

        private static URL filtered(final URL modulesProperties) throws IOException {
            final Properties in = new Properties();
            try (InputStream s = modulesProperties.openStream()) {
                in.load(s);
            }
            final StringBuilder out = new StringBuilder();
            for (final String key : new TreeSet<>(in.stringPropertyNames())) {
                final List<String> kept = new ArrayList<>();
                for (final String cls : in.getProperty(key).trim().split("[\\s,]+")) {
                    final Matcher m = Pattern.compile("^com\\.rometools\\.modules\\.([^.]+)\\.").matcher(cls);
                    if (!(m.find() && OUT_OF_SCOPE_MODULES.contains(m.group(1)))) {
                        kept.add(cls);
                    }
                }
                if (!kept.isEmpty()) {
                    out.append(key).append('=').append(String.join(" ", kept)).append('\n');
                }
            }
            final Path tmp = Files.createTempFile("rome-modules-in-scope", ".properties");
            tmp.toFile().deleteOnExit();
            Files.writeString(tmp, out.toString(), StandardCharsets.ISO_8859_1);
            return tmp.toUri().toURL();
        }

        @Override
        public Enumeration<URL> getResources(final String name) throws IOException {
            return name.equals("rome.properties") ? Collections.enumeration(extraProperties) : super.getResources(name);
        }

        @Override
        public URL getResource(final String name) {
            if (name.equals("rome.properties")) {
                return extraProperties.isEmpty() ? null : extraProperties.get(0);
            }
            return super.getResource(name);
        }
    }
}
