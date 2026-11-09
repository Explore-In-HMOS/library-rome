// Runs JDOM 2.0.6.1 configured exactly like ROME's WireFeedInput.createSAXBuilder() over cases.txt and writes
// oh_rome/src/test/XmlParserCases.ets: each case with the expected tree dump or the parse error.
// Usage (from the repo root), on Temurin 17.0.17+10: java -cp <jdom2-2.0.6.1.jar> tools/xml-oracle/XmlOracle.java
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import org.jdom2.*;
import org.jdom2.input.JDOMParseException;
import org.jdom2.input.SAXBuilder;
import org.jdom2.input.sax.XMLReaders;
import org.xml.sax.InputSource;

public class XmlOracle {
    static SAXBuilder builder(boolean allowDoctypes) {
        SAXBuilder b = new SAXBuilder(XMLReaders.NONVALIDATING);
        b.setEntityResolver((publicId, systemId) ->
            systemId != null && systemId.endsWith(".dtd") ? new InputSource(new StringReader("")) : null);
        b.setFeature("http://xml.org/sax/features/external-general-entities", false);
        b.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        b.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
        if (!allowDoctypes) {
            b.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        }
        b.setExpandEntities(false);
        return b;
    }

    // Same escaping as JSON.stringify, which escapes control characters and lone surrogates.
    static String q(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"': sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\b': sb.append("\\b"); break;
                case '\f': sb.append("\\f"); break;
                case '\n': sb.append("\\n"); break;
                case '\r': sb.append("\\r"); break;
                case '\t': sb.append("\\t"); break;
                default:
                    boolean paired = Character.isHighSurrogate(c) && i + 1 < s.length() && Character.isLowSurrogate(s.charAt(i + 1))
                        || Character.isLowSurrogate(c) && i > 0 && Character.isHighSurrogate(s.charAt(i - 1));
                    if (c < 0x20 || Character.isSurrogate(c) && !paired) sb.append(String.format("\\u%04x", (int) c));
                    else sb.append(c);
            }
        }
        return sb.append('"').toString();
    }

    // A string literal for the generated .ets file: q() plus escapes for U+2028/2029 and every surrogate.
    static String literal(String s) {
        StringBuilder sb = new StringBuilder();
        for (char c : q(s).toCharArray()) {
            if (c == 0x2028 || c == 0x2029 || Character.isSurrogate(c)) sb.append(String.format("\\u%04x", (int) c));
            else sb.append(c);
        }
        return sb.toString();
    }

    static String dump(Content c) {
        if (c instanceof Element) {
            Element e = (Element) c;
            List<String> ns = new ArrayList<>();
            for (Namespace n : e.getAdditionalNamespaces()) ns.add(q(n.getPrefix()) + "=" + q(n.getURI()));
            List<String> attrs = new ArrayList<>();
            for (Attribute a : e.getAttributes())
                attrs.add(q(a.getNamespacePrefix()) + ":" + q(a.getName()) + "{" + q(a.getNamespaceURI()) + "}=" + q(a.getValue()));
            List<String> kids = new ArrayList<>();
            for (Content k : e.getContent()) kids.add(dump(k));
            return "E" + q(e.getNamespacePrefix()) + ":" + q(e.getName()) + "{" + q(e.getNamespaceURI()) + "}ns["
                + String.join(",", ns) + "]a[" + String.join(",", attrs) + "]c[" + String.join(",", kids) + "]";
        }
        if (c instanceof CDATA) return "C" + q(((CDATA) c).getText());
        if (c instanceof Text) return "T" + q(((Text) c).getText());
        if (c instanceof Comment) return "M" + q(((Comment) c).getText());
        if (c instanceof ProcessingInstruction) {
            ProcessingInstruction p = (ProcessingInstruction) c;
            return "P" + q(p.getTarget()) + q(p.getData());
        }
        if (c instanceof DocType) {
            DocType d = (DocType) c;
            return "D" + q(d.getElementName()) + q(String.valueOf(d.getPublicID())) + q(String.valueOf(d.getSystemID()));
        }
        if (c instanceof EntityRef) return "R" + q(((EntityRef) c).getName());
        throw new IllegalStateException(c.getClass().getName());
    }

    static String run(String xml, boolean allowDoctypes) {
        try {
            Document doc = builder(allowDoctypes).build(new StringReader(xml));
            List<String> parts = new ArrayList<>();
            for (Content c : doc.getContent()) parts.add(dump(c));
            return "doc[" + String.join(",", parts) + "]";
        } catch (JDOMParseException e) {
            return "ERR L" + e.getLineNumber() + " " + e.getCause().getMessage();
        } catch (Exception e) {
            return "EXC " + e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    // {REPEAT n|text} stands for n copies of text, each with # replaced by its index. The generated file keeps it
    // compact and expands it with the same rule.
    static final java.util.regex.Pattern REPEAT = java.util.regex.Pattern.compile("\\{REPEAT (\\d+)\\|([^}]*)\\}");

    static String expand(String s) {
        java.util.regex.Matcher m = REPEAT.matcher(s);
        StringBuilder sb = new StringBuilder();
        while (m.find()) {
            StringBuilder copies = new StringBuilder();
            for (int k = 0; k < Integer.parseInt(m.group(1)); k++) copies.append(m.group(2).replace("#", String.valueOf(k)));
            m.appendReplacement(sb, java.util.regex.Matcher.quoteReplacement(copies.toString()));
        }
        m.appendTail(sb);
        return sb.toString();
    }

    // {CR}, {TAB} and {U+XXXX} in cases.txt stand for characters that are awkward to write literally.
    static String unescape(String s) {
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("\\{U\\+([0-9A-F]+)\\}").matcher(s.replace("{CR}", "\r").replace("{TAB}", "\t"));
        StringBuilder sb = new StringBuilder();
        while (m.find()) m.appendReplacement(sb, java.util.regex.Matcher.quoteReplacement(new String(Character.toChars(Integer.parseInt(m.group(1), 16)))));
        m.appendTail(sb);
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        String jdk = System.getProperty("java.vendor.version", "") + " " + System.getProperty("java.runtime.version");
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        List<String> lines = Files.readAllLines(Path.of("tools/xml-oracle/cases.txt"), StandardCharsets.UTF_8);
        StringBuilder out = new StringBuilder();
        out.append("// Generated by tools/xml-oracle/XmlOracle.java from tools/xml-oracle/cases.txt with JDOM 2.0.6.1 on " + jdk
            + ". Do not edit.\n");
        out.append("export class XmlParserCase {\n  name: string = '';\n  xml: string = '';\n");
        out.append("  allowDoctypes: boolean = false;\n  expected: string = '';\n}\n\n");
        out.append("function c(name: string, xml: string, allowDoctypes: boolean, expected: string): XmlParserCase {\n");
        out.append("  const r = new XmlParserCase();\n  r.name = name;\n  r.xml = xml;\n  r.allowDoctypes = allowDoctypes;\n");
        out.append("  r.expected = expected;\n  return r;\n}\n\n");
        out.append("function repeat(xml: string): string {\n  let out = '';\n  let from = 0;\n");
        out.append("  const pattern = /\\{REPEAT (\\d+)\\|([^}]*)\\}/g;\n  let m = pattern.exec(xml);\n  while (m !== null) {\n");
        out.append("    out += xml.substring(from, m.index);\n    for (let k = 0; k < Number(m[1]); k++) {\n");
        out.append("      out += m[2].replace(/#/g, String(k));\n    }\n    from = m.index + m[0].length;\n");
        out.append("    m = pattern.exec(xml);\n  }\n  return out + xml.substring(from);\n}\n\n");
        out.append("export const XML_PARSER_CASES: XmlParserCase[] = [\n");
        String name = null;
        boolean doctypes = false;
        StringBuilder body = new StringBuilder();
        List<String> entries = new ArrayList<>();
        for (int i = 0; i <= lines.size(); i++) {
            String line = i < lines.size() ? lines.get(i) : "### END";
            if (line.startsWith("### ")) {
                if (name != null) {
                    String xml = body.toString();
                    if (xml.endsWith("\n")) xml = xml.substring(0, xml.length() - 1);
                    xml = unescape(xml);
                    String expanded = expand(xml);
                    String expected = run(expanded, doctypes);
                    System.out.println(name + " => " + (expected.length() > 300 ? expected.substring(0, 300) + "..." : expected));
                    String input = expanded.equals(xml) ? literal(xml) : "repeat(" + literal(xml) + ")";
                    entries.add("  c(" + literal(name) + ", " + input + ", " + doctypes + ", " + literal(expected) + ")");
                }
                String header = line.substring(4).trim();
                doctypes = header.endsWith(" !doctypes");
                name = doctypes ? header.substring(0, header.length() - " !doctypes".length()) : header;
                body.setLength(0);
            } else {
                body.append(line).append('\n');
            }
        }
        out.append(String.join(",\n", entries)).append("\n];\n");
        Files.writeString(Path.of("oh_rome/src/test/XmlParserCases.ets"), out.toString(), StandardCharsets.UTF_8);
    }
}
