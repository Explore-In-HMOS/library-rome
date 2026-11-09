// Runs the JDK over inputs.txt and writes oh_rome/src/test/JdkCases.ets: for every input, the result of
// new URL(s), new URI(s), URIs.parse(s), new BigDecimal(s) and Currency.getInstance(s), or the exception class
// (with the message for Currency).
// Usage (from the repo root, with the JDK 17 the goldens use): java tools/jdk-oracle/JdkOracle.java
import java.math.BigDecimal;
import java.net.URI;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Currency;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.concurrent.Callable;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class JdkOracle {
    // Same escaping as JSON.stringify, plus \\u escapes for everything outside printable ASCII.
    static String q(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            if (c == '"') sb.append("\\\"");
            else if (c == '\\') sb.append("\\\\");
            else if (c < 0x20 || c > 0x7e) sb.append(String.format("\\u%04x", (int) c));
            else sb.append(c);
        }
        return sb.append('"').toString();
    }

    static String run(Callable<String> f) {
        try {
            return f.call();
        } catch (Exception e) {
            return e.getClass().getSimpleName();
        }
    }

    static String currency(String s) {
        try {
            return Currency.getInstance(s).getCurrencyCode();
        } catch (IllegalArgumentException e) {
            return "IllegalArgumentException: " + e.getMessage();
        }
    }

    @SuppressWarnings("deprecation")
    static String url(String s) throws Exception {
        URL u = new URL(s);
        if (!u.toString().equals(u.toExternalForm())) throw new IllegalStateException(s);
        return u.getProtocol() + " " + u.getHost() + " " + u.getPort() + " " + u.getDefaultPort() + " " + u;
    }

    // MediaModuleParser.parseFileSize: number.multiply(BigDecimal.valueOf(1000).pow(k)).longValue()
    static String bigDecimal(String s) {
        BigDecimal d = new BigDecimal(s);
        StringBuilder sb = new StringBuilder(d.toString());
        for (int k = 0; k <= 4; k++) sb.append(' ').append(d.multiply(BigDecimal.valueOf(1000).pow(k)).longValue());
        return sb.toString();
    }

    static String unescape(String s) {
        if (s.equals("{EMPTY}")) return "";
        Matcher m = Pattern.compile("\\{U\\+([0-9A-F]{4})\\}")
            .matcher(s.replace("{TAB}", "\t").replace("{CR}", "\r").replace("{LF}", "\n"));
        StringBuilder sb = new StringBuilder();
        while (m.find()) m.appendReplacement(sb, Matcher.quoteReplacement(String.valueOf((char) Integer.parseInt(m.group(1), 16))));
        m.appendTail(sb);
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        Set<String> available = new TreeSet<>();
        for (Currency c : Currency.getAvailableCurrencies()) available.add(c.getCurrencyCode());
        for (char a = 'A'; a <= 'Z'; a++) for (char b = 'A'; b <= 'Z'; b++) for (char c = 'A'; c <= 'Z'; c++) {
            String code = "" + a + b + c;
            if (!currency(code).equals(available.contains(code) ? code : "IllegalArgumentException: The input currency code: \"" + code + "\" is not a valid ISO 4217 code"))
                throw new IllegalStateException("Currency.getInstance disagrees with getAvailableCurrencies: " + code);
        }
        System.out.println("CURRENCY_CODES = '" + String.join(" ", available) + "'");

        Set<String> inputs = new LinkedHashSet<>();
        for (String line : Files.readAllLines(Path.of("tools/jdk-oracle/inputs.txt"), StandardCharsets.UTF_8)) {
            if (!line.isEmpty() && !line.startsWith("# ")) inputs.add(unescape(line));
        }
        inputs.addAll(available);
        // Each block of Unicode decimal digits: its 0 and 9, and the characters just outside it.
        for (char c = 0; c < 0xffff; c++) {
            if (Character.digit(c, 10) == 0) {
                inputs.add("" + (char) (c - 1) + c);
                inputs.add("" + (char) (c + 9) + (char) (c + 10));
            }
        }

        List<String> entries = new ArrayList<>();
        for (String s : inputs) {
            String uri = run(() -> new URI(s).toString());
            String uris = run(() -> new URI(s.replace(" ", "%20")).toString());
            entries.add("  c(" + q(s) + ", " + q(run(() -> url(s))) + ", " + q(uri) + ", " + q(uris) + ",\n    "
                + q(run(() -> bigDecimal(s))) + ", " + q(currency(s)) + ")");
        }
        String out = "// Generated by tools/jdk-oracle/JdkOracle.java from tools/jdk-oracle/inputs.txt on JDK "
            + System.getProperty("java.version") + ". Do not edit.\n"
            + "export class JdkCase {\n  input: string = '';\n  url: string = '';\n  uri: string = '';\n  urisParse: string = '';\n"
            + "  bigDecimal: string = '';\n  currency: string = '';\n}\n\n"
            + "function c(input: string, url: string, uri: string, urisParse: string, bigDecimal: string, currency: string): JdkCase {\n"
            + "  const r = new JdkCase();\n  r.input = input;\n  r.url = url;\n  r.uri = uri;\n  r.urisParse = urisParse;\n"
            + "  r.bigDecimal = bigDecimal;\n  r.currency = currency;\n  return r;\n}\n\n"
            + "export const JDK_CASES: JdkCase[] = [\n" + String.join(",\n", entries) + "\n];\n";
        Files.writeString(Path.of("oh_rome/src/test/JdkCases.ets"), out, StandardCharsets.UTF_8);
        System.out.println(entries.size() + " cases");
    }
}
