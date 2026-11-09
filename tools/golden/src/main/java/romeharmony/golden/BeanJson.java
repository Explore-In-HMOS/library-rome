package romeharmony.golden;

import org.jdom2.Content;
import org.jdom2.Element;
import org.jdom2.Namespace;
import org.jdom2.output.Format;
import org.jdom2.output.XMLOutputter;

import java.beans.IntrospectionException;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Array;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.net.URI;
import java.net.URL;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Currency;
import java.util.Date;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Turns ROME objects into the JSON tree the goldens store: bean properties by Java name, read through getters.
 *
 * <p>The format is the contract with the ArkTS comparator (oh_rome/src/test/golden/Compare.ets):
 * <ul>
 * <li>Beans: object of property name to value, minus {@link #EXCLUDED} and the class's CONVENIENCE_PROPERTIES.</li>
 * <li>Date: ISO-8601 UTC with milliseconds. Enum: name(). URL, URI, BigDecimal, Locale and the type-safe-enum classes
 * in {@link #TO_STRING_CLASSES}: toString(). Currency: code.</li>
 * <li>JDOM Element or other Content: XMLOutputter raw-format string. JDOM Namespace: {"prefix", "uri"} (our Namespace fields).</li>
 * <li>List and arrays: JSON array. Set: {"$set": [...]} (order-free). Map: object with String.valueOf(key).</li>
 * <li>float/double: the Java decimal string as a JSON number; NaN/Infinity as strings.</li>
 * <li>Exceptions: {"$exception": simple class name, "message": text} with the message only when ROME itself produced it.</li>
 * </ul>
 */
final class BeanJson {

    // Properties that are not data: computed from other properties, ROME internals, or reflection noise.
    private static final Map<String, Set<String>> EXCLUDED = Map.ofEntries(
            Map.entry("*", Set.of("class", "interface")),
            Map.entry("com.rometools.rome.feed.synd.SyndFeedImpl", Set.of("title", "description", "supportedFeedTypes", "preservingWireFeed")),
            Map.entry("com.rometools.rome.feed.synd.SyndEntryImpl", Set.of("title", "wireEntry")),
            // Getters computed from other properties that the goldens already hold (titleEx, published, updated,
            // otherLinks, subtitle, rights, uri), with no state of their own.
            Map.entry("com.rometools.rome.feed.atom.Entry", Set.of("title", "issued", "modified", "mediaEntry")),
            Map.entry("com.rometools.rome.feed.atom.Feed", Set.of("title", "tagline", "copyright", "modified")),
            Map.entry("com.rometools.rome.feed.atom.Person", Set.of("url")),
            Map.entry("com.rometools.modules.mediarss.types.Hash", Set.of("algorithm")),
            // explicitNullable with null as false (AbstractITunesObject.java:129-135); the first subcategory
            // (types/Category.java:69-70); values from attributes (Outline.java:217-218,226-227,301-302).
            Map.entry("com.rometools.modules.itunes.AbstractITunesObject", Set.of("explicit")),
            Map.entry("com.rometools.modules.itunes.types.Category", Set.of("subcategory")),
            Map.entry("com.rometools.opml.feed.opml.Outline", Set.of("url", "htmlUrl", "xmlUrl")),
            // The first of links (AtomLinkModuleImpl.java:41-46).
            Map.entry("com.rometools.modules.atom.modules.AtomLinkModuleImpl", Set.of("link")),
            // The point geometry's position, or null (GeoRSSModule.java:223-228).
            Map.entry("com.rometools.modules.georss.GeoRSSModule", Set.of("position")));

    // Type-safe-enum classes (a private value, toString() returns it, no bean properties): written as toString(),
    // which is what the port stores; as beans they would serialize as {} and lose the value.
    private static final Set<String> TO_STRING_CLASSES = Set.of(
            "com.rometools.modules.mediarss.types.Expression",
            "com.rometools.modules.mediarss.types.Restriction$Relationship",
            "com.rometools.modules.mediarss.types.Restriction$Type",
            "com.rometools.modules.cc.types.License$Behaviour");

    // Same text as JavaScript Date.prototype.toISOString for years 0000-9999.
    private static final DateTimeFormatter ISO = DateTimeFormatter.ofPattern("uuuu-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC);

    private final IdentityHashMap<Object, Boolean> path = new IdentityHashMap<>();

    Object value(final Object v) {
        if (v == null || v instanceof String || v instanceof Boolean) {
            return v;
        }
        if (v instanceof Character) {
            return v.toString();
        }
        if (v instanceof Float || v instanceof Double) {
            final double d = ((Number) v).doubleValue();
            return Double.isNaN(d) || Double.isInfinite(d) ? String.valueOf(v) : new Json.RawNumber(String.valueOf(v));
        }
        if (v instanceof Byte || v instanceof Short || v instanceof Integer || v instanceof Long) {
            return new Json.RawNumber(String.valueOf(v));
        }
        if (v instanceof Date) {
            return ISO.format(Instant.ofEpochMilli(((Date) v).getTime()));
        }
        if (v instanceof Enum<?>) {
            return ((Enum<?>) v).name();
        }
        if (v instanceof URL || v instanceof URI || v instanceof BigDecimal || v instanceof Locale
                || TO_STRING_CLASSES.contains(v.getClass().getName())) {
            return v.toString();
        }
        if (v instanceof Currency) {
            return ((Currency) v).getCurrencyCode();
        }
        if (v instanceof Namespace) {
            final Map<String, Object> ns = new TreeMap<>();
            ns.put("prefix", ((Namespace) v).getPrefix());
            ns.put("uri", ((Namespace) v).getURI());
            return ns;
        }
        if (v instanceof Element || v instanceof Content) {
            final XMLOutputter out = new XMLOutputter(Format.getRawFormat());
            return v instanceof Element ? out.outputString((Element) v) : out.outputString(List.of((Content) v));
        }
        enter(v);
        try {
            if (v instanceof Set<?>) {
                final List<Object> items = new ArrayList<>();
                for (final Object o : (Set<?>) v) {
                    items.add(value(o));
                }
                final Map<String, Object> set = new TreeMap<>();
                set.put("$set", items);
                return set;
            }
            if (v instanceof Collection<?>) {
                final List<Object> items = new ArrayList<>();
                for (final Object o : (Collection<?>) v) {
                    items.add(value(o));
                }
                return items;
            }
            if (v.getClass().isArray()) {
                final List<Object> items = new ArrayList<>();
                for (int i = 0; i < Array.getLength(v); i++) {
                    items.add(value(Array.get(v, i)));
                }
                return items;
            }
            if (v instanceof Map<?, ?>) {
                final Map<String, Object> map = new TreeMap<>();
                for (final Map.Entry<?, ?> e : ((Map<?, ?>) v).entrySet()) {
                    map.put(String.valueOf(e.getKey()), value(e.getValue()));
                }
                return map;
            }
            return bean(v);
        } finally {
            path.remove(v);
        }
    }

    private void enter(final Object v) {
        if (path.put(v, Boolean.TRUE) != null) {
            throw new IllegalStateException("reference cycle through " + v.getClass().getName());
        }
    }

    private Map<String, Object> bean(final Object v) {
        final Class<?> cls = v.getClass();
        if (!cls.getName().startsWith("com.rometools.")) {
            throw new IllegalStateException("no JSON rule for " + cls.getName() + "; add one to BeanJson and Compare.ets");
        }
        final Map<String, Object> out = new TreeMap<>();
        final PropertyDescriptor[] props;
        try {
            props = Introspector.getBeanInfo(cls, Object.class).getPropertyDescriptors();
        } catch (final IntrospectionException e) {
            throw new IllegalStateException(e);
        }
        for (final PropertyDescriptor p : props) {
            final Method read = p.getReadMethod();
            if (read == null || read.getParameterCount() != 0 || excluded(cls, p.getName())) {
                continue;
            }
            try {
                out.put(p.getName(), value(read.invoke(v)));
            } catch (final InvocationTargetException e) {
                out.put(p.getName(), exception((Exception) e.getCause()));
            } catch (final IllegalAccessException e) {
                throw new IllegalStateException(e);
            }
        }
        return out;
    }

    private static boolean excluded(final Class<?> cls, final String property) {
        if (EXCLUDED.get("*").contains(property) || convenienceProperties(cls).contains(property)) {
            return true;
        }
        for (Class<?> c = cls; c != null; c = c.getSuperclass()) {
            if (EXCLUDED.getOrDefault(c.getName(), Set.of()).contains(property)) {
                return true;
            }
        }
        return false;
    }

    @SuppressWarnings("unchecked")
    private static Set<String> convenienceProperties(final Class<?> cls) {
        for (Class<?> c = cls; c != null; c = c.getSuperclass()) {
            try {
                return (Set<String>) c.getField("CONVENIENCE_PROPERTIES").get(null);
            } catch (final NoSuchFieldException e) {
                continue;
            } catch (final IllegalAccessException e) {
                throw new IllegalStateException(e);
            }
        }
        return Set.of();
    }

    static Map<String, Object> exception(final Exception e) {
        final Map<String, Object> out = new TreeMap<>();
        out.put("$exception", e.getClass().getSimpleName());
        if (romeMessage(e)) {
            out.put("message", e.getMessage());
        }
        return out;
    }

    // ROME's own messages are part of the behavior; XML parser and JDK messages are not.
    private static boolean romeMessage(final Throwable e) {
        for (Throwable c = e.getCause(); c != null; c = c.getCause()) {
            if (!c.getClass().getName().startsWith("com.rometools.")) {
                return false;
            }
        }
        if (e.getClass().getName().startsWith("com.rometools.")) {
            return true;
        }
        final StackTraceElement[] st = e.getStackTrace();
        return st.length > 0 && st[0].getClassName().startsWith("com.rometools.") && e instanceof RuntimeException
                && !(e instanceof NullPointerException) && !(e instanceof ClassCastException)
                && !(e instanceof IndexOutOfBoundsException);
    }
}
