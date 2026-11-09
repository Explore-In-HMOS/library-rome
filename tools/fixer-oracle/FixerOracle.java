// Runs ROME's own XmlFixerReader over tools/fixer-oracle/cases.txt, the inputs of TestXmlFixerReader and
// Issue1Test, generated long inputs and every ROME test fixture that contains '&', and writes
// oh_rome/src/test/XmlFixerCases.ets with each input and the text read from the fixer to the end.
// Usage (from the repo root, <rome> is a ROME clone at 6b4a7e8):
//   javac -d /tmp/fixer-oracle <rome>/rome/src/main/java/com/rometools/rome/io/impl/XmlFixerReader.java tools/fixer-oracle/FixerOracle.java
//   java -cp /tmp/fixer-oracle FixerOracle <rome>
import com.rometools.rome.io.impl.XmlFixerReader;
import java.io.Reader;
import java.io.StringReader;
import java.lang.reflect.Field;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Stream;

public class FixerOracle {
    static final int MAX_FIXTURE_CHARS = 40_000;
    static final String XML_PROLOG = "<?xml version=\"1.0\" ?>";

    static String fix(String s) throws Exception {
        Reader r = new XmlFixerReader(new StringReader(s));
        StringBuilder sb = new StringBuilder();
        char[] buf = new char[8192];
        int k;
        while ((k = r.read(buf, 0, buf.length)) != -1) sb.append(buf, 0, k);
        return sb.toString();
    }

    // ASCII-only string literal, so BOMs, line separators and surrogates survive any editor or encoding.
    static String q(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (c < 0x20 || c >= 0x7f) sb.append(String.format("\\u%04x", (int) c)); else sb.append(c);
            }
        }
        return sb.append('"').toString();
    }

    // {CR}, {TAB} and {U+XXXX} in cases.txt stand for characters that are awkward to write literally.
    static String unescape(String s) {
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("\\{U\\+([0-9A-F]+)\\}").matcher(s.replace("{CR}", "\r").replace("{TAB}", "\t"));
        StringBuilder sb = new StringBuilder();
        while (m.find()) m.appendReplacement(sb, java.util.regex.Matcher.quoteReplacement(new String(Character.toChars(Integer.parseInt(m.group(1), 16)))));
        m.appendTail(sb);
        return sb.toString();
    }

    static List<String[]> handWritten() throws Exception {
        List<String[]> cases = new ArrayList<>();
        List<String> lines = Files.readAllLines(Path.of("tools/fixer-oracle/cases.txt"), StandardCharsets.UTF_8);
        String name = null;
        StringBuilder body = new StringBuilder();
        for (int i = 0; i <= lines.size(); i++) {
            String line = i < lines.size() ? lines.get(i) : "### END";
            if (line.startsWith("### ")) {
                if (name != null) {
                    String in = body.toString();
                    if (in.endsWith("\n")) in = in.substring(0, in.length() - 1);
                    cases.add(new String[] {name, unescape(in)});
                }
                name = line.substring(4).trim();
                body.setLength(0);
            } else {
                body.append(line).append('\n');
            }
        }

        String[] trimGarbage = {"", " ", " \n", "<!-- - -- -->", " <!-- - -- -->", " <!-- - -- --> ",
            " <!-- - -- --> <!-- - -- --> ", " <!-- - -- --> \n <!-- - -- --> ", "\r\n<!-- hackedString Clean-->",
            "x", " x", " x\n", "<!-- - -- - ->", " <!-- - -- -- >", " <!-- - -- -->x ", " <!-- - -- --> x <!-- - -- --> ",
            " <!-- - -- --> x\n <!-- - -- --> "};
        for (String g : trimGarbage) {
            for (String doc : new String[] {"<hello></hello>", XML_PROLOG + "<hello></hello>"}) {
                cases.add(new String[] {"testTrim " + q(g) + " + " + q(doc), g + doc});
            }
        }
        String[] entityBodies = {"", "&apos;&yen;&#250;&yen;", "&Pi;&Rho;#913;&Rho;", "&Pi;&Rho;&#913;&Rho;",
            "&OElig;&mdash;&#8211;&mdash;", "&apos;&yexn;&#250;&yen;", "&Pi;&Rhox;#913;&Rho;", "&Pi;&Rhox;&#913;&Rho;",
            "&apos;&yen;&#2x50;&yen;", "&Pi;&Rho;&#9x13;&Rho;"};
        for (String b : entityBodies) {
            String doc = "<hello>" + b + "</hello>";
            for (String prefix : new String[] {"", XML_PROLOG, " <!-- just in case -->\n" + XML_PROLOG}) {
                cases.add(new String[] {"testHtmlEntities " + q(prefix + doc), prefix + doc});
            }
        }

        Field f = XmlFixerReader.class.getDeclaredField("CODED_ENTITIES");
        f.setAccessible(true);
        @SuppressWarnings("unchecked")
        Set<String> names = new TreeSet<>(((Map<String, String>) f.get(null)).keySet());
        String all = String.join(" ", names);
        cases.add(new String[] {"every coded entity (" + names.size() + ")", "<a>" + all + "</a>"});
        cases.add(new String[] {"every coded entity in cdata", "<a><![CDATA[" + all + "]]></a>"});
        cases.add(new String[] {"every coded entity without semicolon", "<a>" + all.replace(";", "") + "</a>"});

        cases.add(new String[] {"long entity name with semicolon", "<a>&" + "a".repeat(5000) + ";</a>"});
        cases.add(new String[] {"long entity name without semicolon", "<a>&" + "a".repeat(5000) + " </a>"});
        cases.add(new String[] {"long entity name at eof", "<a>&" + "a1#".repeat(2000)});
        cases.add(new String[] {"long tag name at eof", "<" + "x".repeat(5000) + "&"});
        cases.add(new String[] {"long bracket run in cdata", "<a><![CDATA[" + "]".repeat(3000) + "> & ]]> & </a>"});
        cases.add(new String[] {"many ampersands", "<a>" + "& &amp; &x ".repeat(1000) + "</a>"});
        return cases;
    }

    static List<String[]> fixtures(Path rome) throws Exception {
        List<String[]> cases = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        for (String dir : new String[] {"rome/src/test/resources", "rome-modules/src/test/resources"}) {
            List<Path> files;
            try (Stream<Path> s = Files.walk(rome.resolve(dir))) {
                files = s.filter(Files::isRegularFile).sorted().toList();
            }
            for (Path p : files) {
                String content = new String(Files.readAllBytes(p), StandardCharsets.UTF_8);
                String name = rome.relativize(p).toString();
                if (content.indexOf('&') == -1) continue;
                if (!seen.add(content)) {
                    System.out.println("skip duplicate " + name);
                } else if (content.length() > MAX_FIXTURE_CHARS) {
                    System.out.println("skip large " + name + " (" + content.length() + " chars)");
                } else {
                    cases.add(new String[] {name, content});
                }
            }
        }
        return cases;
    }

    static String entries(List<String[]> cases, boolean htmlEntities) throws Exception {
        XmlFixerReader fixer = new XmlFixerReader(new StringReader(""));
        List<String> out = new ArrayList<>();
        for (String[] c : cases) {
            String expected = htmlEntities ? fixer.processHtmlEntities(c[1]) : fix(c[1]);
            out.add("  c(" + q(c[0]) + ", " + q(c[1]) + ", " + q(expected) + ")");
        }
        return String.join(",\n", out);
    }

    public static void main(String[] args) throws Exception {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        List<String[]> hand = handWritten();
        List<String[]> all = new ArrayList<>(hand);
        all.addAll(fixtures(Path.of(args[0])));
        StringBuilder out = new StringBuilder();
        out.append("// Generated by tools/fixer-oracle/FixerOracle.java from tools/fixer-oracle/cases.txt and ROME's test fixtures. Do not edit.\n");
        out.append("export class XmlFixerCase {\n  name: string = '';\n  input: string = '';\n  expected: string = '';\n}\n\n");
        out.append("function c(name: string, input: string, expected: string): XmlFixerCase {\n");
        out.append("  const r = new XmlFixerCase();\n  r.name = name;\n  r.input = input;\n  r.expected = expected;\n  return r;\n}\n\n");
        out.append("export const XML_FIXER_CASES: XmlFixerCase[] = [\n").append(entries(all, false)).append("\n];\n\n");
        out.append("export const HTML_ENTITIES_CASES: XmlFixerCase[] = [\n").append(entries(hand, true)).append("\n];\n");
        Files.writeString(Path.of("oh_rome/src/test/XmlFixerCases.ets"), out.toString(), StandardCharsets.UTF_8);
        System.out.println(all.size() + " fixer cases, " + hand.size() + " processHtmlEntities cases");
    }
}
