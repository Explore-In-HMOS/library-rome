// Writes oh_rome/src/test/XmlOutputterExpected.ets: JDOM 2.0.6.1 XMLOutputter output for every tree x format that
// oh_rome/src/test/XmlOutputter.test.ets builds the same way. From the repo root:
//   java -cp <jdom2-2.0.6.1.jar> tools/xml-oracle/XmlOutputterOracle.java   (Temurin 17.0.17+10)
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.function.Supplier;

import org.jdom2.Attribute;
import org.jdom2.CDATA;
import org.jdom2.Comment;
import org.jdom2.Content;
import org.jdom2.DocType;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.Namespace;
import org.jdom2.ProcessingInstruction;
import org.jdom2.Text;
import org.jdom2.output.Format;
import org.jdom2.output.XMLOutputter;

public class XmlOutputterOracle {
    static final Namespace D = Namespace.getNamespace("urn:d");
    static final Namespace P = Namespace.getNamespace("p", "urn:p");
    static final Namespace P2 = Namespace.getNamespace("p", "urn:p2");
    static final Namespace Q = Namespace.getNamespace("q", "urn:q");
    static final Namespace XHTML = Namespace.getNamespace("http://www.w3.org/1999/xhtml");
    static final Namespace ATOM = Namespace.getNamespace("http://www.w3.org/2005/Atom");
    static final String SPECIAL = "\"'<>& \r\t\n";
    static final String CHARSET_SAMPLE = "\u00e9\u20ac\u0416\u4e2d\u00a5\\~\u00a0\u3042\uac00\ud83d\ude00";
    static final String NON_ASCII = "café € 中 😀 \u0081";

    static Element el(String name, Object... children) {
        Element e = new Element(name);
        for (Object c : children) {
            e.addContent(c instanceof String ? new Text((String) c) : (Content) c);
        }
        return e;
    }

    static Map<String, Function<XMLOutputter, String>> trees() {
        Map<String, Function<XMLOutputter, String>> t = new LinkedHashMap<>();
        t.put("escapes", o -> {
            Element e = el("a", SPECIAL + "]]>");
            e.setAttribute("attr", SPECIAL + "]]>");
            return o.outputString(e);
        });
        t.put("cdata", o -> o.outputString(el("a", new CDATA(" x <&> y "), "]]>", new CDATA(""))));
        t.put("empty", o -> {
            Element b = el("b", "");
            Element c = el("c");
            c.setAttribute("attr", "1");
            return o.outputString(el("root", el("a"), b, c, el("d", "  ")));
        });
        t.put("textOnly", o -> o.outputString(el("a", "  hello \n  world  ")));
        t.put("mixed", o -> o.outputString(el("p", "  Some ", el("b", "bold"), " and ", el("i", " italic "),
                "\n text  ")));
        t.put("adjacentText", o -> o.outputString(el("a", "one ", new CDATA(" two "), "  three",
                el("b"), "  ", el("c"), "y ", "", new CDATA("  "))));
        t.put("whitespaceOnly", o -> o.outputString(el("root", "\n  ", el("x"), "\n  ", el("y", "  "), "\n",
                el("z", "\n   \n"))));
        t.put("nested", o -> o.outputString(el("root", el("a", el("b", el("c", "deep"), new Comment(" c "),
                new ProcessingInstruction("pi", "data")), el("e")))));
        t.put("namespaces", o -> {
            Element root = new Element("root", D);
            root.addNamespaceDeclaration(Namespace.getNamespace("z", "urn:z"));
            root.addNamespaceDeclaration(P);
            root.addNamespaceDeclaration(Namespace.getNamespace("m", "urn:m"));
            Element pChild = new Element("child", P);
            pChild.setAttribute(new Attribute("own", "1", P));
            pChild.setAttribute(new Attribute("q", "2", Q));
            pChild.setAttribute(new Attribute("lang", "en", Namespace.XML_NAMESPACE));
            pChild.addNamespaceDeclaration(P);
            Element redeclared = new Element("again", P2);
            redeclared.addContent(new Element("inner", P));
            Element none = new Element("none");
            none.addContent(new Element("back", D));
            Element q = new Element("q", Q);
            q.setAttribute("x", "1");
            q.addNamespaceDeclaration(Namespace.getNamespace("b", "urn:b"));
            q.addNamespaceDeclaration(Namespace.getNamespace("a", "urn:a"));
            root.addContent(Arrays.asList(pChild, redeclared, none, new Element("same", D), q));
            return o.outputString(root);
        });
        t.put("document", o -> {
            Element root = el("rss", el("channel", el("title", "T")));
            root.setAttribute("version", "2.0");
            Document doc = new Document(root);
            DocType dt = new DocType("rss", "-//Netscape Communications//DTD RSS 0.91//EN",
                    "http://my.netscape.com/publish/formats/rss-0.91.dtd");
            dt.setInternalSubset("<!ENTITY e \"x\">");
            doc.setDocType(dt);
            doc.addContent(0, new ProcessingInstruction("xml-stylesheet", "href=\"a.xsl\" type=\"text/xsl\""));
            doc.addContent(1, new Comment(" top "));
            doc.addContent(new Comment(" end "));
            return o.outputString(doc);
        });
        t.put("documentSystemId", o -> {
            Document doc = new Document(new Element("opml"));
            doc.setDocType(new DocType("opml", "opml.dtd"));
            return o.outputString(doc);
        });
        t.put("documentNs", o -> {
            Element feed = new Element("feed", ATOM);
            feed.addContent(new Element("title", ATOM).setText("a & b"));
            return o.outputString(new Document(feed));
        });
        t.put("documentEmpty", o -> o.outputString(new Document()));
        t.put("documentText", o -> {
            Document doc = new Document();
            doc.addContent(new Text("\n  "));
            doc.addContent(new Comment(" c "));
            doc.addContent(new Text(" "));
            doc.addContent(el("root", " x "));
            doc.addContent(new Text("\r\n\t"));
            doc.addContent(new Text(""));
            return o.outputString(doc);
        });
        t.put("docType", o -> {
            DocType dt = new DocType("html", "-//W3C//DTD XHTML 1.0 Strict//EN", null);
            dt.setInternalSubset("<!ENTITY nbsp \"&#160;\">\n");
            return o.outputString(dt);
        });
        t.put("nonAscii", o -> {
            Element e = el("a", NON_ASCII, new CDATA(NON_ASCII));
            e.setAttribute("v", NON_ASCII);
            return o.outputString(e);
        });
        t.put("cp1252", o -> o.outputString(el("a", "€“œŸ\u0080\u0081\u008d Ā")));
        t.put("contentList", o -> {
            Element content = new Element("content", ATOM);
            content.setAttribute("type", "xhtml");
            Element div = new Element("div", XHTML);
            Element p = new Element("p", XHTML);
            p.addContent("Hi & <bye>");
            div.addContent(Arrays.asList(new Text("\n  "), p, new Text("\n")));
            content.addContent(Arrays.asList(new Text("\n    "), div, new Text("\n  ")));
            return o.outputString(content.getContent());
        });
        t.put("contentListText", o -> {
            Element desc = el("description", "  Hello ", el("b", "world"), new Comment("c"), " &amp; bye\n");
            return o.outputString(desc.getContent());
        });
        t.put("text", o -> o.outputString(new Text("  a\nb <&>\r\t\"'  ")));
        t.put("cdataNode", o -> o.outputString(new CDATA("  c <&> d  ")));
        t.put("comment", o -> o.outputString(new Comment(" note <&> ")));
        t.put("pi", o -> o.outputString(new ProcessingInstruction("target")) + "|"
                + o.outputString(new ProcessingInstruction("xml-stylesheet", "href=\"a.xsl\"")) + "|"
                + o.outputString(new ProcessingInstruction("javax.xml.transform.disable-output-escaping", "")));
        t.put("xmlSpace", o -> {
            Element pre = el("pre", "  x  ", el("b", " y "), el("c", el("d")));
            pre.setAttribute("space", "preserve", Namespace.XML_NAMESPACE);
            Element def = el("n", "  z  ", el("m", "  w "));
            def.setAttribute("space", "default", Namespace.XML_NAMESPACE);
            pre.addContent(def);
            return o.outputString(el("root", pre, el("after", " k ")));
        });
        t.put("trax", o -> {
            Element x = el("x", "<i>");
            x.setAttribute("a", "<&>");
            return o.outputString(el("root", "<a>",
                    new ProcessingInstruction("javax.xml.transform.disable-output-escaping", ""), "<b>&", x,
                    new ProcessingInstruction("javax.xml.transform.enable-output-escaping", ""), "<c>"));
        });
        t.put("charsets", o -> {
            Element e = el("a", CHARSET_SAMPLE);
            e.setAttribute("v", CHARSET_SAMPLE);
            return o.outputString(e);
        });
        return t;
    }

    static Map<String, Supplier<Format>> formats() {
        Map<String, Supplier<Format>> f = new LinkedHashMap<>();
        f.put("raw", Format::getRawFormat);
        f.put("compact", Format::getCompactFormat);
        f.put("pretty", Format::getPrettyFormat);
        f.put("trimFullWhite", () -> Format.getRawFormat().setTextMode(Format.TextMode.TRIM_FULL_WHITE));
        f.put("trimNoIndent", () -> Format.getRawFormat().setTextMode(Format.TextMode.TRIM));
        f.put("prettyTabs", () -> Format.getPrettyFormat().setIndent("\t").setLineSeparator("\n")
                .setExpandEmptyElements(true));
        f.put("prettyNormalize", () -> Format.getPrettyFormat().setTextMode(Format.TextMode.NORMALIZE)
                .setLineSeparator("\n"));
        f.put("prettyPreserve", () -> Format.getPrettyFormat().setTextMode(Format.TextMode.PRESERVE));
        f.put("rawNoSeparator", () -> Format.getRawFormat().setLineSeparator("").setOmitEncoding(true));
        f.put("compactAscii", () -> Format.getCompactFormat().setEncoding("US-ASCII"));
        f.put("prettyLatin1", () -> Format.getPrettyFormat().setEncoding("ISO-8859-1").setOmitDeclaration(true));
        f.put("rawCp1252", () -> Format.getRawFormat().setEncoding("windows-1252"));
        f.put("rawUtf16le", () -> Format.getRawFormat().setEncoding("UTF-16LE"));
        f.put("rawUnknown", () -> Format.getRawFormat().setEncoding("x-no-such-encoding"));
        for (String encoding : new String[] {"windows-1251", "KOI8-R", "ISO-8859-5", "GBK", "Shift_JIS", "Big5",
                "IBM866", "Cp866", "ISO8859_5", "EUC-KR"}) {
            f.put("raw:" + encoding, () -> Format.getRawFormat().setEncoding(encoding));
        }
        return f;
    }

    static String quote(String s) {
        StringBuilder sb = new StringBuilder("'");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '\'': sb.append("\\'"); break;
                case '\r': sb.append("\\r"); break;
                case '\n': sb.append("\\n"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    if (c < 0x20 || c > 0x7e) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
            }
        }
        return sb.append("'").toString();
    }

    public static void main(String[] args) throws java.io.IOException {
        String jdk = System.getProperty("java.vendor.version", "") + " " + System.getProperty("java.runtime.version");
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        List<String> lines = new ArrayList<>();
        for (Map.Entry<String, Function<XMLOutputter, String>> tree : trees().entrySet()) {
            for (Map.Entry<String, Supplier<Format>> format : formats().entrySet()) {
                String out = tree.getValue().apply(new XMLOutputter(format.getValue().get()));
                lines.add("  ['" + tree.getKey() + "/" + format.getKey() + "', " + quote(out) + "]");
            }
        }
        Format format = Format.getRawFormat();
        XMLOutputter outputter = new XMLOutputter(format);
        format.setOmitDeclaration(true);
        lines.add("  ['formatIsCloned', " + quote(outputter.outputString(new Document(new Element("a")))) + "]");
        String file = "// Generated by tools/xml-oracle/XmlOutputterOracle.java from JDOM 2.0.6.1 on " + jdk.trim() + "; regenerate, do not edit\n"
                + "export const XML_OUTPUTTER_EXPECTED: Map<string, string> = new Map<string, string>([\n"
                + String.join(",\n", lines) + "\n]);\n";
        java.nio.file.Files.writeString(java.nio.file.Path.of("oh_rome/src/test/XmlOutputterExpected.ets"), file);
    }
}
