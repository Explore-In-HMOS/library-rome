// Runs ROME's mediarss model classes and writes oh_rome/src/test/MediarssCases.ets: Time parsing and formatting,
// the Community tag order, Credit roles, the clone/constructor behaviors the port replicates and each class's
// Java bean property names.
// Usage (from the repo root, JDK 17.0.17, en-US like the goldens; ROME = a checkout of rometools/rome at 6b4a7e8):
//   javac -g -d /tmp/rome-classes -cp jdom2-2.0.6.1.jar:slf4j-api-1.7.36.jar \
//     -sourcepath $ROME/rome/src/main/java:$ROME/rome-modules/src/main/java:$ROME/rome-utils/src/main/java \
//     $ROME/rome-modules/src/main/java/com/rometools/modules/mediarss/*.java \
//     $ROME/rome-modules/src/main/java/com/rometools/modules/mediarss/types/*.java
//   java -Duser.language=en -Duser.country=US -cp /tmp/rome-classes:jdom2-2.0.6.1.jar:slf4j-api-1.7.36.jar \
//     tools/mediarss-oracle/MediarssOracle.java
import com.rometools.modules.mediarss.MediaEntryModuleImpl;
import com.rometools.modules.mediarss.MediaModule;
import com.rometools.modules.mediarss.MediaModuleImpl;
import com.rometools.modules.mediarss.types.Category;
import com.rometools.modules.mediarss.types.Community;
import com.rometools.modules.mediarss.types.Credit;
import com.rometools.modules.mediarss.types.Embed;
import com.rometools.modules.mediarss.types.Expression;
import com.rometools.modules.mediarss.types.Hash;
import com.rometools.modules.mediarss.types.License;
import com.rometools.modules.mediarss.types.Location;
import com.rometools.modules.mediarss.types.MediaContent;
import com.rometools.modules.mediarss.types.MediaGroup;
import com.rometools.modules.mediarss.types.Metadata;
import com.rometools.modules.mediarss.types.PeerLink;
import com.rometools.modules.mediarss.types.PlayerReference;
import com.rometools.modules.mediarss.types.Price;
import com.rometools.modules.mediarss.types.Rating;
import com.rometools.modules.mediarss.types.Restriction;
import com.rometools.modules.mediarss.types.Scene;
import com.rometools.modules.mediarss.types.StarRating;
import com.rometools.modules.mediarss.types.Statistics;
import com.rometools.modules.mediarss.types.Status;
import com.rometools.modules.mediarss.types.SubTitle;
import com.rometools.modules.mediarss.types.Tag;
import com.rometools.modules.mediarss.types.Text;
import com.rometools.modules.mediarss.types.Thumbnail;
import com.rometools.modules.mediarss.types.Time;
import com.rometools.modules.mediarss.types.UrlReference;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Array;
import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;

public class MediarssOracle {
    static final String[] TIME_INPUTS = {
        // ROME's TimeTest and every time value in the rome-modules mediarss fixtures
        "12:05:35.3", "3:54.00001", "00:00:00.000", "00:01", "01:00", "00:15", "00:45",
        "0", "5", "59.999", "60", "61.5", "1.5", " 1.5 ", "\t2\n", "1.5f", "1.5D", "1e3", "1E-3", "1.", ".5", "+.5",
        "-1.5", "0.0001", "0.0005", "0.0015", "0.1", "0.2", "0.3", "35.3", "1:2:3", "1:2:3:4", "01:02:03.004",
        "-1:30", "1:-30", "-1:-1:-1", "+1:+2:+3", "1:+2", "100:00:00", "1000:00:00", "123456:00:00",
        "", " ", ":", "::", "1:", "1::", ":5", "::5", "a", "1:a", "a:1", "1:2:a", "1.5:2", " 1:2", "1 :2", "1: 2",
        "+", "-", "+:1", "-:1", "1:2:+", "NaN", "-NaN", "Infinity", "-Infinity", "+Infinity", "1:NaN", "NaNf",
        "1e20", "-1e20", "9e18", "1e400", "9223372036854775807:0", "9223372036854775808:0",
        "-9223372036854775808:0", "-9223372036854775809:0", "99999999999999999999:0", "153722867280912:55:0",
        "\u0661:\u0662:\u0663", "1:\u0663", "\u0663", "\uff11:\uff12:3", "0x10", "1_000", "1,5", "1.5.5", "--1",
        "1..", "..", "-1.2.3x", " a ", "1e5.5", ".", "1.5\u00a0", "\u00a01", "1:\u00a01",
        "1.5e3.", "0x1p3:1",
    };

    static final long[] TIME_MILLISECONDS = {
        0, 1, 9, 10, 99, 100, 999, 1000, 1001, 1010, 1100, 59999, 60000, 60001, 3599999, 3600000, 3600001,
        35999999, 36000000, 359999999, 3600000000L, 4442400000L, 4442400001L, 444240000000L, 3600000000000L,
        -1, -999, -1000, -59999, -60000, -3600000, -3600001, -4442400000L, -360000000000L,
        9007199254740991L, -9007199254740991L,
    };

    static final String[] TAG_SEQUENCES = {
        "a", "a b", "a:2 b:1", "a:1 b:2", "a:1 b:1", "a b:1", "a:3 b c:2 d:3 e:0 f:-1 g:2", "x:0 y:-5 z:10 w",
        "a:2147483647 b:-2147483648",
    };

    static final String[] CREDIT_ROLES = {
        "Director", "ACTOR", "producer", "\u0130STANBUL", "\u03a3\u0391\u03a3", "\u03a3", "STRASSE", "\u01c5", "\u2160", "",
    };

    static String q(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            if (c == '"') sb.append("\\\"");
            else if (c == '\\') sb.append("\\\\");
            else if (c < 0x20 || c > 0x7e) sb.append(String.format("\\u%04x", (int) c));
            else sb.append(c);
        }
        return sb.append('"').toString();
    }

    static String run(Callable<Object> f) {
        try {
            return String.valueOf(f.call());
        } catch (Exception e) {
            return e.getClass().getSimpleName() + ": " + e.getMessage();
        }
    }

    static String tags(String sequence) {
        Community community = new Community();
        for (String spec : sequence.split(" ")) {
            String[] parts = spec.split(":");
            community.getTags().add(new Tag(parts[0], parts.length > 1 ? Integer.valueOf(parts[1]) : null));
        }
        List<String> out = new ArrayList<>();
        for (Tag tag : community.getTags()) out.add(tag.getName() + ":" + tag.getWeight());
        return String.join(" ", out);
    }

    static Map<String, String> facts() throws Exception {
        Map<String, String> f = new LinkedHashMap<>();
        Metadata md = new Metadata();
        md.setCategories(new Category[] { new Category("s", "l", "v") });
        md.setTitle("t");
        Metadata copy = (Metadata) md.clone();
        f.put("metadataCloneSharesArrays", String.valueOf(copy.getCategories() == md.getCategories()));
        f.put("metadataCloneCopiesTitle", copy.getTitle());
        f.put("metadataCloneFieldsNotShared", metadataCloneFieldsNotShared());

        MediaEntryModuleImpl entry = new MediaEntryModuleImpl();
        MediaContent content = new MediaContent(new UrlReference("http://x/a.mp4"));
        entry.setMediaContents(new MediaContent[] { content });
        entry.setMediaGroups(new MediaGroup[] { new MediaGroup(new MediaContent[] { content }) });
        entry.setMetadata(md);
        entry.setPlayer(new PlayerReference(new URI("http://x/p")));
        MediaEntryModuleImpl entryCopy = (MediaEntryModuleImpl) entry.clone();
        f.put("entryCloneCopiesArrays", String.valueOf(entryCopy.getMediaContents() != entry.getMediaContents()
            && entryCopy.getMediaGroups() != entry.getMediaGroups()));
        f.put("entryCloneSharesItems", String.valueOf(entryCopy.getMediaContents()[0] == content
            && entryCopy.getMediaGroups()[0] == entry.getMediaGroups()[0]));
        f.put("entryCloneMetadataIsNew", String.valueOf(entryCopy.getMetadata() != md
            && entryCopy.getMetadata().getCategories() == md.getCategories()));
        f.put("entryCloneSharesPlayer", String.valueOf(entryCopy.getPlayer() == entry.getPlayer()));
        f.put("entryCloneUri", entryCopy.getUri());
        f.put("entryCloneNullMetadata", run(() -> ((MediaEntryModuleImpl) new MediaEntryModuleImpl().clone()).getMetadata()));
        MediaEntryModuleImpl target = new MediaEntryModuleImpl();
        target.copyFrom(entry);
        f.put("entryCopyFrom", String.valueOf(target.getMediaContents()[0] == content
            && target.getMediaContents() != entry.getMediaContents() && target.getMetadata() != md
            && target.getMetadata().getTitle().equals("t") && target.getPlayer() == entry.getPlayer()));

        MediaModuleImpl feedModule = new MediaModuleImpl();
        feedModule.setMetadata(md);
        MediaModuleImpl feedCopy = (MediaModuleImpl) feedModule.clone();
        f.put("moduleCloneMetadataIsNew", String.valueOf(feedCopy.getMetadata() != md
            && feedCopy.getMetadata().getTitle().equals("t")));
        f.put("moduleCloneNullMetadata", run(() -> new MediaModuleImpl().clone()).split(":")[0]);
        MediaModuleImpl feedTarget = new MediaModuleImpl();
        feedTarget.copyFrom(feedModule);
        f.put("moduleCopyFrom", String.valueOf(feedTarget.getMetadata() != md && feedTarget.getMetadata().getTitle().equals("t")));

        PlayerReference player = new PlayerReference(new URI("http://x/p"), 640, 480);
        MediaContent withPlayer = new MediaContent(player);
        f.put("contentPlayerFromReference", String.valueOf(withPlayer.getPlayer() == player));
        f.put("contentUrlReferenceNoPlayer", String.valueOf(new MediaContent(new UrlReference("http://x/a")).getPlayer()));
        f.put("contentNullReference", run(() -> new MediaContent(null)));
        f.put("urlReferenceToString", new UrlReference("http://x/a%20b?c#d").toString());
        f.put("urlReferenceInvalid", run(() -> new UrlReference("http://x/a b")).split(":")[0]);
        f.put("urlReferenceNull", run(() -> new UrlReference((String) null)));
        f.put("playerReferenceNull", run(() -> new PlayerReference(null)));

        MediaContent c0 = new MediaContent(new UrlReference("http://x/0"));
        MediaContent c1 = new MediaContent(new UrlReference("http://x/1"));
        c0.setDefaultContent(true);
        MediaGroup group = new MediaGroup(new MediaContent[] { c0, c1 }, 1);
        f.put("groupDefaultIndex", group.getDefaultContentIndex() + " " + c0.isDefaultContent() + " " + c1.isDefaultContent());
        group.setDefaultContentIndex(5);
        f.put("groupDefaultIndexOutOfRange", group.getDefaultContentIndex() + " " + c0.isDefaultContent() + " " + c1.isDefaultContent());
        f.put("groupNullIndex", run(() -> new MediaGroup(new MediaContent[] { c0 }, null)));
        f.put("groupNullIndexEmpty", run(() -> new MediaGroup(new MediaContent[0], null).getDefaultContentIndex()));
        f.put("groupNullContents", run(() -> new MediaGroup(null).getContents().length));

        f.put("hashDefaultAlgorithm", new Hash(null, "abc").getAlgorithm());
        f.put("hashNullValue", run(() -> new Hash("SHA-1", null)));
        f.put("ratingNullScheme", run(() -> new Rating(null, "adult")));
        f.put("ratingEqualsAdult", String.valueOf(new Rating("urn:simple", "adult").equals(Rating.ADULT)));
        f.put("ratingEqualsOther", String.valueOf(new Rating("urn:simple", "Adult").equals(Rating.ADULT)
            || new Rating("urn:mpaa", "adult").equals(Rating.ADULT) || Rating.ADULT.equals(Rating.NONADULT)
            || Rating.ADULT.equals(null)));
        f.put("creditDefaults", new Credit(null, null, "n").getScheme() + " " + new Credit(null, null, "n").getRole());
        f.put("creditNullName", run(() -> new Credit("s", "r", null)));
        f.put("restrictionNullRelationship", run(() -> new Restriction(null, Restriction.Type.COUNTRY, "us")));
        f.put("restrictionNullValue", run(() -> new Restriction(Restriction.Relationship.ALLOW, Restriction.Type.COUNTRY, null)));
        f.put("restrictionNullType", run(() -> new Restriction(Restriction.Relationship.ALLOW, null, "us")));
        f.put("restrictionAllWithoutType", run(() -> new Restriction(Restriction.Relationship.DENY, null, "all").getValue()));
        f.put("restrictionNoneWithoutType", run(() -> new Restriction(Restriction.Relationship.DENY, null, "none").getValue()));
        f.put("restrictionAllUppercase", run(() -> new Restriction(Restriction.Relationship.DENY, null, "ALL")));
        f.put("restrictionToStrings", Restriction.Relationship.ALLOW + " " + Restriction.Relationship.DENY + " "
            + Restriction.Type.COUNTRY + " " + Restriction.Type.SHARING + " " + Restriction.Type.URI);
        f.put("enumStrings", Arrays.toString(new Expression[] { Expression.FULL, Expression.SAMPLE, Expression.NONSTOP })
            + Arrays.toString(Price.Type.values()) + Arrays.toString(Status.State.values())
            + Arrays.toString(Metadata.RightsStatus.values()));
        f.put("constants", MediaModule.URI + " " + Category.SCHEME_FLICKR_TAGS + " " + Credit.SCHEME_EBU);
        f.put("tagDefaultWeight", String.valueOf(new Tag("a").getWeight()));
        f.put("tagCompareNull", new Tag("a", 2).compareTo(null) + " " + new Tag("a").compareTo(null) + " " + new Tag("a", 0).compareTo(null));
        return f;
    }

    // Sets every Metadata field to a fresh non-default value and lists the fields whose value clone() does not share.
    static String metadataCloneFieldsNotShared() throws Exception {
        Metadata md = new Metadata();
        List<Field> fields = new ArrayList<>();
        for (Field field : Metadata.class.getDeclaredFields()) {
            if (Modifier.isStatic(field.getModifiers())) continue;
            field.setAccessible(true);
            Class<?> type = field.getType();
            Object value;
            if (type.isArray()) value = Array.newInstance(type.getComponentType(), 0);
            else if (type == String.class) value = new String(field.getName());
            else if (type == Hash.class) value = new Hash(null, "h");
            else if (type == URI.class) value = new URI("http://x/" + field.getName());
            else if (type == Metadata.RightsStatus.class) value = Metadata.RightsStatus.official;
            else value = type.getDeclaredConstructor().newInstance();
            field.set(md, value);
            fields.add(field);
        }
        Metadata copy = (Metadata) md.clone();
        List<String> notShared = new ArrayList<>();
        for (Field field : fields) if (field.get(copy) != field.get(md)) notShared.add(field.getName());
        return fields.size() + " fields, not shared: " + notShared;
    }

    // Java bean property names (java.beans.Introspector, getters only) of every class the port serializes, as the
    // goldens see them. Expression, Restriction.Relationship/Type and the Java enums are not listed: they have no
    // properties and the goldens write them as strings (toString()/name()), as the port stores them. Reference is an
    // empty interface and AbstractSchemeValue is abstract (covered by Hash and Rating).
    static String properties(Class<?> type) throws Exception {
        List<String> names = new ArrayList<>();
        for (PropertyDescriptor p : Introspector.getBeanInfo(type).getPropertyDescriptors()) {
            if (p.getReadMethod() == null) continue;
            String name = p.getName();
            // getClass() is not a property; the goldens exclude it.
            if (name.equals("class")) continue;
            // ModuleImpl.getInterface(): the goldens exclude it.
            if (name.equals("interface")) continue;
            // Hash.getAlgorithm() returns getScheme(); the goldens leave this computed alias out.
            if (type == Hash.class && name.equals("algorithm")) continue;
            names.add(name);
        }
        Collections.sort(names);
        return String.join(" ", names);
    }

    static final Class<?>[] PROPERTY_CLASSES = {
        MediaModuleImpl.class, MediaEntryModuleImpl.class, Category.class, Community.class, Credit.class,
        Embed.class, Embed.Param.class, Hash.class, License.class, Location.class, MediaContent.class,
        MediaGroup.class, Metadata.class, PeerLink.class, PlayerReference.class, Price.class, Rating.class,
        Restriction.class, Scene.class, StarRating.class, Statistics.class, Status.class, SubTitle.class, Tag.class,
        Text.class, Thumbnail.class, Time.class, UrlReference.class,
    };

    public static void main(String[] args) throws Exception {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        List<String> time = new ArrayList<>();
        for (String s : TIME_INPUTS) {
            String result = run(() -> {
                Time t = new Time(s);
                return t.getValue() + " " + t;
            });
            time.add("  [" + q(s) + ", " + q(result) + "]");
        }
        List<String> ms = new ArrayList<>();
        for (long m : TIME_MILLISECONDS) ms.add("  [" + q(String.valueOf(m)) + ", " + q(new Time(m).toString()) + "]");
        List<String> tags = new ArrayList<>();
        for (String s : TAG_SEQUENCES) tags.add("  [" + q(s) + ", " + q(tags(s)) + "]");
        List<String> roles = new ArrayList<>();
        for (String s : CREDIT_ROLES) roles.add("  [" + q(s) + ", " + q(new Credit(null, s, "n").getRole()) + "]");
        List<String> facts = new ArrayList<>();
        for (Map.Entry<String, String> e : facts().entrySet()) facts.add("  [" + q(e.getKey()) + ", " + q(e.getValue()) + "]");

        List<String> props = new ArrayList<>();
        for (Class<?> c : PROPERTY_CLASSES) {
            String name = c.getName().substring(c.getName().lastIndexOf('.') + 1).replace("Impl", "").replace('$', '.');
            props.add("  [" + q(name) + ", " + q(properties(c)) + "]");
        }

        String out = "// Generated by tools/mediarss-oracle/MediarssOracle.java from ROME 6b4a7e8 on JDK "
            + System.getProperty("java.version") + ", " + java.util.Locale.getDefault() + ". Do not edit.\n"
            + "// Each entry is [input, expected]. Time.parse results are \"<value> <toString()>\" or \"<exception>: <message>\".\n"
            + "export const TIME_PARSE: string[][] = [\n" + String.join(",\n", time) + "\n];\n\n"
            + "export const TIME_TO_STRING: string[][] = [\n" + String.join(",\n", ms) + "\n];\n\n"
            + "export const TAG_ORDER: string[][] = [\n" + String.join(",\n", tags) + "\n];\n\n"
            + "export const CREDIT_ROLES: string[][] = [\n" + String.join(",\n", roles) + "\n];\n\n"
            + "export const FACTS: string[][] = [\n" + String.join(",\n", facts) + "\n];\n\n"
            + "// [class, its Java bean property names, sorted]\n"
            + "export const PROPERTIES: string[][] = [\n" + String.join(",\n", props) + "\n];\n";
        Files.writeString(Path.of("oh_rome/src/test/MediarssCases.ets"), out, StandardCharsets.UTF_8);
        System.out.println(time.size() + ms.size() + tags.size() + roles.size() + facts.size() + props.size() + " cases");
    }
}
