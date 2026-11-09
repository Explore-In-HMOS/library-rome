// Runs ROME's RSS models through the steps of oh_rome/src/test/Rss.test.ets and prints every expect(...) line of that
// test, in order, with ROME's result. The test's lines are pasted from this output; check them with the diff below.
// Usage (from the repo root, <rome> is a ROME clone at 6b4a7e8, JDK Temurin 17.0.17+10, jdom2 2.0.6.1 and slf4j-api
// 1.7.36 from the local Maven repository):
//   javac -d /tmp/rss-oracle -cp <jdom2.jar>:<slf4j-api.jar> -sourcepath <rome>/rome/src/main/java:<rome>/rome-utils/src/main/java tools/rss-oracle/RssOracle.java
//   java -cp /tmp/rss-oracle:<jdom2.jar>:<slf4j-api.jar> RssOracle | diff - <(grep -o 'expect(.*' oh_rome/src/test/Rss.test.ets)
// Use /usr/bin/diff: the diff in DevEco's sdk/default/openharmony/toolchains rejects '-' and prints nothing.
import com.rometools.rome.feed.module.DCModule;
import com.rometools.rome.feed.module.DCModuleImpl;
import com.rometools.rome.feed.rss.Category;
import com.rometools.rome.feed.rss.Channel;
import com.rometools.rome.feed.rss.Cloud;
import com.rometools.rome.feed.rss.Content;
import com.rometools.rome.feed.rss.Description;
import com.rometools.rome.feed.rss.Enclosure;
import com.rometools.rome.feed.rss.Guid;
import com.rometools.rome.feed.rss.Image;
import com.rometools.rome.feed.rss.Item;
import com.rometools.rome.feed.rss.Source;
import com.rometools.rome.feed.rss.TextInput;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

public class RssOracle {
    static void expect(String actual, Object value) {
        String assertion;
        if (value == null) assertion = "assertNull()";
        else if (value instanceof Boolean) assertion = (Boolean) value ? "assertTrue()" : "assertFalse()";
        else if (value instanceof String) assertion = "assertEqual('" + value + "')";
        else assertion = "assertEqual(" + value + ")";
        System.out.println("expect(" + actual + ")." + assertion + ";");
    }

    // Mirrors the test's errorOf(): the port throws a plain Error with ROME's message.
    static String errorOf(Runnable r) {
        try {
            r.run();
            return "no error";
        } catch (RuntimeException e) {
            return e.getMessage();
        }
    }

    static String join(List<?> list) {
        return list.stream().map(String::valueOf).collect(Collectors.joining(","));
    }

    static <T> List<T> list(T... values) {
        return new ArrayList<>(Arrays.asList(values));
    }

    public static void main(String[] args) {
        // Every oracle and the goldens run on this JDK (URL, Currency and charset data differ between JDKs).
        if (!"Temurin-17.0.17+10".equals(System.getProperty("java.vendor.version")) || !"17.0.17".equals(System.getProperty("java.version"))) {
            throw new IllegalStateException("need java.vendor.version Temurin-17.0.17+10 and java.version 17.0.17, got "
                    + System.getProperty("java.vendor.version") + " and " + System.getProperty("java.version"));
        }
        channelDefaults();
        channelListsKeepAddedValues();
        unsetSkipListsSerializeAsEmptyLists();
        skipHoursAcceptsZeroToTwentyFour();
        skipDaysLowercasesTheGivenListInPlace();
        channelDatesAreCopied();
        itemDefaultsListsAndModules();
        itemDatesAreCopied();
        beanDefaults();
    }

    static void channelDefaults() {
        expect("new Channel().feedType", new Channel().getFeedType());
        Channel c = new Channel("rss_2.0");
        expect("c.feedType", c.getFeedType());
        expect("c.ttl", c.getTtl());
        expect("c.title", c.getTitle());
        expect("c.description", c.getDescription());
        expect("c.link", c.getLink());
        expect("c.uri", c.getUri());
        expect("c.image", c.getImage());
        expect("c.textInput", c.getTextInput());
        expect("c.language", c.getLanguage());
        expect("c.rating", c.getRating());
        expect("c.copyright", c.getCopyright());
        expect("c.pubDate", c.getPubDate());
        expect("c.lastBuildDate", c.getLastBuildDate());
        expect("c.docs", c.getDocs());
        expect("c.managingEditor", c.getManagingEditor());
        expect("c.webMaster", c.getWebMaster());
        expect("c.cloud", c.getCloud());
        expect("c.generator", c.getGenerator());
        expect("c.items.length", c.getItems().size());
        expect("c.categories.length", c.getCategories().size());
        expect("c.modules.length", c.getModules().size());
        expect("c.foreignMarkup.length", c.getForeignMarkup().size());
        expect("c.skipHours.length", c.getSkipHours().size());
        expect("c.skipDays.length", c.getSkipDays().size());
        expect("[Channel.SUNDAY, Channel.MONDAY, Channel.TUESDAY, Channel.WEDNESDAY, Channel.THURSDAY, Channel.FRIDAY, Channel.SATURDAY].join(',')",
                join(list(Channel.SUNDAY, Channel.MONDAY, Channel.TUESDAY, Channel.WEDNESDAY, Channel.THURSDAY, Channel.FRIDAY, Channel.SATURDAY)));
    }

    static void channelListsKeepAddedValues() {
        Channel c = new Channel("rss_2.0");
        c.getItems().add(new Item());
        c.getCategories().add(new Category());
        c.getModules().add(new DCModuleImpl());
        expect("c.items.length", c.getItems().size());
        expect("c.categories.length", c.getCategories().size());
        expect("c.getModule(DCModule.URI) instanceof DCModule", c.getModule(DCModule.URI) instanceof DCModule);
        expect("c.getModule('urn:x')", c.getModule("urn:x"));
        expect("new Channel().getModule(DCModule.URI)", new Channel().getModule(DCModule.URI));
    }

    // The golden writes a bean property's getter value; the port's JSON has the field behind the accessor.
    static void unsetSkipListsSerializeAsEmptyLists() {
        Channel c = new Channel("rss_2.0");
        expect("JSON.stringify(c).includes('\"_skipHours\":[]')", c.getSkipHours() != null && c.getSkipHours().isEmpty());
        expect("JSON.stringify(c).includes('\"_skipDays\":[]')", c.getSkipDays() != null && c.getSkipDays().isEmpty());
    }

    static void skipHoursAcceptsZeroToTwentyFour() {
        Channel c = new Channel("rss_2.0");
        List<Integer> hours = list(0, 24);
        c.setSkipHours(hours);
        expect("c.skipHours === hours", c.getSkipHours() == hours);
        c.getSkipHours().add(99);
        expect("c.skipHours.join(',')", join(c.getSkipHours()));
        expect("errorOf(() => { c.skipHours = [25]; })", errorOf(() -> c.setSkipHours(list(25))));
        expect("errorOf(() => { c.skipHours = [-1]; })", errorOf(() -> c.setSkipHours(list(-1))));
        expect("errorOf(() => { c.skipHours = [1, 25, -1]; })", errorOf(() -> c.setSkipHours(list(1, 25, -1))));
        expect("c.skipHours.join(',')", join(c.getSkipHours()));
        c.setSkipHours(list());
        expect("c.skipHours.length", c.getSkipHours().size());
    }

    static void skipDaysLowercasesTheGivenListInPlace() {
        Channel c = new Channel("rss_2.0");
        List<String> days = list("Monday", "SUNDAY", "saturday");
        c.setSkipDays(days);
        expect("c.skipDays === days", c.getSkipDays() == days);
        expect("days.join(',')", join(days));
        List<String> bad = list("Tuesday", "Funday", "FRIDAY");
        expect("errorOf(() => { c.skipDays = bad; })", errorOf(() -> c.setSkipDays(bad)));
        expect("bad.join(',')", join(bad));
        expect("c.skipDays.join(',')", join(c.getSkipDays()));
        expect("errorOf(() => { c.skipDays = [' monday']; })", errorOf(() -> c.setSkipDays(list(" monday"))));
    }

    static void channelDatesAreCopied() {
        Channel c = new Channel("rss_2.0");
        Date pubDate = new Date(1704153600000L);
        c.setPubDate(pubDate);
        pubDate.setTime(0);
        expect("time(c.pubDate)", c.getPubDate().getTime());
        c.getPubDate().setTime(5);
        expect("time(c.pubDate)", c.getPubDate().getTime());
        expect("c.pubDate === c.pubDate", c.getPubDate() == c.getPubDate());
        Date lastBuildDate = new Date(1704153600000L);
        c.setLastBuildDate(lastBuildDate);
        lastBuildDate.setTime(0);
        c.getLastBuildDate().setTime(7);
        expect("time(c.lastBuildDate)", c.getLastBuildDate().getTime());
        c.setPubDate(null);
        expect("c.pubDate", c.getPubDate());
    }

    static void itemDefaultsListsAndModules() {
        Item i = new Item();
        expect("i.title", i.getTitle());
        expect("i.link", i.getLink());
        expect("i.uri", i.getUri());
        expect("i.description", i.getDescription());
        expect("i.content", i.getContent());
        expect("i.source", i.getSource());
        expect("i.guid", i.getGuid());
        expect("i.comments", i.getComments());
        expect("i.author", i.getAuthor());
        expect("i.pubDate", i.getPubDate());
        expect("i.expirationDate", i.getExpirationDate());
        expect("i.categories.length", i.getCategories().size());
        expect("i.modules.length", i.getModules().size());
        expect("i.foreignMarkup.length", i.getForeignMarkup().size());
        i.getEnclosures().add(new Enclosure());
        expect("i.enclosures.length", i.getEnclosures().size());
        expect("i.getModule(DCModule.URI)", i.getModule(DCModule.URI));
        i.getModules().add(new DCModuleImpl());
        expect("i.getModule(DCModule.URI) instanceof DCModule", i.getModule(DCModule.URI) instanceof DCModule);
    }

    static void itemDatesAreCopied() {
        Item i = new Item();
        Date pubDate = new Date(1704153600000L);
        i.setPubDate(pubDate);
        pubDate.setTime(0);
        i.getPubDate().setTime(1);
        Date expirationDate = new Date(1704240000000L);
        i.setExpirationDate(expirationDate);
        expirationDate.setTime(0);
        i.getExpirationDate().setTime(1);
        expect("time(i.pubDate)", i.getPubDate().getTime());
        expect("time(i.expirationDate)", i.getExpirationDate().getTime());
    }

    static void beanDefaults() {
        Image image = new Image();
        expect("image.title", image.getTitle());
        expect("image.url", image.getUrl());
        expect("image.link", image.getLink());
        expect("image.width", image.getWidth());
        expect("image.height", image.getHeight());
        expect("image.description", image.getDescription());
        Guid guid = new Guid();
        expect("guid.permaLink", guid.isPermaLink());
        expect("guid.value", guid.getValue());
        Enclosure enclosure = new Enclosure();
        expect("enclosure.url", enclosure.getUrl());
        expect("enclosure.length", enclosure.getLength());
        expect("enclosure.type", enclosure.getType());
        Cloud cloud = new Cloud();
        expect("cloud.domain", cloud.getDomain());
        expect("cloud.port", cloud.getPort());
        expect("cloud.path", cloud.getPath());
        expect("cloud.registerProcedure", cloud.getRegisterProcedure());
        expect("cloud.protocol", cloud.getProtocol());
        Category category = new Category();
        expect("category.domain", category.getDomain());
        expect("category.value", category.getValue());
        Content content = new Content();
        expect("content.type", content.getType());
        expect("content.value", content.getValue());
        expect("Content.HTML", Content.HTML);
        expect("Content.TEXT", Content.TEXT);
        Description description = new Description();
        expect("description.type", description.getType());
        expect("description.value", description.getValue());
        Source source = new Source();
        expect("source.url", source.getUrl());
        expect("source.value", source.getValue());
        TextInput textInput = new TextInput();
        expect("textInput.title", textInput.getTitle());
        expect("textInput.description", textInput.getDescription());
        expect("textInput.name", textInput.getName());
        expect("textInput.link", textInput.getLink());
    }
}
