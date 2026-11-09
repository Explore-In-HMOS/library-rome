package romeharmony.golden;

import java.util.List;
import java.util.Map;

/** Minimal JSON writer for the trees BeanJson builds (Map with String keys, List, String, Boolean, RawNumber, null). */
final class Json {

    /** A number written exactly as Java prints it (e.g. "1.0", "0.1" for 0.1f). */
    static final class RawNumber {
        final String text;

        RawNumber(final String text) {
            this.text = text;
        }
    }

    private Json() {
    }

    static String write(final Object v) {
        final StringBuilder sb = new StringBuilder();
        write(v, sb);
        return sb.toString();
    }

    private static void write(final Object v, final StringBuilder sb) {
        if (v == null) {
            sb.append("null");
        } else if (v instanceof String) {
            string((String) v, sb);
        } else if (v instanceof Boolean) {
            sb.append(v.toString());
        } else if (v instanceof RawNumber) {
            sb.append(((RawNumber) v).text);
        } else if (v instanceof Map<?, ?>) {
            sb.append('{');
            boolean first = true;
            for (final Map.Entry<?, ?> e : ((Map<?, ?>) v).entrySet()) {
                if (!first) {
                    sb.append(',');
                }
                first = false;
                string((String) e.getKey(), sb);
                sb.append(':');
                write(e.getValue(), sb);
            }
            sb.append('}');
        } else if (v instanceof List<?>) {
            sb.append('[');
            boolean first = true;
            for (final Object o : (List<?>) v) {
                if (!first) {
                    sb.append(',');
                }
                first = false;
                write(o, sb);
            }
            sb.append(']');
        } else {
            throw new IllegalStateException("not a JSON tree value: " + v.getClass().getName());
        }
    }

    private static void string(final String s, final StringBuilder sb) {
        sb.append('"');
        for (int i = 0; i < s.length(); i++) {
            final char c = s.charAt(i);
            switch (c) {
                case '"':
                    sb.append("\\\"");
                    break;
                case '\\':
                    sb.append("\\\\");
                    break;
                case '\n':
                    sb.append("\\n");
                    break;
                case '\r':
                    sb.append("\\r");
                    break;
                case '\t':
                    sb.append("\\t");
                    break;
                default:
                    if (c < 0x20 || c == 0x2028 || c == 0x2029 || Character.isSurrogate(c)) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
            }
        }
        sb.append('"');
    }
}
