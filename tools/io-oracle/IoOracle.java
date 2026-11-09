// Runs ROME's WireFeedInput/Output and SyndFeedInput/Output over the inputs of oh_rome/src/test/FeedIO.test.ets and
// prints every expect(...) line of that test, in order, with ROME's result. The test's lines are pasted from this
// output; check them with the diff below. The constants here and in the test must stay identical.
// Usage (from the repo root, <rome> is a ROME clone at 6b4a7e8 built with ./mvnw install, JDK Temurin 17.0.17+10, jdom2
// 2.0.6.1 and slf4j-api 1.7.36 from the local Maven repository). rome-opml and rome-modules must be on the classpath:
// their rome.properties add the OPML and rss_2.0yahoo feed types.
//   CP=<rome>/rome/target/classes:<rome>/rome-utils/target/classes:<rome>/rome-opml/target/classes:<rome>/rome-modules/target/classes:<jdom2.jar>:<slf4j-api.jar>
//   javac -d /tmp/io-oracle -cp $CP tools/io-oracle/IoOracle.java
//   java -cp /tmp/io-oracle:$CP IoOracle | /usr/bin/diff - <(grep -o 'expect(.*' oh_rome/src/test/FeedIO.test.ets)
import com.rometools.rome.feed.WireFeed;
import com.rometools.rome.feed.rss.Channel;
import com.rometools.rome.feed.rss.Item;
import com.rometools.rome.feed.synd.SyndFeed;
import com.rometools.rome.io.FeedException;
import com.rometools.rome.io.ParsingFeedException;
import com.rometools.rome.io.SyndFeedInput;
import com.rometools.rome.io.SyndFeedOutput;
import com.rometools.rome.io.WireFeedInput;
import com.rometools.rome.io.WireFeedOutput;
import com.rometools.rome.io.XmlReader;
import java.io.ByteArrayInputStream;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.jdom2.Document;
import org.jdom2.ProcessingInstruction;
import org.jdom2.input.SAXBuilder;

public class IoOracle {
    static final String RSS20 = "<rss version=\"2.0\"><channel><title>T</title><link>http://x/</link>"
            + "<description>D</description></channel></rss>";
    static final String UNKNOWN_ROOT = "<foo/>";
    static final String MALFORMED = "<rss version=\"2.0\">\n<channel>\n  <title>T</title>\n</rss>";
    static final String BAD_NS_URI = "<rss xmlns:p=\"2005\" version=\"2.0\"><channel/></rss>";
    static final String NO_CHANNEL = "<rss version=\"2.0\"/>";
    static final String BAD_HOUR = "<rss version=\"0.91\"><channel><skipHours><hour>x</hour></skipHours></channel></rss>";
    static final String SELF_NO_HREF = "<feed xmlns=\"http://www.w3.org/2005/Atom\"><link rel=\"self\"/></feed>";
    static final String NBSP = "<rss version=\"2.0\"><channel><title>a&nbsp;b</title></channel></rss>";
    static final String LEADING_COMMENT = "<!-- c --> <?xml version=\"1.0\"?><rss version=\"2.0\"><channel/></rss>";
    static final String DOCTYPE = "<?xml version=\"1.0\"?><!DOCTYPE rss PUBLIC \"-//Netscape Communications//DTD RSS 0.91//EN\" "
            + "\"http://my.netscape.com/publish/formats/rss-0.91.dtd\"><rss version=\"0.91\"><channel><title>T</title></channel></rss>";
    static final String DOCTYPE_IN_ELEMENT = "<rss><!DOCTYPE x></rss>";
    static final String LATIN1 = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><rss version=\"2.0\"><channel><title>caf\u00e9</title></channel></rss>";

    static String lit(String s) {
        StringBuilder b = new StringBuilder("'");
        for (char c : s.toCharArray()) {
            if (c == '\'' || c == '\\') b.append('\\').append(c);
            else if (c == '\n') b.append("\\n");
            else if (c == '\r') b.append("\\r");
            else if (c < 0x20 || c > 0x7e) b.append(String.format("\\u%04X", (int) c));
            else b.append(c);
        }
        return b.append("'").toString();
    }

    static void expect(String call, Object value) {
        String assertion;
        if (value == null) assertion = "assertNull()";
        else if (value instanceof Boolean) assertion = (Boolean) value ? "assertTrue()" : "assertFalse()";
        else if (value instanceof String) assertion = "assertEqual(" + lit((String) value) + ")";
        else assertion = "assertEqual(" + value + ")";
        System.out.println("expect(" + call + ")." + assertion + ";");
    }

    interface Call {
        Object run() throws Exception;
    }

    // Mirrors the test's outcome(): the result, or the exception's class, message and (for ParsingFeedException) position.
    static String outcome(Call c) {
        try {
            return "ok " + c.run();
        } catch (Exception e) {
            String s = e.getClass().getSimpleName() + ": " + e.getMessage();
            if (e instanceof ParsingFeedException) {
                ParsingFeedException p = (ParsingFeedException) e;
                s += " @" + p.getLineNumber() + ":" + p.getColumnNumber();
            }
            return s;
        }
    }

    static String causeOf(Call c) {
        try {
            c.run();
            return "no error";
        } catch (Exception e) {
            Throwable t = e.getCause();
            return t == null ? "no cause" : t.getMessage();
        }
    }

    static Exception errorOf(String xml) {
        try {
            new WireFeedInput().build(new StringReader(xml));
        } catch (Exception e) {
            return e;
        }
        throw new IllegalStateException("no error");
    }

    static WireFeedInput input(boolean healer, boolean doctypes) {
        WireFeedInput in = new WireFeedInput();
        in.setXmlHealerOn(healer);
        in.setAllowDoctypes(doctypes);
        return in;
    }

    static String typeAndTitle(WireFeed f) {
        return f.getFeedType() + " " + ((Channel) f).getTitle();
    }

    static String read(String xml, boolean healer, boolean doctypes) {
        return outcome(() -> typeAndTitle(input(healer, doctypes).build(new StringReader(xml))));
    }

    // XmlParser reports this error at the start of the DOCTYPE token, Xerces after it (A1 PR, deviation 13).
    static String withoutColumn(String outcome) {
        return outcome.replaceAll(":-?\\d+$", "");
    }

    static Channel sample(String type, String encoding, String styleSheet) {
        Channel c = new Channel(type);
        c.setTitle("caf\u00e9 \u20ac");
        c.setLink("http://x/");
        c.setDescription("D");
        c.setLanguage("en");
        c.setEncoding(encoding);
        c.setStyleSheet(styleSheet);
        Item item = new Item();
        item.setTitle("I");
        item.setLink("http://x/i");
        c.setItems(List.of(item));
        return c;
    }

    static String write(Channel c, boolean pretty) {
        return outcome(() -> new WireFeedOutput().outputString(c, pretty));
    }

    public static void main(String[] args) throws Exception {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        System.out.println("expect(new WireFeedInput().xmlHealerOn).assertTrue();");
        System.out.println("expect(new WireFeedInput().allowDoctypes).assertFalse();");
        System.out.println("expect(new SyndFeedInput().xmlHealerOn).assertTrue();");
        System.out.println("expect(new SyndFeedInput().allowDoctypes).assertFalse();");
        System.out.println("expect(new SyndFeedInput().preserveWireFeed).assertFalse();");
        // ROME returns these in HashMap key order; the test compares them sorted.
        List<String> in = new ArrayList<>(WireFeedInput.getSupportedFeedTypes());
        Collections.sort(in);
        expect("sorted(WireFeedInput.getSupportedFeedTypes())", String.join(",", in));
        List<String> out = new ArrayList<>(WireFeedOutput.getSupportedFeedTypes());
        Collections.sort(out);
        expect("sorted(WireFeedOutput.getSupportedFeedTypes())", String.join(",", out));

        expect("read(RSS20)", read(RSS20, true, false));
        expect("read(UNKNOWN_ROOT)", read(UNKNOWN_ROOT, true, false));
        expect("read(MALFORMED)", read(MALFORMED, true, false));
        expect("read(BAD_NS_URI)", read(BAD_NS_URI, true, false));
        expect("read(BAD_HOUR)", read(BAD_HOUR, true, false));
        expect("read(NO_CHANNEL)", read(NO_CHANNEL, true, false));
        expect("read(SELF_NO_HREF)", read(SELF_NO_HREF, true, false));
        expect("causeOf(() => readWire(SELF_NO_HREF))", causeOf(() -> input(true, false).build(new StringReader(SELF_NO_HREF))));
        // ROME rethrows IllegalArgumentException and its subclasses raw and wraps everything else (WireFeedInput.java:228-241).
        expect("errorOf(UNKNOWN_ROOT) instanceof IllegalArgumentException", errorOf(UNKNOWN_ROOT) instanceof IllegalArgumentException);
        expect("errorOf(BAD_NS_URI) instanceof IllegalArgumentException", errorOf(BAD_NS_URI) instanceof IllegalArgumentException);
        expect("errorOf(BAD_HOUR) instanceof IllegalArgumentException", errorOf(BAD_HOUR) instanceof IllegalArgumentException);
        expect("errorOf(NO_CHANNEL) instanceof ParsingFeedException", errorOf(NO_CHANNEL) instanceof ParsingFeedException);
        expect("(errorOf(SELF_NO_HREF) as ParsingFeedException).rootCause instanceof FeedException",
                errorOf(SELF_NO_HREF).getCause() instanceof FeedException);
        expect("read(NBSP)", read(NBSP, true, false));
        expect("read(NBSP, false)", read(NBSP, false, false));
        expect("read(LEADING_COMMENT)", read(LEADING_COMMENT, true, false));
        expect("read(LEADING_COMMENT, false)", read(LEADING_COMMENT, false, false));
        expect("withoutColumn(read(DOCTYPE))", withoutColumn(read(DOCTYPE, true, false)));
        expect("read(DOCTYPE, true, true)", read(DOCTYPE, true, true));
        expect("read(DOCTYPE_IN_ELEMENT)", read(DOCTYPE_IN_ELEMENT, true, false));
        expect("read(DOCTYPE_IN_ELEMENT, true, true)", read(DOCTYPE_IN_ELEMENT, true, true));
        expect("read('')", read("", true, false));
        byte[] latin1 = LATIN1.getBytes(StandardCharsets.ISO_8859_1);
        expect("outcome(() => typeAndTitle(new WireFeedInput().build(latin1())))",
                outcome(() -> typeAndTitle(new WireFeedInput().build(new XmlReader(new ByteArrayInputStream(latin1))))));
        Document unknown = new SAXBuilder().build(new StringReader(UNKNOWN_ROOT));
        expect("outcome(() => typeAndTitle(new WireFeedInput().build(parseXml(UNKNOWN_ROOT))))",
                outcome(() -> typeAndTitle(new WireFeedInput().build(unknown))));
        Document rss = new SAXBuilder().build(new StringReader(RSS20));
        expect("outcome(() => typeAndTitle(new WireFeedInput().build(parseXml(RSS20))))",
                outcome(() -> typeAndTitle(new WireFeedInput().build(rss))));

        expect("write(sample('rss_2.0', null, null), true)", write(sample("rss_2.0", null, null), true));
        expect("write(sample('rss_2.0', null, null), false)", write(sample("rss_2.0", null, null), false));
        expect("outcome(() => new WireFeedOutput().outputString(sample('rss_2.0', null, null)))",
                outcome(() -> new WireFeedOutput().outputString(sample("rss_2.0", null, null))));
        expect("write(sample('rss_2.0', 'ISO-8859-1', null), false)", write(sample("rss_2.0", "ISO-8859-1", null), false));
        expect("write(sample('rss_2.0', 'US-ASCII', 'a.xsl'), false)", write(sample("rss_2.0", "US-ASCII", "a.xsl"), false));
        expect("write(sample('rss_0.91N', null, 'a\"b.xsl'), true)", write(sample("rss_0.91N", null, "a\"b.xsl"), true));
        expect("write(sample('rss_2.0', null, 'a?>b'), false)", write(sample("rss_2.0", null, "a?>b"), false));
        expect("write(sample('foo', null, null), false)", write(sample("foo", null, null), false));
        expect("write(sample(null, null, null), false)", write(sample(null, null, null), false));
        Document doc = new WireFeedOutput().outputJDom(sample("rss_0.91N", null, "a.xsl"));
        ProcessingInstruction pi = (ProcessingInstruction) doc.getContent(0);
        expect("pi.getTarget()", pi.getTarget());
        expect("pi.getData()", pi.getData());
        expect("doc.getContent()[1] instanceof DocType", doc.getContent(1) instanceof org.jdom2.DocType);

        SyndFeedInput sin = new SyndFeedInput();
        SyndFeed synd = sin.build(new StringReader(RSS20));
        expect("synd.originalWireFeed() === null", synd.originalWireFeed() == null);
        sin.setPreserveWireFeed(true);
        SyndFeed preserved = sin.build(new StringReader(RSS20));
        expect("preserved.originalWireFeed()!.feedType", preserved.originalWireFeed().getFeedType());
        expect("preserved.isPreservingWireFeed()", preserved.isPreservingWireFeed());
        expect("outcome(() => new SyndFeedInput().build(UNKNOWN_ROOT).feedType)",
                outcome(() -> new SyndFeedInput().build(new StringReader(UNKNOWN_ROOT)).getFeedType()));
        SyndFeedInput noHealer = new SyndFeedInput();
        noHealer.setXmlHealerOn(false);
        expect("outcome(() => noHealer.build(NBSP).feedType)", outcome(() -> noHealer.build(new StringReader(NBSP)).getFeedType()));
        SyndFeedInput doctypes = new SyndFeedInput();
        doctypes.setAllowDoctypes(true);
        expect("outcome(() => doctypes.build(DOCTYPE).feedType)", outcome(() -> doctypes.build(new StringReader(DOCTYPE)).getFeedType()));
        expect("outcome(() => new SyndFeedOutput().outputString(synd, false))", outcome(() -> new SyndFeedOutput().outputString(synd, false)));
        expect("new SyndFeedOutput().outputString(synd) === new WireFeedOutput().outputString(synd.createWireFeed())",
                new SyndFeedOutput().outputString(synd).equals(new WireFeedOutput().outputString(synd.createWireFeed())));
        expect("new SyndFeedOutput().outputJDom(synd).getRootElement().getName()", new SyndFeedOutput().outputJDom(synd).getRootElement().getName());
    }
}
