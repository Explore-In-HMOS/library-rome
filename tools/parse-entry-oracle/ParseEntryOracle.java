// Runs ROME's Atom10Parser.parseEntry over the inputs of oh_rome/src/test/AtomParseEntry.test.ets and prints the test's
// expect lines, in order, with ROME's result. The test's lines are pasted from this output; check them with the diff below.
// Usage (from the repo root, <rome> is a ROME clone at 6b4a7e8 built with ./mvnw, JDK Temurin 17.0.17+10, jdom2 2.0.6.1
// and slf4j-api 1.7.36 from the local Maven repository; <cp> = <rome>/rome/target/classes:<rome>/rome-utils/target/classes:<jdom2.jar>:<slf4j-api.jar>):
//   javac -d /tmp/pe-oracle -cp <cp> tools/parse-entry-oracle/ParseEntryOracle.java
//   java -cp /tmp/pe-oracle:<cp> ParseEntryOracle | /usr/bin/diff - <(grep -o 'expect(run.*' oh_rome/src/test/AtomParseEntry.test.ets)
import com.rometools.rome.feed.atom.Entry;
import com.rometools.rome.feed.atom.Link;
import com.rometools.rome.io.impl.Atom10Parser;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.jdom2.input.JDOMParseException;

public class ParseEntryOracle {
    static final String NS = "xmlns=\"http://www.w3.org/2005/Atom\"";
    static final String XXE = "<?xml  version=\"1.0\" encoding=\"ISO-8859-1\"?><!DOCTYPE foo [\n   <!ELEMENT foo ANY >\n   "
            + "<!ENTITY xxe SYSTEM  \"file:///etc/passwd\" >]><entry " + NS + ">  <title>Hello &xxe;</title></entry>";
    static final String RELATIVE = "<entry " + NS + " xml:base=\"sub/\"><title>T</title><id>i</id>"
            + "<link href=\"a.html\"/><link rel=\"enclosure\" href=\"/b.mp3\" length=\"3\"/><content src=\"c.txt\"/></entry>";
    static final String ABSOLUTE_BASE = "<entry " + NS + " xml:base=\"http://y/\"><link href=\"a.html\"/></entry>";
    static final String NO_BASE = "<entry " + NS + "><link href=\"a.html\"/></entry>";
    static final String NOT_ENTRY = "<foo " + NS + "/>";
    static final String NO_NS = "<entry><title>T</title></entry>";
    static final String TWO = "<feed " + NS + "><entry><title>inner</title></entry></feed>";
    static final String MALFORMED = "<entry " + NS + ">\n<title>T</entry>";
    static final String BAD_NS_URI = "<entry " + NS + " xmlns:p=\"2005\"/>";

    static String links(final List<Link> links) {
        final List<String> out = new ArrayList<>();
        for (final Link link : links) {
            out.add(link.getHref() + "=" + link.getHrefResolved());
        }
        return out.toString().replace(", ", ",");
    }

    static String run(final String xml, final String base) {
        try {
            final Entry e = Atom10Parser.parseEntry(new StringReader(xml), base, Locale.US);
            final String src = e.getContents().isEmpty() ? "null" : e.getContents().get(0).getSrc();
            return "ok " + e.getTitle() + " " + e.getId() + " " + e.getXmlBase() + " " + links(e.getAlternateLinks()) + " " + links(e.getOtherLinks()) + " " + src;
        } catch (final JDOMParseException x) {
            final String prefix = "Error on line " + x.getLineNumber() + ": ";
            return "XmlParseException: " + x.getMessage().substring(prefix.length()) + " @" + x.getLineNumber();
        } catch (final Exception x) {
            return x.getClass().getSimpleName() + ": " + x.getMessage();
        }
    }

    static void line(final String name, final String nameBase, final String xml, final String base) {
        final String r = run(xml, base);
        System.out.println("expect(run(" + name + ", " + nameBase + ")).assertEqual('" + r.replace("\\", "\\\\").replace("'", "\\'") + "');");
    }

    public static void main(final String[] args) {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        for (final boolean resolve : new boolean[] {false, true}) {
            Atom10Parser.setResolveURIs(resolve);
            line("XXE", "null", XXE, null);
            line("RELATIVE", "null", RELATIVE, null);
            line("RELATIVE", "BASE", RELATIVE, "http://x/base/");
            line("RELATIVE", "RELATIVE_BASE", RELATIVE, "rel/");
            line("ABSOLUTE_BASE", "BASE", ABSOLUTE_BASE, "http://x/base/");
            line("NO_BASE", "FILE_BASE", NO_BASE, "http://x/base/f.xml");
            line("NO_BASE", "null", NO_BASE, null);
            line("NOT_ENTRY", "null", NOT_ENTRY, null);
            line("NO_NS", "null", NO_NS, null);
            line("TWO", "null", TWO, null);
            line("MALFORMED", "null", MALFORMED, null);
            line("BAD_NS_URI", "null", BAD_NS_URI, null);
        }
        Atom10Parser.setResolveURIs(false);
    }
}
