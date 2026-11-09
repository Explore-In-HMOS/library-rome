// Runs ROME's own XmlReader and Java's decoders over the cases of oh_rome/src/test/XmlReader.test.ets and prints every
// expect(...) line of that test, in order, with Java's result. With the argument ohos it prints the expect(decode(...)) lines
// of oh_rome/src/ohosTest/ets/test/XmlReader.test.ets. The tests' lines are pasted from this output; check them with the diffs below.
// Usage (from the repo root, <rome> is a ROME clone at 6b4a7e8, Temurin 17.0.17+10 like the golden harness):
//   javac -d /tmp/xmlreader-oracle <rome>/rome/src/main/java/com/rometools/rome/io/XmlReader*.java tools/xmlreader-oracle/*.java
//   java -cp /tmp/xmlreader-oracle XmlReaderOracle | diff - <(grep -o 'expect(.*' oh_rome/src/test/XmlReader.test.ets)
//   java -cp /tmp/xmlreader-oracle XmlReaderOracle ohos | diff - <(grep -o 'expect(decode(.*' oh_rome/src/ohosTest/ets/test/XmlReader.test.ets)
import com.rometools.rome.io.XmlReader;
import com.rometools.rome.io.XmlReaderException;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.charset.Charset;
import java.text.MessageFormat;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class XmlReaderOracle {
    // Same names and documents as ROME's XmlReaderTest.
    static final Map<String, String> XML_NAMES = Map.of("XML1", "xml", "XML2", "xml-prolog", "XML3", "xml-prolog-encoding-double-quotes",
            "XML4", "xml-prolog-encoding-single-quotes", "XML5", "xml-prolog-encoding-spaced-single-quotes");
    static final Map<String, int[]> BOMS = new HashMap<>();
    static final Map<String, MessageFormat> XMLS = new HashMap<>();
    static final MessageFormat INFO = new MessageFormat("\nBOM : {0}\nDoc : {1}\nStream Enc : {2}\nProlog Enc : {3}\n");
    static {
        BOMS.put("no-bom", new int[] {});
        BOMS.put("UTF-16BE-bom", new int[] { 0xFE, 0xFF });
        BOMS.put("UTF-16LE-bom", new int[] { 0xFF, 0xFE });
        BOMS.put("UTF-16-bom", new int[] {});
        BOMS.put("UTF-8-bom", new int[] { 0xEF, 0xBB, 0xBF });
        XMLS.put("XML1", new MessageFormat("<root>{2}</root>"));
        XMLS.put("XML2", new MessageFormat("<?xml version=\"1.0\"?>\n<root>{2}</root>"));
        XMLS.put("XML3", new MessageFormat("<?xml version=\"1.0\" encoding=\"{1}\"?>\n<root>{2}</root>"));
        XMLS.put("XML4", new MessageFormat("<?xml version=\"1.0\" encoding=''{1}''?>\n<root>{2}</root>"));
        XMLS.put("XML5", new MessageFormat("<?xml version=\"1.0\" encoding =  \t \n \r''{1}''?>\n<root>{2}</root>"));
    }

    static byte[] stream(String bomType, String xmlType, String streamEnc, String prologEnc) throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        int[] bom = BOMS.get(bomType);
        for (int b : bom == null ? new int[0] : bom) baos.write(b);
        Writer w = new OutputStreamWriter(baos, streamEnc);
        String info = INFO.format(new Object[] { bomType, XML_NAMES.get(xmlType), prologEnc });
        w.write(XMLS.get(xmlType).format(new Object[] { streamEnc, prologEnc, info }));
        w.write("<da>\n");
        for (int i = 0; i < 10000; i++) w.write("<do/>\n");
        w.write("</da>\n");
        w.close();
        return baos.toByteArray();
    }

    interface Run { String run() throws Exception; }

    // Mirrors the test's result(): XmlReaderException keeps its class, every other exception is a plain Error in the port.
    static String result(Run r) {
        try {
            return String.valueOf(r.run());
        } catch (InvocationTargetException e) {
            Throwable t = e.getCause();
            return (t instanceof XmlReaderException ? "XmlReaderException: " : "Error: ") + t.getMessage();
        } catch (XmlReaderException e) {
            return "XmlReaderException: " + e.getMessage();
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }

    static String q(String s) {
        if (s == null) return "null";
        StringBuilder b = new StringBuilder("'");
        for (char c : s.toCharArray()) {
            if (c == '\'' || c == '\\') b.append('\\').append(c);
            else if (c == '\n') b.append("\\n");
            else if (c == '\r') b.append("\\r");
            else if (c == '\t') b.append("\\t");
            else if (c < 0x20 || c > 0x7e) b.append(String.format("\\u%04X", (int) c));
            else b.append(c);
        }
        return b.append("'").toString();
    }

    static void expect(String actual, String expected) {
        System.out.println("expect(" + actual + ").assertEqual(" + expected + ");");
    }

    static String read(Reader r) throws Exception {
        StringBuilder sb = new StringBuilder();
        int c;
        while ((c = r.read()) != -1) sb.append((char) c);
        return sb.toString();
    }

    static XmlReader reader(byte[] bytes, String ct, boolean lenient, String def) throws Exception {
        InputStream is = new ByteArrayInputStream(bytes);
        return ct == null ? new XmlReader(is, lenient, def) : new XmlReader(is, ct, lenient, def);
    }

    static void raw(String bom, String xml, String se, String pe, boolean lenient) {
        expect("raw(" + q(bom) + ", " + xml + ", " + q(se) + ", " + q(pe) + ", " + lenient + ")",
                q(result(() -> reader(stream(bom, xml, se, pe), null, lenient, null).getEncoding())));
    }

    static void http(String ct, String bom, String xml, String se, String pe, boolean lenient, String def) {
        String r = result(() -> {
            XmlReader.setDefaultEncoding(def);
            try {
                return reader(stream(bom, xml, se, pe), ct, lenient, null).getEncoding();
            } finally {
                XmlReader.setDefaultEncoding(null);
            }
        });
        expect("http(" + q(ct) + ", " + q(bom) + ", " + xml + ", " + q(se) + ", " + q(pe) + ", " + lenient + ", " + q(def) + ")", q(r));
    }

    static void prolog(String s, String shown, String enc, String guessed) throws Exception {
        Method m = XmlReader.class.getDeclaredMethod("getXmlProlog", InputStream.class, String.class);
        m.setAccessible(true);
        String r = result(() -> (String) m.invoke(null, new ByteArrayInputStream(s.getBytes(Charset.forName(enc))), guessed));
        expect("prolog(" + (shown == null ? q(s) : shown) + ", " + q(enc) + ", " + q(guessed) + ")", q(r));
    }

    static void prolog(String s, String enc, String guessed) throws Exception {
        prolog(s, null, enc, guessed);
    }

    static void validHttp(String kind, String ct, String bom, String se, String pe) {
        boolean lenient = kind.equals("L");
        String xml = pe == null ? (kind.equals("V") ? "XML1" : "XML2") : "XML3";
        http(ct, bom, xml, se, pe, lenient, null);
    }

    static String boundary(int size, boolean bom) {
        String head = "<?xml encoding=\"TEST\"" + " ".repeat(size - 21);
        return result(() -> reader(((bom ? "\ufeff" : "") + head).getBytes("UTF-8"), null, false, null).getEncoding());
    }


    // Multi-byte charsets the port decodes: in plain code, or (the CJK ones) with util.TextDecoder on the device.
    static final Set<String> PORT_DECODED = Set.of("UTF-8", "UTF-16", "UTF-16BE", "UTF-16LE", "UTF-32", "UTF-32BE", "UTF-32LE",
            "Big5", "EUC-JP", "EUC-KR", "GB18030", "GB2312", "GBK", "ISO-2022-JP", "Shift_JIS");

    static String hex(int[] bytes) {
        StringBuilder b = new StringBuilder("[");
        for (int i = 0; i < bytes.length; i++) b.append(i == 0 ? "" : ", ").append(String.format("0x%02X", bytes[i]));
        return b.append("]").toString();
    }

    static byte[] toBytes(int[] bytes) {
        byte[] out = new byte[bytes.length];
        for (int i = 0; i < bytes.length; i++) out[i] = (byte) bytes[i];
        return out;
    }

    // What the port's decodeAs gives: Java's InputStreamReader result, or its error for a charset the port can't decode.
    static String decodeResult(int[] bytes, String name) {
        return result(() -> {
            String text = read(new InputStreamReader(new ByteArrayInputStream(toBytes(bytes)), name));
            Charset cs = Charset.forName(name);
            if (JavaCharsets.table(cs) == null && !PORT_DECODED.contains(cs.name())) {
                throw new Exception(name + ": charset " + cs.name() + " is not supported by this port");
            }
            return text;
        });
    }

    static void decode(int[] bytes, String name) {
        expect("decode(" + hex(bytes) + ", " + q(name) + ")", q(decodeResult(bytes, name)));
    }

    // getXmlProlog decodes with new String(bytes, "UTF-8"), read() with an InputStreamReader; both must agree.
    static void utf8(int[] bytes) throws Exception {
        String viaString = new String(toBytes(bytes), "UTF-8");
        if (!viaString.equals(read(new InputStreamReader(new ByteArrayInputStream(toBytes(bytes)), "UTF-8")))) {
            throw new IllegalStateException("String and InputStreamReader disagree on " + hex(bytes));
        }
        expect("utf8(" + hex(bytes) + ")", q(viaString));
    }

    public static void main(String[] args) throws Exception {
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        if (args.length > 0 && args[0].equals("ohos")) {
            ohos();
            return;
        }
        // rawNoBom
        for (String e : new String[] { "US-ASCII", "UTF-8", "ISO-8859-1", "CP1047" })
            for (String x : new String[] { "XML1", "XML2", "XML3", "XML4", "XML5" }) raw("no-bom", x, e, e, false);
        // rawBom
        for (String e : new String[] { "UTF-8", "UTF-16BE", "UTF-16LE", "UTF-16" }) raw(e + "-bom", "XML3", e, e, false);
        String[][] invalid = { { "UTF-8-bom", "US-ASCII", "US-ASCII" }, { "UTF-8-bom", "ISO-8859-1", "ISO-8859-1" },
                { "UTF-8-bom", "UTF-8", "UTF-16" }, { "UTF-8-bom", "UTF-8", "UTF-16BE" }, { "UTF-8-bom", "UTF-8", "UTF-16LE" },
                { "UTF-16BE-bom", "UTF-16BE", "UTF-16LE" }, { "UTF-16LE-bom", "UTF-16LE", "UTF-16BE" }, { "UTF-16LE-bom", "UTF-16LE", "UTF-8" } };
        for (String[] i : invalid) raw(i[0], "XML3", i[1], i[2], false);
        // http: ROME's testHttp calls in order. V = testHttpValid, I = testHttpInvalid, L = testHttpLenient,
        // A = testAlternateDefaultEncoding (last field is the default encoding).
        String[] calls = {
            "V|application/xml|no-bom|US-ASCII|", "V|application/xml|UTF-8-bom|US-ASCII|", "V|application/xml|UTF-8-bom|UTF-8|",
            "V|application/xml|UTF-8-bom|UTF-8|UTF-8", "V|application/xml;charset=UTF-8|UTF-8-bom|UTF-8|",
            "V|application/xml;charset=\"UTF-8\"|UTF-8-bom|UTF-8|", "V|application/xml;charset='UTF-8'|UTF-8-bom|UTF-8|",
            "V|application/xml;charset=UTF-8|UTF-8-bom|UTF-8|UTF-8", "V|application/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|",
            "V|application/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|UTF-16", "V|application/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|UTF-16BE",
            "I|application/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|", "I|application/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|UTF-16",
            "I|application/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|UTF-16BE", "I|application/xml|UTF-8-bom|US-ASCII|US-ASCII",
            "I|application/xml;charset=UTF-16|UTF-16LE|UTF-8|UTF-8", "I|application/xml;charset=UTF-16|no-bom|UTF-16BE|UTF-16BE",
            "V|text/xml|no-bom|US-ASCII|", "V|text/xml;charset=UTF-8|UTF-8-bom|UTF-8|UTF-8", "V|text/xml;charset=UTF-8|UTF-8-bom|UTF-8|",
            "V|text/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|", "V|text/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|UTF-16",
            "V|text/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|UTF-16BE", "V|text/xml|UTF-8-bom|US-ASCII|",
            "A|application/xml|UTF-8-bom|UTF-8||", "A|application/xml|no-bom|US-ASCII||US-ASCII", "A|application/xml|UTF-8-bom|UTF-8||UTF-8",
            "A|text/xml|no-bom|US-ASCII||", "A|text/xml|no-bom|US-ASCII||US-ASCII", "A|text/xml|no-bom|US-ASCII||UTF-8",
            "I|text/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|", "I|text/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|UTF-16",
            "I|text/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|UTF-16BE", "I|text/xml;charset=UTF-16|no-bom|UTF-16BE|UTF-16BE",
            "I|text/xml;charset=UTF-16|no-bom|UTF-16BE|",
            "L|text/xml|no-bom|US-ASCII|", "L|text/xml;charset=UTF-8|UTF-8-bom|UTF-8|UTF-8", "L|text/xml;charset=UTF-8|UTF-8-bom|UTF-8|",
            "L|text/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|", "L|text/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|UTF-16",
            "L|text/xml;charset=UTF-16|UTF-16BE-bom|UTF-16BE|UTF-16BE", "L|text/xml|UTF-8-bom|US-ASCII|",
            "L|text/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|", "L|text/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|UTF-16",
            "L|text/xml;charset=UTF-16BE|UTF-16BE-bom|UTF-16BE|UTF-16BE", "L|text/xml;charset=UTF-16|no-bom|UTF-16BE|UTF-16BE",
            "L|text/xml;charset=UTF-16|no-bom|UTF-16BE|",
            "L|text/html|no-bom|US-ASCII|US-ASCII", "L|text/html|no-bom|US-ASCII|", "L|text/html;charset=UTF-8|no-bom|US-ASCII|UTF-8",
            "L|text/html;charset=UTF-16BE|no-bom|US-ASCII|UTF-8" };
        for (String c : calls) {
            String[] p = c.split("\\|", -1);
            String pe = p[4].isEmpty() ? null : p[4];
            if (p[0].equals("A")) http(p[1], p[2], pe == null ? "XML1" : "XML3", p[3], pe, false, p[5].isEmpty() ? null : p[5]);
            else validHttp(p[0], p[1], p[2], p[3], pe);
        }
        // encodingAttributeXml, httpHeaderContentType
        String attr = "<?xml version=\"1.0\" ?> \n<atom:feed xmlns:atom=\"http://www.w3.org/2005/Atom\">\n\n  <atom:entry>\n"
                + "    <atom:title encoding=\"base64\"><![CDATA\naW5nTGluZSIgLz4";
        expect("new XmlReader(bytes(xml, 'UTF-8'), '', true).encoding", q(result(() -> reader(attr.getBytes("UTF-8"), "", true, null).getEncoding())));
        String body = "<?xml version=\"1.0\" encoding=\"utf-8\"?><rss version=\"2.0\"><channel/></rss>";
        expect("new XmlReader(bytes(body, 'UTF-8'), 'text/xml').encoding",
                q(result(() -> reader(body.getBytes("UTF-8"), "text/xml", true, null).getEncoding())));
        // getXmlProlog
        prolog("<?xml encoding=\"TEST\"?>", "UTF-8", "UTF-8");
        prolog("<?xml encoding=\"UTF-8\"?>", "UTF-8", "UTF-8");
        prolog("<?xml encoding=\"UTF-16\"?>", "UTF-16", "UTF-16");
        prolog("<?xml encoding=\"CP1047\"?>", "CP1047", "CP1047");
        prolog("<?xml>", "UTF-8", "UTF-8");
        prolog("<?xml encoding=\"UTF-8\"?>", "UTF-8", null);
        prolog("<?xml encoding=\"utf-8\"?>", "UTF-8", "UTF-8");
        prolog("<?xml encoding=\"TEST\"?>", "ISO-8859-1", "UTF-8");
        prolog("<?xml encoding=\"TEST\"?>", "UTF-16BE", "UTF-16LE");
        prolog("<?xml encoding=\"TEST\"", "UTF-8", "UTF-8");
        prolog("", "UTF-8", "UTF-8");
        prolog("<?xml encoding=\"TEST\"?" + " ".repeat(5000) + ">", "`<?xml encoding=\"TEST\"?${' '.repeat(5000)}>`", "UTF-8", "UTF-8");
        // prologBufferBoundary
        expect("raw4096(head(4095), false)", q(boundary(4095, false)));
        expect("raw4096(head(4096), false)", q(boundary(4096, false)));
        expect("raw4096(head(4096), true)", q(boundary(4096, true)));
        expect("raw4096(head(4097), false)", q(boundary(4097, false)));
        // moreRomeBehavior
        raw("UTF-8-bom", "XML3", "ISO-8859-1", "ISO-8859-1", true);
        raw("UTF-16BE-bom", "XML3", "UTF-16LE", "UTF-16LE", true);
        raw("no-bom", "XML3", "UTF-16LE", "UTF-16", false);
        raw("no-bom", "XML2", "UTF-8", null, false);
        http("application/json", "no-bom", "XML2", "UTF-8", null, false, null);
        http("application/json", "no-bom", "XML2", "UTF-8", null, true, null);
        http("text/html", "UTF-8-bom", "XML2", "UTF-8", null, false, null);
        http("application/atom+xml", "no-bom", "XML3", "UTF-8", "WINDOWS-1254", false, null);
        http("text/xml; charset=iso-8859-1 x", "no-bom", "XML1", "UTF-8", null, false, null);
        http("text/xml; xcharset=utf-8", "no-bom", "XML1", "UTF-8", null, false, null);
        http("text/xml; charset=\"", "no-bom", "XML1", "UTF-8", null, false, null);
        prolog("<?xml version=\"1.0\" encoding=\"a\" x encoding = 'b'?>", "UTF-8", "UTF-8");
        prolog("<?xml version=\"1.0\"\u0085 encoding=\"x\"?>", "UTF-8", "UTF-8");
        prolog("<?xml version=\"1.0\"\u00a0encoding=\u00a0\"x\"?>", "UTF-8", "UTF-8");
        prolog("<?xml encoding=\"stra\u00dfe\"?>", "UTF-8", "UTF-8");
        prolog("<?xml encoding=\"\u00e9\"?>", "ISO-8859-1", "UTF-8");
        byte[] doubleBom = { (byte) 0xEF, (byte) 0xBB, (byte) 0xBF, (byte) 0xEF, (byte) 0xBB, (byte) 0xBF, '<', '?', 'x', 'm', 'l', '>' };
        expect("new XmlReader(doubleBom, 'text/html').encoding", q(result(() -> reader(doubleBom, "text/html", true, null).getEncoding())));
        // readsSingleByteEncodingsWithoutTextDecoder
        XmlReader ascii = reader(new byte[] { 0x3C, 0x61, 0x3E, (byte) 0xE9 }, "text/xml", false, null);
        expect("ascii.encoding", q(ascii.getEncoding()));
        expect("ascii.read()", q(read(ascii)));
        expect("latin1.read()", q(read(reader(new byte[] { 0x3C, 0x61, 0x3E, (byte) 0xE9, (byte) 0x80 }, "text/xml", false, "ISO-8859-1"))));
        String ebcdic = "<?xml version=\"1.0\" encoding=\"CP1047\"?><a>Hello</a>";
        XmlReader cp1047 = reader(ebcdic.getBytes("CP1047"), null, false, null);
        expect("cp1047.encoding", q(cp1047.getEncoding()));
        String decoded = read(cp1047);
        expect("cp1047.read()", decoded.equals(ebcdic) ? "ebcdic" : q(decoded));
        // httpMimeRules
        http("text/rss+xml", "no-bom", "XML1", "US-ASCII", null, false, null);
        http("text/xml-external-parsed-entity", "no-bom", "XML1", "US-ASCII", null, false, null);
        http("application/xml-external-parsed-entity", "no-bom", "XML3", "UTF-8", "UTF-8", false, null);
        http("application/xml-dtd", "no-bom", "XML3", "UTF-8", "UTF-8", false, null);
        http("text/xml;charset=UTF-16LE", "UTF-16LE-bom", "XML2", "UTF-16LE", null, false, null);
        http("application/xml;charset=UTF-16LE", "UTF-16LE-bom", "XML3", "UTF-16LE", "UTF-16LE", false, null);
        http("text/xml;charset=UTF-16", "UTF-8-bom", "XML2", "UTF-8", null, false, null);
        http("text/xml;charset=UTF-16", "UTF-16LE-bom", "XML2", "UTF-16LE", null, false, null);
        for (String ct : new String[] { " text/xml", "text/xml ", "\ttext/xml\r\n", "text/xml ;charset=UTF-8", "\u00a0text/xml",
                "text/xml\u00a0", "text/xml\u3000", "\ufefftext/xml", "text/xml\u2028", "text/xml\u0001", "\u001ftext/xml\u001f" }) {
            http(ct, "no-bom", "XML2", "UTF-8", null, false, null);
        }
        // decodesLikeInputStreamReader
        int[] lt = { 0x3C, 0x61, 0x3E };
        for (String name : new String[] { "", "\"UTF-8", "UTF-8\n", " UTF-8", "UTF-16 ", "\u0005UTF-8", "macintosh", "MACINTOSH", "SS",
                "STRASSE", "X-UNKNOWN", "\u212aoi8-r" }) {
            decode(lt, name);
        }
        int[] w1252 = { 0x80, 0x81, 0x8D, 0x8F, 0x90, 0x9D, 0x9F };
        decode(w1252, "windows-1252");
        decode(w1252, "CP1252");
        decode(new int[] { 0x80, 0x8E, 0x9E, 0xD0, 0xDD, 0xDE, 0xF0, 0xFD, 0xFE }, "windows-1254");
        decode(new int[] { 0x3C, 0xE9, 0x80 }, "ISO-8859-1");
        decode(new int[] { 0x3C, 0xE9, 0x80 }, "latin1");
        decode(new int[] { 0x41, 0xE9 }, "US-ASCII");
        decode(new int[] { 0x41, 0xE9 }, "ascii");
        decode(new int[] { 0xC1, 0xE2, 0xF7, 0x9F }, "KOI8-R");
        decode(new int[] { 0x4C, 0x6F, 0xA7, 0x94, 0x15 }, "ibm-1047");
        decode(new int[] { 0x80, 0xA5, 0xF0 }, "x-MacRoman");
        decode(new int[] { 0xA1, 0xBF, 0xE0, 0xFB }, "ISO-8859-8");
        decode(new int[] { 0x80, 0xB0, 0xFF }, "IBM437");
        decode(new int[] { 0xA4, 0xBE }, "ISO-8859-15");
        decode(new int[] { 0xD8, 0x3D, 0x00, 0x3C }, "UTF-16BE");
        decode(new int[] { 0xD8, 0x3D, 0xDE, 0x00, 0xDC, 0x00, 0x00, 0x41 }, "UTF-16BE");
        decode(new int[] { 0xFF, 0xFE, 0x00, 0x41, 0xFE, 0xFF }, "UTF-16BE");
        decode(new int[] { 0x00, 0x41, 0xD8, 0x3D }, "UTF-16BE");
        decode(new int[] { 0x00, 0x41, 0xD8, 0x3D, 0x00 }, "UTF-16BE");
        decode(new int[] { 0x00, 0x41, 0x00 }, "UTF-16BE");
        decode(new int[] { 0x3D, 0xD8, 0x3C, 0x00 }, "UTF-16LE");
        decode(new int[] { 0xFE, 0xFF, 0x00, 0x41 }, "UTF-16LE");
        decode(new int[] { 0xFE, 0xFF, 0x00, 0x41, 0xFE, 0xFF }, "UTF-16");
        decode(new int[] { 0xFF, 0xFE, 0x41, 0x00, 0xFF, 0xFE }, "UTF-16");
        decode(new int[] { 0x00, 0x41, 0xFF, 0xFE }, "UTF-16");
        decode(new int[] { 0xFE }, "UTF-16");
        decode(new int[] { 0x00, 0x00, 0xFE, 0xFF, 0x00, 0x01, 0xF6, 0x00 }, "UTF-32");
        decode(new int[] { 0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00 }, "UTF-32");
        decode(new int[] { 0x00, 0x00, 0x00, 0x41, 0x00, 0x11, 0x00, 0x00, 0x00, 0x00, 0xD8, 0x00, 0x00 }, "UTF-32");
        decode(new int[] { 0x00, 0x00, 0xFE, 0xFF, 0x00, 0x00, 0x00, 0x41 }, "UTF-32BE");
        decode(new int[] { 0xFF, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x41 }, "UTF-32BE");
        decode(new int[] { 0xFF, 0xFE, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00 }, "UTF-32LE");
        decode(new int[] { 0x00, 0x00, 0xFE, 0xFF, 0x41, 0x00, 0x00, 0x00 }, "UTF-32LE");
        decode(new int[] { 0x00, 0x00, 0x00 }, "UTF-32");
        for (String name : new String[] { "windows-31j", "x-windows-949", "Big5-HKSCS", "ISO-2022-KR", "CESU-8", "x-UTF-16LE-BOM" }) {
            decode(lt, name);
        }
        // utf8LikeJava
        int[][] utf8 = { { 0xED, 0xA0, 0x80 }, { 0xED, 0xA0, 0x80, 0x3C }, { 0xED, 0xBF, 0xBF }, { 0xC0, 0xAF }, { 0xC1, 0xBF },
                { 0xC2 }, { 0xC2, 0x3C }, { 0xE2, 0x82 }, { 0xE2, 0x82, 0x3C }, { 0xE2, 0x28, 0xA1 }, { 0xE0, 0x80, 0x80 }, { 0xE0, 0xA0 },
                { 0xE0, 0x9F, 0x80 }, { 0xF0, 0x90, 0x80 }, { 0xF0, 0x90, 0x80, 0x3C }, { 0xF0, 0x80, 0x80, 0x80 }, { 0xF0, 0x8F },
                { 0xF4, 0x90, 0x80, 0x80 }, { 0xF4, 0x8F, 0xBF, 0xBF }, { 0xF5, 0x80, 0x80, 0x80 }, { 0xF7, 0xBF }, { 0xF8, 0x88, 0x80, 0x80, 0x80 },
                { 0x80, 0xBF }, { 0xF0, 0x28, 0x8C, 0xBC }, { 0xF0, 0x90, 0x28, 0xBC }, { 0xF0, 0x90, 0x8C, 0x28 }, { 0xF1, 0x80, 0x80 },
                { 0xF1, 0x80 }, { 0xEF, 0xBF, 0xBD }, { 0xF0, 0x9F, 0x98, 0x80 }, { 0xC3, 0xA9, 0x3C }, { 0xFF, 0xFE }, { 0xE2, 0x82, 0xAC, 0x41 } };
        for (int[] u : utf8) utf8(u);
        int[] prologBytes = { 0x3C, 0x3F, 0x78, 0x6D, 0x6C, 0x20, 0x65, 0x6E, 0x63, 0x6F, 0x64, 0x69, 0x6E, 0x67, 0x3D, 0x22, 0xED, 0xA0, 0x80,
                0x22, 0x3F, 0x3E };
        Method m = XmlReader.class.getDeclaredMethod("getXmlProlog", InputStream.class, String.class);
        m.setAccessible(true);
        expect("result(() => getXmlProlog(new Uint8Array(" + hex(prologBytes) + "), 'UTF-8'))",
                q(result(() -> (String) m.invoke(null, new ByteArrayInputStream(toBytes(prologBytes)), "UTF-8"))));
    }

    static void ohos() throws Exception {
        decode(new int[] { 0x80, 0x81, 0x8D, 0x8F, 0x90, 0x9D, 0x9F }, "windows-1252");
        decode(new int[] { 0x5C, 0x7E, 0x80, 0xA0, 0xFD }, "Shift_JIS");
        decode(new int[] { 0x82, 0xA0, 0x93, 0xFA, 0x96, 0x7B }, "Shift_JIS");
        decode(new int[] { 0x3C, 0xED, 0xA0, 0x80, 0x3E }, "UTF-8");
        decode(new int[] { 0x3C, 0x61, 0x3E }, "X-UNKNOWN");
        decode(new int[] { 0x3C, 0x61, 0x3E }, "windows-31j");
        for (int b : new int[] { 0x1A, 0x1C, 0x7F }) decode(new int[] { 0x41, b, 0x42 }, "Shift_JIS");
        for (String name : new String[] { "Shift_JIS", "EUC-JP", "GBK", "GB18030", "GB2312", "Big5", "EUC-KR" }) {
            decode(unsigned(("\u65E5\u001A\u001C\u007FA<\u65E5" + (name.equals("GB18030") ? "\u00A5\u001A" : "")).getBytes(name)), name);
        }
    }

    static int[] unsigned(byte[] bytes) {
        int[] out = new int[bytes.length];
        for (int i = 0; i < bytes.length; i++) out[i] = bytes[i] & 0xFF;
        return out;
    }
}
