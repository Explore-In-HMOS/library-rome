// Runs ROME's own Integers.parse, Longs.parseDecimal and Doubles.parse over the inputs below and writes
// oh_rome/src/test/NumberCases.ets with each input and the three results as String.valueOf (or "null").
// Usage (from the repo root, <rome> is a ROME clone at 6b4a7e8, with the JDK 17 the goldens use):
//   javac -d /tmp/base-oracle <rome>/rome-utils/src/main/java/com/rometools/utils/{Integers,Longs,Doubles}.java tools/base-oracle/NumbersOracle.java
//   java -cp /tmp/base-oracle NumbersOracle
import com.rometools.utils.Doubles;
import com.rometools.utils.Integers;
import com.rometools.utils.Longs;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

public class NumbersOracle {
    static final String[] INPUTS = {
        // Plain, signs, zeros
        "", " ", "0", "-0", "+0", "00", "007", "-007", "1", "-1", "+1", "42", "-7", "+", "-", "++1", "+-1", "-+1", "--1",
        "1-", "1+", "+-0", "0.", ".0", ".", "-.", "+.", "-.5", "+.5", "1.5", "-1.5", "12.9", "-12.9", "0.5", "-0.5",
        "0.9999999", "-0.9999999", "-0.0", "+0.0", "1.1.1", "1,5", "1_000", "1 2", "0b101", "017", "abc", "12abc", "4.2",
        // Whitespace: Java trim() strips U+0000..U+0020 only
        " 42", "42 ", " 42 ", "\t1\n", "\r\n1.5\r\n", "\u00001\u0000", "\u001f1\u001f", "\u000b1", "\u000c1", " 1",
        "1 ", " 1", "　1", "﻿1", "\u00851", " 1", "- 1", "1 .5",
        // Unicode digits that Character.digit accepts and Double.parseDouble does not
        "١٢", "-١٢", "+١٢", "٠", "۱۲", "१२", "１２",
        "－１", "1٢", "١.٥", "1e٢", "²", "③", "Ⅻ", "𝟎",
        "𝟏𝟐", "١٢٣٤٥٦٧٨٩٠",
        "٢١٤٧٤٨٣٦٤٧", "٢١٤٧٤٨٣٦٤٨",
        "-٢١٤٧٤٨٣٦٤٨", "-٢١٤٧٤٨٣٦٤٩",
        // int and long edges
        "2147483647", "2147483648", "-2147483648", "-2147483649", "+2147483647", "0000000000000000002147483647",
        "-0000000000000000002147483648", "4294967296", "99999999999", "9007199254740991", "9007199254740992",
        "9007199254740993", "-9007199254740993", "123456789012345678", "9223372036854775807", "9223372036854775808",
        "-9223372036854775808", "-9223372036854775809", "9223372036854775807.5", "1e18", "1e19", "-1e19", "9.3e18",
        "-9.3e18", "1e300", "-1e300",
        // Exponents
        "1e10", "1E10", "1e+10", "1e-10", "1e", "1E", "1e+", "1e-", "e5", "E5", ".e5", "1.e5", ".5e5", "1e5.5",
        "1e05", "1ee5", "1e+-5", "1e5f", "1e5 f", "1.5E-3D", "1e2147483647", "1e2147483648", "1e-2147483648",
        "1e-2147483649", "1e99999999999", "1e-99999999999", "0e99999999999", "0.0000000000000000000000000001e28",
        "1e214748364f", "-1e400", "1e-400", "-1e-400",
        // Double edges and rounding
        "1.7976931348623157e308", "1.7976931348623158e308", "1.7976931348623159e308", "4.9e-324", "4.9E-324",
        "2.4703282292062327e-324", "2.4703282292062328e-324", "2.2250738585072011e-308", "2.2250738585072012e-308",
        "0.1", "0.2", "0.3", "3.141592653589793", "1.00000000000000011102230246251565404236316680908203125",
        "1.00000000000000011102230246251565404236316680908203125" + "0".repeat(1200) + "1",
        "1.0000000000000002220446049250313080847263336181640625", "123456789012345678901234567890",
        "0." + "0".repeat(400) + "1e500", "0." + "0".repeat(400) + "1e800", "1" + "0".repeat(400) + "e-500",
        "1" + "0".repeat(400) + "e-800", "1" + "0".repeat(400),
        // NaN and Infinity spellings
        "NaN", "-NaN", "+NaN", "nan", "NAN", "Nan", "NaNd", "NaNf", "NaN ", " NaN", "N", "NaN0", "Infinity", "-Infinity",
        "+Infinity", "infinity", "INFINITY", "Inf", "-Inf", "Infinityf", "InfinityD", " -Infinity ", "Infinit",
        "Infinity1", "∞", "-∞", "1/0",
        // Suffixes
        "1f", "1F", "1d", "1D", "1l", "1L", "1ff", "1df", "1.f", ".5f", ".f", "f", "d", "-f", "1f ", "1 f", "1e5d",
        // Hex floats
        "0x1p0", "0X1P0", "0x1p1", "0x1.8p1", "0x.8p1", "0x1.p1", "0xp1", "0x.p1", "0x1", "0x1.0", "0x10", "0xA",
        "-0x1p-1", "+0x1p+1", "0x1p1f", "0x1p1d", "0x1p1D ", " 0x1p1 ", "0x0p0", "-0x0p0", "0x0.0p999999999999",
        "0x00001p0", "0x1p-1074", "-0x1p-1074", "0x1p-1075", "0x1.8p-1075", "0x1.0000000000001p-1075", "0x1p-1076",
        "0x0.8p-1073", "0x0.cp-1073", "0x0.4p-1073", "0x1.00000000000008p0", "0x1.00000000000018p0",
        "0x1.000000000000081p0", "0x1.0000000000000800000000001p0", "0x1.fffffffffffffp1023",
        "0x1.fffffffffffff7p1023", "0x1.fffffffffffff8p1023", "0x1p1023", "0x1p1024", "0x1p-1022", "0x1p-1023",
        "0x1.ffffffffffffffffp-1023", "0x0.fffffffffffff8p-1022", "0x0.fffffffffffff7p-1022", "0x1p2147483647",
        "0x1p2147483648", "-0x1p2147483648", "0x1p-2147483648", "0x1p-2147483647", "0x1p00000000000000000001",
        "0x0.0000001p-1050", "0x123456789abcdef0123p0", "0x123456789ABCDEF0123P-100", "0x0.00000000000000000000001p0",
        "0xffffffffffffffffffffffffffffffffp0", "0x1.8p1L", "0x1.8p1ff", "0xg", "0x1p", "0x1pp1", "0x1p+", "1x1p1",
        "0x1p1.5", "0x1e3", "0x1.2.3p1", "0x١p1", "0x1p١", "0x-1p1", "-0x-1p1", "x1p1", "0x 1p1",
    };

    // ASCII-only string literal, so BOMs, line separators and surrogates survive any editor or encoding.
    static String q(String s) {
        if (s == null) return "null";
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            if (c == '"') sb.append("\\\"");
            else if (c == '\\') sb.append("\\\\");
            else if (c < 0x20 || c > 0x7e) sb.append(String.format("\\u%04x", (int) c));
            else sb.append(c);
        }
        return sb.append('"').toString();
    }

    public static void main(String[] args) throws Exception {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        Set<String> inputs = new LinkedHashSet<>(Arrays.asList(INPUTS));
        // Each block of Unicode decimal digits: its 0..9, a signed pair, and the characters just outside it.
        for (char c = 0; c < 0xffff; c++) {
            if (Character.digit(c, 10) == 0) {
                StringBuilder all = new StringBuilder();
                for (int k = 0; k <= 9; k++) all.append((char) (c + k));
                inputs.add(all.toString());
                inputs.add("-" + (char) (c + 1) + (char) (c + 2));
                inputs.add("" + (char) (c - 1));
                inputs.add("" + (char) (c + 10));
            }
        }

        // FloatingDecimal keeps MAX_NDIGITS = 1100 significant digits plus a sticky '1'. Halfway points between
        // doubles, nudged up and down at digits 1099..1200, and wrapped in leading and trailing zeros the cap
        // does not count.
        for (double d : new double[] {0.0, Double.MIN_VALUE, Double.MIN_NORMAL, 0.1, 1.0, Math.PI, Double.MAX_VALUE}) {
            BigDecimal h = new BigDecimal(d).add(new BigDecimal(Math.ulp(d)).divide(BigDecimal.valueOf(2)));
            int top = h.precision() - h.scale();
            inputs.add(h.toString());
            inputs.add(h.toPlainString() + (h.scale() > 0 ? "" : ".") + "0".repeat(2000));
            for (int p : new int[] {1099, 1100, 1101, 1102, 1200}) {
                BigDecimal nudge = BigDecimal.ONE.scaleByPowerOfTen(top - p);
                inputs.add(h.add(nudge).toString());
                inputs.add(h.subtract(nudge).toString());
            }
            inputs.add("0".repeat(2000) + h.add(BigDecimal.ONE.scaleByPowerOfTen(top - 1101)).toPlainString());
        }
        inputs.add("1".repeat(1000));
        inputs.add("1".repeat(10000));
        inputs.add("0." + "1".repeat(10000));
        inputs.add("9".repeat(1100) + "e-1400");
        // Long hex significands: halfway points with a sticky digit far away, leading zeros, overflow, subnormals.
        for (String tail : new String[] {"", "1", "0".repeat(10) + "1", "0".repeat(1000) + "1", "0".repeat(10000) + "1",
                "0".repeat(10000)}) {
            inputs.add("0x1.00000000000008" + tail + "p0");
        }
        inputs.add("0x1.00000000000018" + "0".repeat(1000) + "p0");
        inputs.add("0x1.00000000000007" + "f".repeat(1000) + "p0");
        inputs.add("0x" + "0".repeat(5000) + "1.00000000000008" + "0".repeat(5000) + "1p0");
        inputs.add("0x0." + "0".repeat(1000) + "1p4000");
        inputs.add("0x0.00000000000008" + "0".repeat(1000) + "p-1022");
        inputs.add("-0x0.00000000000008" + "0".repeat(1000) + "1p-1022");
        inputs.add("0x1.fffffffffffff8" + "0".repeat(1000) + "p1023");
        inputs.add("0x1.fffffffffffff7" + "f".repeat(1000) + "p1023");
        inputs.add("0x1" + "8".repeat(2000) + "p-9074");
        inputs.add("0x" + "f".repeat(1000) + "p0");
        inputs.add("0x" + "f".repeat(1000) + "p-4000");
        inputs.add("0x" + "f".repeat(10000) + "p-40000");

        List<String> entries = new ArrayList<>();
        entries.add("  c(null, \"" + Integers.parse(null) + "\", \"" + Longs.parseDecimal(null) + "\", \"" + Doubles.parse(null) + "\")");
        for (String s : inputs) {
            entries.add("  c(" + q(s) + ", \"" + Integers.parse(s) + "\", \"" + Longs.parseDecimal(s) + "\", \"" + Doubles.parse(s) + "\")");
        }
        String out = "// Generated by tools/base-oracle/NumbersOracle.java on JDK " + System.getProperty("java.version")
            + ". Do not edit.\n"
            + "export class NumberCase {\n  input: string | null = null;\n  integer: string = '';\n  long: string = '';\n  double: string = '';\n}\n\n"
            + "function c(input: string | null, integer: string, long: string, double: string): NumberCase {\n"
            + "  const r = new NumberCase();\n  r.input = input;\n  r.integer = integer;\n  r.long = long;\n  r.double = double;\n  return r;\n}\n\n"
            + "export const NUMBER_CASES: NumberCase[] = [\n" + String.join(",\n", entries) + "\n];\n";
        Files.writeString(Path.of("oh_rome/src/test/NumberCases.ets"), out, StandardCharsets.UTF_8);
        System.out.println(entries.size() + " cases");
    }
}
