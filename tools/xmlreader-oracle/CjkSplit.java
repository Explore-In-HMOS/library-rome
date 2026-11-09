// Checks on JDK 17 the rule decodeCjk in oh_rome/src/main/ets/io/XmlReader.ets uses: in Shift_JIS, EUC-JP, GBK, GB18030, GB2312,
// Big5 and EUC-KR every byte 0x00-0x7F decodes alone, and inside valid text, to the same code point, and splitting the input
// where decodeCjk emits an ASCII byte directly never changes Java's result. Then prints the cjk(...) lines of
// oh_rome/src/test/XmlReader.test.ets, a decoded segment shown as [hex].
// Usage (from the repo root, Temurin 17.0.17+10):
//   java tools/xmlreader-oracle/CjkSplit.java | /usr/bin/diff - <(grep -o 'expect(cjk(.*' oh_rome/src/test/XmlReader.test.ets)
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CodingErrorAction;
import java.util.Arrays;
import java.util.Map;
import java.util.Random;
import java.util.function.Function;

public class CjkSplit {
    static final String[] CHARSETS = { "Shift_JIS", "EUC-JP", "GBK", "GB18030", "GB2312", "Big5", "EUC-KR" };
    static final Map<String, Integer> ALWAYS_ASCII = Map.of("Shift_JIS", 0x40, "GBK", 0x40, "Big5", 0x40, "GB2312", 0x80, "EUC-KR", 0x80);

    // Same as unitLength in XmlReader.ets.
    static int unitLength(String charset, byte[] bytes, int i) {
        int b = bytes[i] & 0xFF;
        if (b < 0x80) return 1;
        if (charset.equals("EUC-JP")) return b == 0x8F ? 3 : 2;
        if (b == 0x80 || b == 0xFF || i + 1 >= bytes.length) return 1;
        int b2 = bytes[i + 1] & 0xFF;
        if (b2 < 0x30) return 1;
        if (b2 > 0x39) return 2;
        return i + 2 < bytes.length && (bytes[i + 2] & 0xFF) >= 0x81 && (bytes[i + 2] & 0xFF) <= 0xFE ? 4 : 3;
    }

    // Same as decodeCjk in XmlReader.ets.
    static String decodeCjk(byte[] bytes, String charset, Function<byte[], String> decodeSegment) {
        Integer limit = ALWAYS_ASCII.get(charset);
        StringBuilder out = new StringBuilder();
        int start = 0;
        int i = 0;
        while (i < bytes.length) {
            int b = bytes[i] & 0xFF;
            if (b < 0x80 && (limit == null || b < limit || b == 0x7F)) {
                if (start < i) out.append(decodeSegment.apply(Arrays.copyOfRange(bytes, start, i)));
                out.append((char) b);
                start = i + 1;
            }
            i += limit == null ? unitLength(charset, bytes, i) : 1;
        }
        if (start < bytes.length) out.append(decodeSegment.apply(Arrays.copyOfRange(bytes, start, bytes.length)));
        return out.toString();
    }

    static Function<byte[], String> java(Charset cs) {
        CharsetDecoder d = cs.newDecoder().onMalformedInput(CodingErrorAction.REPLACE).onUnmappableCharacter(CodingErrorAction.REPLACE);
        return bytes -> {
            try {
                return d.reset().decode(ByteBuffer.wrap(bytes)).toString();
            } catch (Exception e) {
                throw new IllegalStateException(e);
            }
        };
    }

    static String hex(byte[] bytes, String sep, String fmt) {
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < bytes.length; i++) b.append(i == 0 ? "" : sep).append(String.format(fmt, bytes[i] & 0xFF));
        return b.toString();
    }

    static String q(String s) {
        StringBuilder b = new StringBuilder("'");
        for (char c : s.toCharArray()) {
            if (c == '\'' || c == '\\') b.append('\\').append(c);
            else if (c < 0x20 || c > 0x7e) b.append(String.format("\\u%04X", (int) c));
            else b.append(c);
        }
        return b.append("'").toString();
    }

    static byte[] bytes(int... values) {
        byte[] out = new byte[values.length];
        for (int i = 0; i < values.length; i++) out[i] = (byte) values[i];
        return out;
    }

    static void check(String charset, Function<byte[], String> java, byte[] in, long[] counts) {
        counts[0]++;
        if (!java.apply(in).equals(decodeCjk(in, charset, java))) {
            throw new IllegalStateException(charset + ": splitting changes Java's result for " + hex(in, " ", "%02X"));
        }
    }

    public static void main(String[] args) {
        String jdk = System.getProperty("java.vendor.version", "") + " " + System.getProperty("java.runtime.version");
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        int[] alphabet = { 0x00, 0x09, 0x0A, 0x1A, 0x1B, 0x1C, 0x20, 0x30, 0x35, 0x39, 0x3C, 0x3F, 0x40, 0x41, 0x5C, 0x7E, 0x7F, 0x80, 0x81,
            0x84, 0x85, 0x88, 0x8E, 0x8F, 0x9F, 0xA0, 0xA1, 0xA4, 0xB0, 0xC8, 0xC9, 0xD5, 0xDF, 0xE0, 0xEA, 0xEB, 0xF0, 0xF9, 0xFA, 0xFC, 0xFD,
            0xFE, 0xFF };
        Random random = new Random(17);
        for (String charset : CHARSETS) {
            Charset cs = Charset.forName(charset);
            Function<byte[], String> java = java(cs);
            byte[] kanji = "日".getBytes(cs);
            for (int b = 0; b < 0x80; b++) {
                String c = String.valueOf((char) b);
                byte[] inText = new byte[kanji.length * 2 + 1];
                System.arraycopy(kanji, 0, inText, 0, kanji.length);
                inText[kanji.length] = (byte) b;
                System.arraycopy(kanji, 0, inText, kanji.length + 1, kanji.length);
                if (!java.apply(bytes(b)).equals(c) || !java.apply(bytes(0x41, b, 0x42)).equals("A" + c + "B")
                        || !java.apply(inText).equals("日" + c + "日")) {
                    throw new IllegalStateException(charset + ": byte " + b + " does not decode to itself");
                }
            }
            long[] counts = { 0 };
            for (int p = 0; p < 256; p++) {
                check(charset, java, bytes(p), counts);
                for (int r = 0; r < 256; r++) {
                    check(charset, java, bytes(p, r), counts);
                    for (int s : alphabet) check(charset, java, bytes(p, r, s), counts);
                }
            }
            for (int p : alphabet) for (int r : alphabet) for (int s : alphabet) for (int t : alphabet) check(charset, java, bytes(p, r, s, t), counts);
            for (int n = 0; n < 2_000_000; n++) {
                byte[] in = new byte[1 + random.nextInt(12)];
                for (int i = 0; i < in.length; i++) in[i] = (byte) (random.nextInt(3) == 0 ? random.nextInt(256) : alphabet[random.nextInt(alphabet.length)]);
                check(charset, java, in, counts);
            }
            System.err.println(charset + ": bytes 0x00-0x7F decode to themselves; splitting matches Java on " + counts[0] + " inputs (" + jdk.trim() + ")");
        }
        int[][][] cases = {
            { { 0x41, 0x1A, 0x42 }, { 0x41, 0x1C, 0x42 }, { 0x41, 0x7F, 0x42 }, { 0x93, 0xFA, 0x1A, 0x93, 0xFA }, { 0x3C, 0x61, 0x3E },
                { 0x81, 0x40, 0x3C, 0x85, 0x41, 0x7F, 0x80 } },
            { { 0xC6, 0xFC, 0x1A, 0x41 }, { 0x8F, 0xB0, 0xA1, 0x1A }, { 0xB0, 0x1A, 0x42 }, { 0x8E, 0xB1, 0x3C, 0x8F, 0x41 } },
            { { 0xC8, 0xD5, 0x1A, 0x7F, 0x41 }, { 0x81, 0x40, 0x3E, 0x80 } },
            { { 0x81, 0x30, 0x87, 0x30, 0x1A }, { 0x81, 0x30, 0x1A, 0x42, 0x43 }, { 0x81, 0x3C, 0x41, 0x81, 0x1A }, { 0xC8, 0xD5, 0x1A }, { 0x80, 0x1A, 0xFF, 0x41 } },
            { { 0xC8, 0xD5, 0x41, 0x1A }, { 0xB0, 0x41, 0x7F } },
            { { 0xA4, 0xE9, 0x1A, 0x41, 0x7F } },
            { { 0xC0, 0xCF, 0x41, 0x1A } },
        };
        for (int c = 0; c < CHARSETS.length; c++) {
            for (int[] in : cases[c]) {
                String out = decodeCjk(bytes(in), CHARSETS[c], segment -> "[" + hex(segment, " ", "%02X") + "]");
                System.out.println("expect(cjk([" + hex(bytes(in), ", ", "0x%02X") + "], " + q(CHARSETS[c]) + ")).assertEqual(" + q(out) + ");");
            }
        }
    }
}
