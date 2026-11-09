// Runs ROME's DateParser, Base64 and NumberParser over a cases file written by gen_cases.py and writes one
// result per line, in the format arkts_runner.js writes for the ArkTS port. Refuses to run on anything but
// Temurin 17.0.17+10 unless -Doracle.allowOtherJdk=true (only for comparing JDKs). run.sh drives it:
//   tools/dateparser-oracle/run.sh <rome checkout at 6b4a7e8> [<work dir>]
// RomeOracle --zone-cutoffs <output file> instead writes, for every name DateParserZoneNames.ets can match,
// "name<TAB>cutoff ms": the instant after which the offset Java applies for that name equals its current one
// (raw offset, or total offset when the zone's own rules decide; scanned in 15-day steps), so compare.py can
// excuse a zone mismatch only before it, plus "@default<TAB>ms": the end of local mean time in the default zone.
// By hand (from the repo root, <rome> is the ROME checkout, <tz> the default zone):
//   javac -d <classes> <rome>/rome/src/main/java/com/rometools/rome/io/impl/{DateParser,PropertiesLoader,Base64,NumberParser}.java \
//     <rome>/rome/src/main/java/com/rometools/rome/feed/impl/ConfigurableClassLoader.java tools/dateparser-oracle/RomeOracle.java
//   java -Duser.timezone=<tz> -Duser.language=en -Duser.country=US -cp <classes>:<rome>/rome/src/main/resources \
//     RomeOracle <cases file> <output file>
import com.rometools.rome.io.impl.Base64;
import com.rometools.rome.io.impl.DateParser;
import com.rometools.rome.io.impl.NumberParser;
import java.io.PrintStream;
import java.lang.reflect.Field;
import java.text.DateFormatSymbols;
import java.time.Instant;
import java.time.ZoneId;
import java.time.zone.ZoneOffsetTransition;
import java.util.ArrayList;
import java.util.List;
import java.util.TimeZone;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Date;
import java.util.Locale;

public class RomeOracle {

    // Cases and results escape \, tab, CR, LF and every char outside printable ASCII as \\uXXXX.
    static String unescape(String s) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '\\' && s.charAt(i + 1) == 'u') {
                b.append((char) Integer.parseInt(s.substring(i + 2, i + 6), 16));
                i += 5;
            } else {
                b.append(c);
            }
        }
        return b.toString();
    }

    static String escape(String s) {
        StringBuilder b = new StringBuilder();
        for (char c : s.toCharArray()) {
            if (c < 0x20 || c > 0x7e || c == '\\') b.append(String.format("\\u%04x", (int) c));
            else b.append(c);
        }
        return b.toString();
    }

    static String run(Field masks, String kind, String arg, String input) throws Exception {
        switch (kind) {
            case "P": case "W": case "R": {
                masks.set(null, arg.isEmpty() ? new String[0] : arg.split("\\|"));
                Date d = kind.equals("P") ? DateParser.parseDate(input, Locale.US)
                        : kind.equals("W") ? DateParser.parseW3CDateTime(input, Locale.US) : DateParser.parseRFC822(input, Locale.US);
                return d == null ? "null" : String.valueOf(d.getTime());
            }
            case "F": {
                Date d = new Date(Long.parseLong(input));
                return DateParser.formatRFC822(d, Locale.US) + " / " + DateParser.formatW3CDateTime(d, Locale.US);
            }
            case "B64D": return escape(Base64.decode(input));
            case "B64E": return escape(Base64.encode(input));
            case "LONG": return String.valueOf(NumberParser.parseLong(input));
            case "INT": return String.valueOf(NumberParser.parseInt(input));
            case "FLOAT": {
                Float f = NumberParser.parseFloat(input);
                return f == null ? "null" : String.format("%08x", Float.floatToRawIntBits(f));
            }
            default: throw new IllegalArgumentException(kind);
        }
    }

    static final long STEP = 15L * 24 * 3600 * 1000;
    static final long SCAN_FROM = -5364662400000L; // 1800-01-01

    // The offset SimpleDateFormat applies at t for a zone name: the zone's raw offset, or its total offset when
    // the zone's own rules decide. The port always applies the current one; the cutoff is the end of the last
    // 15-day step (scanning back from now to 1800) where Java's offset differs from it, Long.MIN_VALUE if none.
    static long cutoff(String id, boolean decides) {
        TimeZone tz = TimeZone.getTimeZone(id);
        java.util.GregorianCalendar cal = new java.util.GregorianCalendar(tz);
        long now = System.currentTimeMillis();
        int current = tz.getRawOffset();
        for (long t = now; t >= SCAN_FROM; t -= STEP) {
            cal.setTimeInMillis(t);
            int offset = decides ? tz.getOffset(t) : cal.get(java.util.Calendar.ZONE_OFFSET);
            if (offset != current) {
                return Math.min(now, t + STEP);
            }
        }
        cal.setTimeInMillis(SCAN_FROM - 1);
        int early = decides ? tz.getOffset(SCAN_FROM - 1) : cal.get(java.util.Calendar.ZONE_OFFSET);
        return early != current ? SCAN_FROM : Long.MIN_VALUE;
    }

    static void zoneCutoffs(String out) throws Exception {
        List<String> seen = new ArrayList<>();
        try (PrintStream p = new PrintStream(Files.newOutputStream(Paths.get(out)), true, "UTF-8")) {
            for (String[] r : DateFormatSymbols.getInstance(Locale.US).getZoneStrings()) {
                int dst = TimeZone.getTimeZone(r[0]).getDSTSavings();
                for (int i = 1; i <= 4; i++) {
                    String lower = r[i].toLowerCase(Locale.ROOT);
                    if (seen.stream().anyMatch(lower::startsWith)) continue;
                    seen.add(lower);
                    boolean decides = (i <= 2 && r[i].equalsIgnoreCase(r[i + 2])) || (i >= 3 && dst == 0);
                    p.println(escape(r[i]) + "\t" + cutoff(r[0], decides));
                }
            }
            List<ZoneOffsetTransition> transitions = ZoneId.systemDefault().getRules().getTransitions();
            p.println("@default\t" + (transitions.isEmpty() ? Long.MIN_VALUE : transitions.get(0).getInstant().toEpochMilli()));
        }
    }

    public static void main(String[] a) throws Exception {
        String version = System.getProperty("java.runtime.version");
        if ((!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version")))
                && !Boolean.getBoolean("oracle.allowOtherJdk")) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        if (a[0].equals("--zone-cutoffs")) {
            zoneCutoffs(a[1]);
            return;
        }
        Field masks = DateParser.class.getDeclaredField("ADDITIONAL_MASKS");
        masks.setAccessible(true);
        try (PrintStream out = new PrintStream(Files.newOutputStream(Paths.get(a[1])), true, "UTF-8")) {
            for (String line : Files.readAllLines(Paths.get(a[0]), StandardCharsets.UTF_8)) {
                String[] p = line.split("\t", -1);
                String result;
                try {
                    result = run(masks, p[0], unescape(p[1]), unescape(p[2]));
                } catch (Exception e) {
                    result = "EXC " + escape(String.valueOf(e.getMessage()));
                }
                out.println(result);
            }
        }
    }
}
