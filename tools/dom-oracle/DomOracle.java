// Runs JDOM 2.0.6.1 over every Dom constructor and setter that validates its input, with legal and illegal names,
// character data, namespaces and namespace collisions, and writes oh_rome/src/test/DomVerifierCases.ets with the
// result or the exception's simple class name and exact message. "sweep ..." cases try every UTF-16 code unit and
// record the legal ones.
// Usage (from the repo root): java -cp <jdom2-2.0.6.1.jar> tools/dom-oracle/DomOracle.java
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;
import org.jdom2.*;

public class DomOracle {
    static final String XML_URI = "http://www.w3.org/XML/1998/namespace";
    static final String XMLNS_URI = "http://www.w3.org/2000/xmlns/";

    static String dump(Element e) {
        List<String> ns = new ArrayList<>();
        for (Namespace n : e.getAdditionalNamespaces()) ns.add(n.getPrefix() + "=" + n.getURI());
        List<String> attrs = new ArrayList<>();
        for (Attribute a : e.getAttributes()) attrs.add(a.getQualifiedName() + "{" + a.getNamespaceURI() + "}=" + a.getValue());
        return e.getQualifiedName() + "{" + e.getNamespaceURI() + "} ns[" + String.join(",", ns) + "] a[" + String.join(",", attrs) + "]";
    }

    // getContent(i), not getContent(): JDOM's getContent() throws without a root element.
    static String dump(Document d) {
        List<String> parts = new ArrayList<>();
        for (int i = 0; i < d.getContentSize(); i++) {
            Content c = d.getContent(i);
            if (c instanceof Element) parts.add("Element:" + ((Element) c).getQualifiedName());
            else if (c instanceof DocType) parts.add("DocType:" + ((DocType) c).getElementName());
            else parts.add(c.getCType() + ":" + c.getValue());
        }
        return String.join(",", parts);
    }

    static Content node(String spec) {
        String text = spec.substring(spec.indexOf(':') + 1);
        switch (spec.substring(0, spec.indexOf(':'))) {
            case "Element": return new Element(text);
            case "Text": return new Text(text);
            case "CDATA": return new CDATA(text);
            case "Comment": return new Comment(text);
            case "PI": return new ProcessingInstruction(text);
            case "DocType": return new DocType(text);
            default: throw new IllegalStateException(spec);
        }
    }

    // A document with the given content, added in order with addContent.
    static Document doc(String[] a, int from) {
        Document d = new Document();
        for (int i = from; i < a.length; i++) d.addContent(node(a[i]));
        return d;
    }

    // The element every collision case starts from: namespace (a0, a1), a declaration p, an attribute q:at.
    static Element scenario(String[] a) {
        Element e = new Element("e", Namespace.getNamespace(a[0], a[1]));
        e.addNamespaceDeclaration(Namespace.getNamespace("p", "urn:p"));
        e.setAttribute(new Attribute("at", "v", Namespace.getNamespace("q", "urn:q")));
        return e;
    }

    static String run(String op, String[] a) {
        switch (op) {
            case "Namespace.getNamespace(uri)": { Namespace n = Namespace.getNamespace(a[0]); return n.getPrefix() + "|" + n.getURI(); }
            case "Namespace.getNamespace": { Namespace n = Namespace.getNamespace(a[0], a[1]); return n.getPrefix() + "|" + n.getURI(); }
            case "Element": new Element(a[0]); return "";
            case "Element(ns)": return dump(new Element(a[0], Namespace.getNamespace(a[1], a[2])));
            case "Element.setName": return dump(new Element("a").setName(a[0]));
            case "Element.setText": return new Element("a").setText(a[0]).getText();
            case "Element.addContent": return new Element("a").addContent(a[0]).getText();
            case "Element.setAttribute": return dump(new Element("a").setAttribute(a[0], a[1]));
            case "Element.setAttribute(ns)": return dump(new Element("a").setAttribute(a[0], a[1], Namespace.getNamespace(a[2], a[3])));
            case "Attribute": new Attribute(a[0], a[1]); return "";
            case "Attribute(ns)": return new Attribute(a[0], a[1], Namespace.getNamespace(a[2], a[3])).getQualifiedName();
            case "Attribute.setName": return new Attribute("a", "v").setName(a[0]).getName();
            case "Attribute.setValue": return new Attribute("a", "v").setValue(a[0]).getValue();
            case "Attribute.setNamespace": return new Attribute("a", "v").setNamespace(Namespace.getNamespace(a[0], a[1])).getQualifiedName();
            case "Text": return new Text(a[0]).getText();
            case "Text.setText": return new Text("x").setText(a[0]).getText();
            case "Text.append": { Text t = new Text(a[0]); t.append(a[1]); return t.getText(); }
            case "CDATA": return new CDATA(a[0]).getText();
            case "CDATA.setText": return new CDATA("x").setText(a[0]).getText();
            case "CDATA.append": { CDATA t = new CDATA(a[0]); t.append(a[1]); return t.getText(); }
            case "Comment": return new Comment(a[0]).getText();
            case "ProcessingInstruction": new ProcessingInstruction(a[0], a[1]); return "";
            case "DocType": new DocType(a[0], a[1], a[2]); return "";
            case "addNamespaceDeclaration": {
                Element e = scenario(a);
                boolean added = e.addNamespaceDeclaration(Namespace.getNamespace(a[2], a[3]));
                return added + " " + dump(e);
            }
            case "setNamespace": { Element e = scenario(a); e.setNamespace(Namespace.getNamespace(a[2], a[3])); return dump(e); }
            case "setAttribute(Attribute)": {
                Element e = scenario(a);
                e.setAttribute(new Attribute(a[4], "w", Namespace.getNamespace(a[2], a[3])));
                return dump(e);
            }
            case "setAttribute(name, value, ns)": {
                Element e = scenario(a);
                e.setAttribute(a[4], "w", Namespace.getNamespace(a[2], a[3]));
                return dump(e);
            }
            case "Document.addContent": return dump(doc(a, 0));
            case "Document.addContent(index)": {
                Document d = doc(a, 2);
                d.addContent(Integer.parseInt(a[0]), node(a[1]));
                return dump(d);
            }
            case "Element.addContent(index)": {
                // a[0]: the index, a[1]: the node, a[2]...: the element's content before.
                Element e = new Element("e");
                for (int i = 2; i < a.length; i++) e.addContent(node(a[i]));
                e.addContent(Integer.parseInt(a[0]), node(a[1]));
                return e.getValue();
            }
            case "setAttribute(parented)": {
                // a[0]: where the attribute, already set on f:first, is set again.
                Element first = new Element("first", Namespace.getNamespace("f", "urn:f"));
                Attribute at = new Attribute("at", "v", Namespace.getNamespace("p", "urn:p"));
                first.setAttribute(at);
                switch (a[0]) {
                    case "other": new Element("other").setAttribute(at); return "";
                    case "colliding other": new Element("other", Namespace.getNamespace("p", "urn:other")).setAttribute(at); return "";
                    case "same": first.setAttribute(at); return "";
                    case "detached": {
                        at.detach();
                        Element other = new Element("other");
                        other.setAttribute(at);
                        return dump(other) + " " + dump(first);
                    }
                    case "same name": {
                        first.setAttribute(new Attribute("at", "w", Namespace.getNamespace("p", "urn:p")));
                        return dump(first) + " " + (at.getParent() == null);
                    }
                    default: throw new IllegalStateException(a[0]);
                }
            }
            case "Document.setRootElement": { Document d = doc(a, 1); d.setRootElement(new Element(a[0])); return dump(d); }
            case "Document.setDocType": { Document d = doc(a, 1); d.setDocType(new DocType(a[0])); return dump(d); }
            case "add parented": {
                // a[0]: the node, a[1]: its first parent (element or document), a[2]: where it is added again.
                Content child = node(a[0]);
                Element firstElement = new Element("first");
                Document firstDoc = new Document();
                if (a[1].equals("element")) firstElement.addContent(child); else firstDoc.addContent(child);
                Element other = new Element("other");
                Document otherDoc = new Document();
                switch (a[2]) {
                    case "element": other.addContent(child); return "";
                    case "element at 5": other.addContent(5, child); return "";
                    case "document at 5": otherDoc.addContent(5, child); return dump(otherDoc);
                    case "document": otherDoc.addContent(child); return dump(otherDoc);
                    case "same element": firstElement.addContent(child); return "";
                    case "same document": firstDoc.addContent(child); return dump(firstDoc);
                    case "setRootElement": firstDoc.setRootElement((Element) child); return dump(firstDoc);
                    case "new Document": return dump(new Document((Element) child));
                    case "setDocType": otherDoc.setDocType((DocType) child); return dump(otherDoc);
                    default: throw new IllegalStateException(a[2]);
                }
            }
            case "add self or ancestor": {
                // root > b > c; a[0] is added to a[1].
                Element root = new Element("root");
                Element b = new Element("b");
                Element c = new Element("c");
                root.addContent(b);
                b.addContent(c);
                Map<String, Element> m = Map.of("root", root, "b", b, "c", c);
                m.get(a[1]).addContent(m.get(a[0]));
                return "";
            }
            case "Element.addContent(DocType)": new Element("a").addContent(new DocType("a")); return "";
            case "Element.addContent(list)": {
                // The list fails at its last node: the earlier nodes must not stay added.
                Element e = new Element("e");
                e.addContent(new Text("t"));
                Element parented = new Element("p");
                new Element("x").addContent(parented);
                try {
                    e.addContent(Arrays.asList(new Element(a[0]), new Comment(a[1]), parented));
                } catch (IllegalArgumentException ex) {
                    return e.getContentSize() + " " + e.getValue() + " " + ex.getMessage();
                }
                return "added";
            }
            case "Element.setContent(list)": {
                Element e = new Element("e");
                Text old = new Text("old");
                e.addContent(old);
                Element parented = new Element("p");
                new Element("x").addContent(parented);
                try {
                    e.setContent(Arrays.asList(new Text(a[0]), parented));
                } catch (IllegalArgumentException ex) {
                    return e.getContentSize() + " " + e.getValue() + " " + (old.getParent() == e) + " " + ex.getMessage();
                }
                return "set";
            }
            default: throw new IllegalStateException(op);
        }
    }

    static String result(String op, String[] a) {
        try {
            return "OK " + run(op, a);
        } catch (RuntimeException e) {
            // The port throws a plain Error where Java throws an unchecked exception other than IllegalArgumentException.
            String name = e instanceof IllegalArgumentException ? e.getClass().getSimpleName() : "Error";
            return "ERR " + name + ": " + e.getMessage();
        }
    }

    // The legal code units as ranges, e.g. "0009-000a,000d,0020-d7ff".
    static String sweep(Consumer<String> op) {
        List<String> ranges = new ArrayList<>();
        int start = -1;
        for (int c = 0; c <= 0x10000; c++) {
            boolean ok = false;
            if (c < 0x10000) {
                try {
                    op.accept(String.valueOf((char) c));
                    ok = true;
                } catch (IllegalArgumentException e) {
                    ok = false;
                }
            }
            if (ok && start < 0) start = c;
            if (!ok && start >= 0) {
                ranges.add(start == c - 1 ? String.format("%04x", start) : String.format("%04x-%04x", start, c - 1));
                start = -1;
            }
        }
        return String.join(",", ranges);
    }

    // ASCII-only string literal, so lone surrogates and control characters survive any editor or encoding.
    static String q(String s) {
        if (s == null) return "null";
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

    static final List<String> entries = new ArrayList<>();

    static void add(String op, String... a) {
        String expected = result(op, a);
        List<String> args = new ArrayList<>();
        for (String s : a) args.add(q(s));
        entries.add("  c(" + q(op) + ", [" + String.join(", ", args) + "], " + q(expected) + ")");
    }

    static void addSweep(String op, Consumer<String> run) {
        entries.add("  c(" + q(op) + ", [], " + q(sweep(run)) + ")");
    }

    public static void main(String[] args) throws Exception {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        String[] names = {"a", "a1", "_a", "a-b", "a.b", "a·b", "·a", "1a", "-a", ".a", "", "a:b", ":a", "a:",
            "xml", "xmlns", "XmlNs", "xmlfoo", "a b", "a\tb", "é", "̀a", "à", "ๆa", "aๆ",
            "日本", "〇", "𐀀", "a𐀀", "a\ud800", "a￿", "a\u0000", "a!b", "a!b?c",
            "a>"};
        String[] data = {"", "plain", "tab\tnl\ncr\r", "\u0000", "a\u0001b", "\u0008", "\u000b", "\u000c", "\u000e",
            "\u001f", " ", "\u007f", "\u0080", "\u0085", " ", "퟿", "", "�", "￾", "￿",
            "x𐀀y", "􏿿", "a\ud800", "\ud800a", "\udc00", "\udc00\ud800", "a\ud800\ud800",
            "]]>", "a]]>b", "]]", "]>", "--", "a--b", "a-", "-a", "-", "a-b", "?>", "a?>b", "?", ">", "<&>\"'"};

        for (String n : names) {
            add("Element", n);
            add("Element.setName", n);
            add("Attribute", n, "v");
            add("Attribute.setName", n);
            add("DocType", n, null, null);
            add("ProcessingInstruction", n, "");
        }
        for (String t : new String[] {"pi", "xml-stylesheet", "XML", "xMl", "Xml", "xml2", "a:b"}) {
            add("ProcessingInstruction", t, "");
        }
        for (String d : data) {
            add("Text", d);
            add("Text.setText", d);
            add("Text.append", "x", d);
            add("CDATA", d);
            add("CDATA.setText", d);
            add("CDATA.append", "x", d);
            add("Comment", d);
            add("ProcessingInstruction", "pi", d);
            add("Attribute", "a", d);
            add("Attribute.setValue", d);
            add("Element.setText", d);
            add("Element.addContent", d);
            add("Element.setAttribute", "a", d);
            add("DocType", "a", null, d);
        }
        add("Element.setText", (String) null);
        String[][] appends = {{"]", "]>"}, {"]]", ">"}, {"]", "]"}, {"", "]]>"}, {"", ""}, {"a", "b\u0000"}, {"a", "\ud800"},
            {"a", "\udc00"}, {"a]", "]>b"}};
        for (String[] p : appends) {
            add("Text.append", p);
            add("CDATA.append", p);
        }

        String[] publicIds = {"", "-//Netscape Communications//DTD RSS 0.91//EN", "a\"b", "a'b", "a<b", "a\tb", "a\nb",
            "a\rb", "a{b", "a~b", "a`b", "a&b", "aéb", "a\\b", "a^b", "a|b", "a[b", "a]b", "!#$%_=*@;:/?.,()+'",
            "a\u0000b", "a>b"};
        for (String p : publicIds) add("DocType", "a", p, null);
        for (String s : new String[] {"a'b", "a\"b", "a'\"b", "http://my.netscape.com/publish/formats/rss-0.91.dtd"}) {
            add("DocType", "a", null, s);
        }
        add("DocType", "rss", "-//Netscape Communications//DTD RSS 0.91//EN", "http://my.netscape.com/publish/formats/rss-0.91.dtd");
        add("DocType", "1a", "a<b", "a'\"b");
        add("DocType", "a", "a<b", "a'\"b");

        String[] uris = {"urn:x", "http://a/b", "", null, "1abc", "9", "$x", "-x", " x", "\tx", "\nx", "\rx", "x y",
            "٣x", "１x", "²x", "Ⅷx", "_x", ".x", "x:", "%zz", "\u0000x", "éx", "\ud800",
            XML_URI, XMLNS_URI, XML_URI + "/"};
        String[] prefixes = {"", null, "a", "xml", "XML", "xmlns", "Xmlns", "xmlfoo", "1a", "a:b", "a b", "-a", "_a",
            "a.b", "é", "a\u0000"};
        for (String u : uris) {
            add("Namespace.getNamespace(uri)", u);
            add("Namespace.getNamespace", "", u);
            add("Namespace.getNamespace", null, u);
            add("Namespace.getNamespace", "p", u);
        }
        for (String p : prefixes) {
            for (String u : new String[] {"urn:x", "", null, XML_URI, XMLNS_URI, "1x"}) add("Namespace.getNamespace", p, u);
        }
        add("Element(ns)", "a", "p", "urn:p");
        add("Element(ns)", "a", "", "urn:x");
        add("Element(ns)", "a:b", "p", "urn:p");
        add("Element(ns)", "a", "xml", XML_URI);
        add("Element(ns)", "1a", "1p", "urn:p");
        add("Attribute(ns)", "a", "v", "p", "urn:p");
        add("Attribute(ns)", "a", "v", "", "urn:x");
        add("Attribute(ns)", "a", "v", "", "");
        add("Attribute(ns)", "a", "v", null, null);
        add("Attribute(ns)", "a", "v", "xml", XML_URI);
        add("Attribute(ns)", "xmlns", "v", "p", "urn:p");
        add("Attribute(ns)", "a", "\u0000", "", "urn:x");
        add("Attribute(ns)", "1a", "\u0000", "", "urn:x");
        add("Attribute.setNamespace", "p", "urn:p");
        add("Attribute.setNamespace", "", "urn:x");
        add("Attribute.setNamespace", null, null);
        add("Element.setAttribute(ns)", "a", "v", "p", "urn:p");
        add("Element.setAttribute(ns)", "a", "v", "", "urn:x");
        add("Element.setAttribute(ns)", "xmlns", "v", "p", "urn:p");

        String[][] elementNamespaces = {{"", ""}, {"", "urn:d"}, {"e", "urn:e"}};
        String[][] namespaces = {{"", ""}, {"", "urn:d"}, {"", "urn:other"}, {"e", "urn:e"}, {"e", "urn:other"},
            {"p", "urn:p"}, {"p", "urn:other"}, {"q", "urn:q"}, {"q", "urn:other"}, {"r", "urn:r"}, {"xml", XML_URI}};
        for (String[] en : elementNamespaces) {
            for (String[] ns : namespaces) {
                add("addNamespaceDeclaration", en[0], en[1], ns[0], ns[1]);
                add("setNamespace", en[0], en[1], ns[0], ns[1]);
                add("setAttribute(Attribute)", en[0], en[1], ns[0], ns[1], "x");
                add("setAttribute(Attribute)", en[0], en[1], ns[0], ns[1], "at");
                add("setAttribute(name, value, ns)", en[0], en[1], ns[0], ns[1], "at");
            }
        }

        for (String n : new String[] {"Element:e", "Text:t", "CDATA:c", "Comment:c", "PI:pi"}) {
            for (String where : new String[] {"element", "document", "same element", "same document", "element at 5",
                "document at 5"}) {
                add("add parented", n, "element", where);
            }
        }
        for (String where : new String[] {"element", "document", "same element", "same document", "setRootElement",
            "new Document"}) {
            add("add parented", "Element:e", "document", where);
        }
        // Other content whose parent is a document fails with JDOM's ClassCastException; Exceptions.test checks it.
        add("add parented", "DocType:d", "document", "setDocType");
        add("add parented", "Element:e", "element", "setRootElement");
        add("add parented", "Element:e", "element", "new Document");
        for (String[] p : new String[][] {{"root", "root"}, {"b", "b"}, {"root", "b"}, {"root", "c"}, {"b", "c"},
            {"c", "root"}}) {
            add("add self or ancestor", p);
        }
        add("Element.addContent(DocType)");
        add("Element.addContent(list)", "x", "y");
        add("Element.setContent(list)", "new");
        String[][] documents = {{"Element:r"}, {"Element:r", "Element:r2"}, {"DocType:d", "Element:r"},
            {"Element:r", "DocType:d"}, {"DocType:d", "DocType:d2"},
            {"Comment:c", "DocType:d", "PI:p", "Element:r", "Comment:z"}, {"Text: \n\t\r"}, {"Text: "}, {"Text:"},
            {"Text:x"}, {"Text: x "}, {"Text:\u00a0"}, {"CDATA: "}, {"CDATA:"}, {"Element:r", "Text:\n"}};
        for (String[] d : documents) add("Document.addContent", d);
        String[][] indexed = {{"0", "Element:r2", "Element:r"}, {"0", "Element:r", "DocType:d"},
            {"1", "Element:r", "DocType:d"}, {"0", "DocType:d", "Element:r"}, {"1", "DocType:d", "Element:r"},
            {"1", "DocType:d", "Comment:c", "Element:r"}, {"0", "DocType:d2", "DocType:d"}, {"0", "Text:x", "Element:r"},
            {"0", "Text: ", "Element:r"}, {"0", "Comment:c", "DocType:d", "Element:r"}, {"0", "Comment:c"},
            {"1", "Comment:c"}, {"1", "Comment:c", "Element:r"}, {"2", "Comment:c", "Element:r"},
            {"-1", "Comment:c", "Element:r"}, {"3", "Element:r2", "Element:r"}};
        for (String[] d : indexed) add("Document.addContent(index)", d);
        String[][] elementIndexed = {{"0", "Text:x"}, {"1", "Text:x"}, {"-1", "Text:x", "Text:a"},
            {"0", "Text:x", "Text:a", "Text:b"}, {"1", "Text:x", "Text:a", "Text:b"}, {"2", "Text:x", "Text:a", "Text:b"},
            {"3", "Text:x", "Text:a", "Text:b"}, {"0", "DocType:d"}, {"3", "DocType:d", "Text:a"}};
        for (String[] d : elementIndexed) add("Element.addContent(index)", d);
        for (String where : new String[] {"other", "colliding other", "same", "detached", "same name"}) {
            add("setAttribute(parented)", where);
        }
        add("Document.setRootElement", "r2");
        add("Document.setRootElement", "r2", "Element:r");
        add("Document.setRootElement", "r2", "DocType:d", "Comment:c", "Element:r", "Comment:z");
        add("Document.setDocType", "d2");
        add("Document.setDocType", "d2", "Element:r");
        add("Document.setDocType", "d2", "Comment:c", "Element:r");
        add("Document.setDocType", "d2", "Comment:c", "DocType:d", "Element:r");

        addSweep("sweep Text", s -> new Text(s));
        addSweep("sweep Text pair low half", s -> new Text("\ud800" + s));
        addSweep("sweep Element name start", s -> new Element(s));
        addSweep("sweep Element name char", s -> new Element("a" + s));
        addSweep("sweep DocType name start", s -> new DocType(s));
        addSweep("sweep DocType name char", s -> new DocType("a" + s));
        addSweep("sweep DocType public ID", s -> new DocType("a", s, null));
        addSweep("sweep Namespace URI start", s -> Namespace.getNamespace("p", s + "x"));

        StringBuilder out = new StringBuilder();
        out.append("// Generated by tools/dom-oracle/DomOracle.java from JDOM 2.0.6.1. Do not edit.\n");
        out.append("export class DomVerifierCase {\n  op: string = '';\n  args: (string | null)[] = [];\n  expected: string = '';\n}\n\n");
        out.append("function c(op: string, args: (string | null)[], expected: string): DomVerifierCase {\n");
        out.append("  const r = new DomVerifierCase();\n  r.op = op;\n  r.args = args;\n  r.expected = expected;\n  return r;\n}\n\n");
        out.append("export const DOM_VERIFIER_CASES: DomVerifierCase[] = [\n");
        out.append(String.join(",\n", entries)).append("\n];\n");
        Files.writeString(Path.of("oh_rome/src/test/DomVerifierCases.ets"), out.toString(), StandardCharsets.UTF_8);
        System.out.println(entries.size() + " cases");
    }
}
