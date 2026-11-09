// Replaces the rome.properties files of rome, rome-opml and rome-modules (Apache-2.0).
import { PluginRegistry, setDefaultPlugins } from './PluginRegistry';
import { Atom03Generator } from './Atom03Generator';
import { Atom03Parser } from './Atom03Parser';
import { Atom10Generator } from './Atom10Generator';
import { Atom10Parser } from './Atom10Parser';
import { ConverterForAtom03 } from '../../feed/synd/impl/ConverterForAtom03';
import { ConverterForAtom10 } from '../../feed/synd/impl/ConverterForAtom10';
import { DCModuleGenerator } from './DCModuleGenerator';
import { DCModuleParser } from './DCModuleParser';
import { SyModuleGenerator } from './SyModuleGenerator';
import { SyModuleParser } from './SyModuleParser';
import { RSS090Parser } from './RSS090Parser';
import { RSS091NetscapeParser } from './RSS091NetscapeParser';
import { RSS091UserlandParser } from './RSS091UserlandParser';
import { RSS092Parser } from './RSS092Parser';
import { RSS093Parser } from './RSS093Parser';
import { RSS094Parser } from './RSS094Parser';
import { RSS10Parser } from './RSS10Parser';
import { RSS20Parser } from './RSS20Parser';
import { RSS20wNSParser } from './RSS20wNSParser';
import { RSS090Generator } from './RSS090Generator';
import { RSS091NetscapeGenerator } from './RSS091NetscapeGenerator';
import { RSS091UserlandGenerator } from './RSS091UserlandGenerator';
import { RSS092Generator } from './RSS092Generator';
import { RSS093Generator } from './RSS093Generator';
import { RSS094Generator } from './RSS094Generator';
import { RSS10Generator } from './RSS10Generator';
import { RSS20Generator } from './RSS20Generator';
import { ConverterForRSS090 } from '../../feed/synd/impl/ConverterForRSS090';
import { ConverterForRSS091Netscape } from '../../feed/synd/impl/ConverterForRSS091Netscape';
import { ConverterForRSS091Userland } from '../../feed/synd/impl/ConverterForRSS091Userland';
import { ConverterForRSS092 } from '../../feed/synd/impl/ConverterForRSS092';
import { ConverterForRSS093 } from '../../feed/synd/impl/ConverterForRSS093';
import { ConverterForRSS094 } from '../../feed/synd/impl/ConverterForRSS094';
import { ConverterForRSS10 } from '../../feed/synd/impl/ConverterForRSS10';
import { ConverterForRSS20 } from '../../feed/synd/impl/ConverterForRSS20';
import { ContentModuleGenerator } from '../../modules/content/io/ContentModuleGenerator';
import { ContentModuleParser } from '../../modules/content/io/ContentModuleParser';
import { ITunesGenerator } from '../../modules/itunes/io/ITunesGenerator';
import { ITunesParser } from '../../modules/itunes/io/ITunesParser';
import { ITunesParserOldNamespace } from '../../modules/itunes/io/ITunesParserOldNamespace';
import { SlashModuleGenerator } from '../../modules/slash/io/SlashModuleGenerator';
import { SlashModuleParser } from '../../modules/slash/io/SlashModuleParser';
import { OPML10Generator } from '../../opml/io/impl/OPML10Generator';
import { OPML20Generator } from '../../opml/io/impl/OPML20Generator';
import { OPML10Parser } from '../../opml/io/impl/OPML10Parser';
import { OPML20Parser } from '../../opml/io/impl/OPML20Parser';
import { ConverterForOPML10 } from '../../opml/feed/synd/impl/ConverterForOPML10';
import { ConverterForOPML20 } from '../../opml/feed/synd/impl/ConverterForOPML20';
import { AtomModuleGenerator } from '../../modules/atom/io/AtomModuleGenerator';
import { AtomModuleParser } from '../../modules/atom/io/AtomModuleParser';
import { OpenSearchModuleGenerator } from '../../modules/opensearch/impl/OpenSearchModuleGenerator';
import { OpenSearchModuleParser } from '../../modules/opensearch/impl/OpenSearchModuleParser';
import { AlternateMediaModuleParser } from '../../modules/mediarss/io/AlternateMediaModuleParser';
import { MediaModuleGenerator } from '../../modules/mediarss/io/MediaModuleGenerator';
import { MediaModuleParser } from '../../modules/mediarss/io/MediaModuleParser';
import { RSS20YahooParser } from '../../modules/mediarss/io/RSS20YahooParser';
import { CCModuleGenerator } from '../../modules/cc/io/CCModuleGenerator';
import { ModuleParserRSS1 } from '../../modules/cc/io/ModuleParserRSS1';
import { ModuleParserRSS2 } from '../../modules/cc/io/ModuleParserRSS2';
import { PodloveSimpleChapterGenerator } from '../../modules/psc/io/PodloveSimpleChapterGenerator';
import { PodloveSimpleChapterParser } from '../../modules/psc/io/PodloveSimpleChapterParser';
import { ThreadingModuleGenerator } from '../../modules/thr/io/ThreadingModuleGenerator';
import { ThreadingModuleParser } from '../../modules/thr/io/ThreadingModuleParser';
import { SimpleGenerator } from '../../modules/georss/SimpleGenerator';
import { SimpleParser } from '../../modules/georss/SimpleParser';
import { W3CGeoGenerator } from '../../modules/georss/W3CGeoGenerator';
import { W3CGeoParser } from '../../modules/georss/W3CGeoParser';

// rome/src/main/resources/com/rometools/rome/rome.properties, one block per key in file order.
export function registerCorePlugins(registry: PluginRegistry): void {
  // WireFeedParser.classes
  registry.addFeedParser(new RSS090Parser());
  registry.addFeedParser(new RSS091NetscapeParser());
  registry.addFeedParser(new RSS091UserlandParser());
  registry.addFeedParser(new RSS092Parser());
  registry.addFeedParser(new RSS093Parser());
  registry.addFeedParser(new RSS094Parser());
  registry.addFeedParser(new RSS10Parser());
  registry.addFeedParser(new RSS20wNSParser());
  registry.addFeedParser(new RSS20Parser());
  registry.addFeedParser(new Atom10Parser());
  registry.addFeedParser(new Atom03Parser());

  // atom_1.0.feed.ModuleParser.classes
  registry.addModuleParser('atom_1.0.feed', new SyModuleParser());
  registry.addModuleParser('atom_1.0.feed', new DCModuleParser());
  // atom_1.0.item.ModuleParser.classes
  registry.addModuleParser('atom_1.0.item', new DCModuleParser());
  // atom_0.3.feed.ModuleParser.classes
  registry.addModuleParser('atom_0.3.feed', new SyModuleParser());
  registry.addModuleParser('atom_0.3.feed', new DCModuleParser());
  // atom_0.3.item.ModuleParser.classes
  registry.addModuleParser('atom_0.3.item', new DCModuleParser());
  // rss_1.0.feed.ModuleParser.classes
  registry.addModuleParser('rss_1.0.feed', new SyModuleParser());
  registry.addModuleParser('rss_1.0.feed', new DCModuleParser());
  // rss_1.0.item.ModuleParser.classes
  registry.addModuleParser('rss_1.0.item', new DCModuleParser());
  // rss_2.0wNS.feed.ModuleParser.classes
  registry.addModuleParser('rss_2.0wNS.feed', new DCModuleParser());
  // rss_2.0wNS.item.ModuleParser.classes
  registry.addModuleParser('rss_2.0wNS.item', new DCModuleParser());
  // rss_2.0.feed.ModuleParser.classes
  registry.addModuleParser('rss_2.0.feed', new DCModuleParser());
  // rss_2.0.item.ModuleParser.classes
  registry.addModuleParser('rss_2.0.item', new DCModuleParser());

  // WireFeedGenerator.classes
  registry.addFeedGenerator(new RSS090Generator());
  registry.addFeedGenerator(new RSS091NetscapeGenerator());
  registry.addFeedGenerator(new RSS091UserlandGenerator());
  registry.addFeedGenerator(new RSS092Generator());
  registry.addFeedGenerator(new RSS093Generator());
  registry.addFeedGenerator(new RSS094Generator());
  registry.addFeedGenerator(new RSS10Generator());
  registry.addFeedGenerator(new RSS20Generator());
  registry.addFeedGenerator(new Atom10Generator());
  registry.addFeedGenerator(new Atom03Generator());

  // atom_1.0.feed.ModuleGenerator.classes
  registry.addModuleGenerator('atom_1.0.feed', new SyModuleGenerator());
  registry.addModuleGenerator('atom_1.0.feed', new DCModuleGenerator());
  // atom_1.0.item.ModuleGenerator.classes
  registry.addModuleGenerator('atom_1.0.item', new DCModuleGenerator());
  // atom_0.3.feed.ModuleGenerator.classes
  registry.addModuleGenerator('atom_0.3.feed', new SyModuleGenerator());
  registry.addModuleGenerator('atom_0.3.feed', new DCModuleGenerator());
  // atom_0.3.item.ModuleGenerator.classes
  registry.addModuleGenerator('atom_0.3.item', new DCModuleGenerator());
  // rss_1.0.feed.ModuleGenerator.classes
  registry.addModuleGenerator('rss_1.0.feed', new SyModuleGenerator());
  registry.addModuleGenerator('rss_1.0.feed', new DCModuleGenerator());
  // rss_1.0.item.ModuleGenerator.classes
  registry.addModuleGenerator('rss_1.0.item', new DCModuleGenerator());
  // rss_2.0.feed.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0.feed', new DCModuleGenerator());
  // rss_2.0.item.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0.item', new DCModuleGenerator());

  // Converter.classes
  registry.addConverter(new ConverterForAtom10());
  registry.addConverter(new ConverterForAtom03());
  registry.addConverter(new ConverterForRSS090());
  registry.addConverter(new ConverterForRSS091Netscape());
  registry.addConverter(new ConverterForRSS091Userland());
  registry.addConverter(new ConverterForRSS092());
  registry.addConverter(new ConverterForRSS093());
  registry.addConverter(new ConverterForRSS094());
  registry.addConverter(new ConverterForRSS10());
  registry.addConverter(new ConverterForRSS20());
}

// rome-opml/src/main/resources/rome.properties, in file order.
export function registerOpmlPlugins(registry: PluginRegistry): void {
  // WireFeedGenerator.classes
  registry.addFeedGenerator(new OPML10Generator());
  registry.addFeedGenerator(new OPML20Generator());
  // WireFeedParser.classes
  registry.addFeedParser(new OPML10Parser());
  registry.addFeedParser(new OPML20Parser());
  // Converter.classes
  registry.addConverter(new ConverterForOPML10());
  registry.addConverter(new ConverterForOPML20());
}

// rome-modules/src/main/resources/rome.properties, in file order.
export function registerModulePlugins(registry: PluginRegistry): void {
  // WireFeedParser.classes
  registry.addFeedParser(new RSS20YahooParser());

  // rss_2.0.feed.ModuleParser.classes
  registry.addModuleParser('rss_2.0.feed', new ModuleParserRSS2());
  registry.addModuleParser('rss_2.0.feed', new ContentModuleParser());
  registry.addModuleParser('rss_2.0.feed', new ITunesParser());
  registry.addModuleParser('rss_2.0.feed', new MediaModuleParser());
  registry.addModuleParser('rss_2.0.feed', new OpenSearchModuleParser());
  registry.addModuleParser('rss_2.0.feed', new SimpleParser());
  registry.addModuleParser('rss_2.0.feed', new W3CGeoParser());
  registry.addModuleParser('rss_2.0.feed', new MediaModuleParser());
  registry.addModuleParser('rss_2.0.feed', new AtomModuleParser());
  registry.addModuleParser('rss_2.0.feed', new ITunesParserOldNamespace());
  registry.addModuleParser('rss_2.0.feed', new AlternateMediaModuleParser());
  // rss_1.0.feed.ModuleParser.classes
  registry.addModuleParser('rss_1.0.feed', new ModuleParserRSS1());
  registry.addModuleParser('rss_1.0.feed', new ContentModuleParser());
  // atom_0.3.feed.ModuleParser.classes
  registry.addModuleParser('atom_0.3.feed', new ModuleParserRSS2());
  registry.addModuleParser('atom_0.3.feed', new OpenSearchModuleParser());
  registry.addModuleParser('atom_0.3.feed', new SimpleParser());
  registry.addModuleParser('atom_0.3.feed', new W3CGeoParser());
  registry.addModuleParser('atom_0.3.feed', new MediaModuleParser());
  registry.addModuleParser('atom_0.3.feed', new AlternateMediaModuleParser());
  // atom_1.0.feed.ModuleParser.classes
  registry.addModuleParser('atom_1.0.feed', new ModuleParserRSS2());
  registry.addModuleParser('atom_1.0.feed', new OpenSearchModuleParser());
  registry.addModuleParser('atom_1.0.feed', new SimpleParser());
  registry.addModuleParser('atom_1.0.feed', new W3CGeoParser());
  registry.addModuleParser('atom_1.0.feed', new MediaModuleParser());
  registry.addModuleParser('atom_1.0.feed', new AlternateMediaModuleParser());
  // rss_2.0.item.ModuleParser.classes
  registry.addModuleParser('rss_2.0.item', new ModuleParserRSS2());
  registry.addModuleParser('rss_2.0.item', new ContentModuleParser());
  registry.addModuleParser('rss_2.0.item', new SlashModuleParser());
  registry.addModuleParser('rss_2.0.item', new ITunesParser());
  registry.addModuleParser('rss_2.0.item', new MediaModuleParser());
  registry.addModuleParser('rss_2.0.item', new AtomModuleParser());
  registry.addModuleParser('rss_2.0.item', new OpenSearchModuleParser());
  registry.addModuleParser('rss_2.0.item', new SimpleParser());
  registry.addModuleParser('rss_2.0.item', new W3CGeoParser());
  registry.addModuleParser('rss_2.0.item', new ITunesParserOldNamespace());
  registry.addModuleParser('rss_2.0.item', new AlternateMediaModuleParser());
  registry.addModuleParser('rss_2.0.item', new PodloveSimpleChapterParser());
  // rss_1.0.item.ModuleParser.classes
  registry.addModuleParser('rss_1.0.item', new ModuleParserRSS1());
  registry.addModuleParser('rss_1.0.item', new ContentModuleParser());
  registry.addModuleParser('rss_1.0.item', new SlashModuleParser());
  // atom_0.3.item.ModuleParser.classes
  registry.addModuleParser('atom_0.3.item', new ModuleParserRSS2());
  registry.addModuleParser('atom_0.3.item', new SlashModuleParser());
  registry.addModuleParser('atom_0.3.item', new OpenSearchModuleParser());
  registry.addModuleParser('atom_0.3.item', new SimpleParser());
  registry.addModuleParser('atom_0.3.item', new W3CGeoParser());
  registry.addModuleParser('atom_0.3.item', new MediaModuleParser());
  registry.addModuleParser('atom_0.3.item', new AlternateMediaModuleParser());
  // atom_1.0.item.ModuleParser.classes
  registry.addModuleParser('atom_1.0.item', new ModuleParserRSS2());
  registry.addModuleParser('atom_1.0.item', new SlashModuleParser());
  registry.addModuleParser('atom_1.0.item', new OpenSearchModuleParser());
  registry.addModuleParser('atom_1.0.item', new SimpleParser());
  registry.addModuleParser('atom_1.0.item', new W3CGeoParser());
  registry.addModuleParser('atom_1.0.item', new MediaModuleParser());
  registry.addModuleParser('atom_1.0.item', new AlternateMediaModuleParser());
  registry.addModuleParser('atom_1.0.item', new ThreadingModuleParser());
  registry.addModuleParser('atom_1.0.item', new PodloveSimpleChapterParser());

  // rss_2.0.feed.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0.feed', new CCModuleGenerator());
  registry.addModuleGenerator('rss_2.0.feed', new ContentModuleGenerator());
  registry.addModuleGenerator('rss_2.0.feed', new ITunesGenerator());
  registry.addModuleGenerator('rss_2.0.feed', new OpenSearchModuleGenerator());
  registry.addModuleGenerator('rss_2.0.feed', new SimpleGenerator());
  registry.addModuleGenerator('rss_2.0.feed', new W3CGeoGenerator());
  registry.addModuleGenerator('rss_2.0.feed', new MediaModuleGenerator());
  registry.addModuleGenerator('rss_2.0.feed', new AtomModuleGenerator());
  // rss_1.0.feed.ModuleGenerator.classes
  registry.addModuleGenerator('rss_1.0.feed', new ContentModuleGenerator());
  // atom_0.3.feed.ModuleGenerator.classes
  registry.addModuleGenerator('atom_0.3.feed', new CCModuleGenerator());
  registry.addModuleGenerator('atom_0.3.feed', new OpenSearchModuleGenerator());
  registry.addModuleGenerator('atom_0.3.feed', new SimpleGenerator());
  registry.addModuleGenerator('atom_0.3.feed', new W3CGeoGenerator());
  registry.addModuleGenerator('atom_0.3.feed', new MediaModuleGenerator());
  // atom_1.0.feed.ModuleGenerator.classes
  registry.addModuleGenerator('atom_1.0.feed', new CCModuleGenerator());
  registry.addModuleGenerator('atom_1.0.feed', new OpenSearchModuleGenerator());
  registry.addModuleGenerator('atom_1.0.feed', new SimpleGenerator());
  registry.addModuleGenerator('atom_1.0.feed', new W3CGeoGenerator());
  registry.addModuleGenerator('atom_1.0.feed', new MediaModuleGenerator());
  // rss_2.0.item.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0.item', new CCModuleGenerator());
  registry.addModuleGenerator('rss_2.0.item', new ContentModuleGenerator());
  registry.addModuleGenerator('rss_2.0.item', new SlashModuleGenerator());
  registry.addModuleGenerator('rss_2.0.item', new ITunesGenerator());
  registry.addModuleGenerator('rss_2.0.item', new OpenSearchModuleGenerator());
  registry.addModuleGenerator('rss_2.0.item', new SimpleGenerator());
  registry.addModuleGenerator('rss_2.0.item', new W3CGeoGenerator());
  registry.addModuleGenerator('rss_2.0.item', new MediaModuleGenerator());
  registry.addModuleGenerator('rss_2.0.item', new AtomModuleGenerator());
  registry.addModuleGenerator('rss_2.0.item', new PodloveSimpleChapterGenerator());
  // rss_1.0.item.ModuleGenerator.classes
  registry.addModuleGenerator('rss_1.0.item', new ContentModuleGenerator());
  registry.addModuleGenerator('rss_1.0.item', new SlashModuleGenerator());
  // atom_0.3.item.ModuleGenerator.classes
  registry.addModuleGenerator('atom_0.3.item', new CCModuleGenerator());
  registry.addModuleGenerator('atom_0.3.item', new SlashModuleGenerator());
  registry.addModuleGenerator('atom_0.3.item', new OpenSearchModuleGenerator());
  registry.addModuleGenerator('atom_0.3.item', new SimpleGenerator());
  registry.addModuleGenerator('atom_0.3.item', new W3CGeoGenerator());
  registry.addModuleGenerator('atom_0.3.item', new MediaModuleGenerator());
  // atom_1.0.item.ModuleGenerator.classes
  registry.addModuleGenerator('atom_1.0.item', new CCModuleGenerator());
  registry.addModuleGenerator('atom_1.0.item', new SlashModuleGenerator());
  registry.addModuleGenerator('atom_1.0.item', new OpenSearchModuleGenerator());
  registry.addModuleGenerator('atom_1.0.item', new SimpleGenerator());
  registry.addModuleGenerator('atom_1.0.item', new W3CGeoGenerator());
  registry.addModuleGenerator('atom_1.0.item', new MediaModuleGenerator());
  registry.addModuleGenerator('atom_1.0.item', new ThreadingModuleGenerator());
  registry.addModuleGenerator('atom_1.0.item', new PodloveSimpleChapterGenerator());

  // rss_2.0wNS.feed.ModuleParser.classes
  registry.addModuleParser('rss_2.0wNS.feed', new MediaModuleParser());
  // rss_2.0wNS.item.ModuleParser.classes
  registry.addModuleParser('rss_2.0wNS.item', new MediaModuleParser());
  // rss_2.0yahoo.feed.ModuleParser.classes
  registry.addModuleParser('rss_2.0yahoo.feed', new MediaModuleParser());
  // rss_2.0yahoo.item.ModuleParser.classes
  registry.addModuleParser('rss_2.0yahoo.item', new MediaModuleParser());

  // rss_2.0wNS.feed.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0wNS.feed', new MediaModuleGenerator());
  // rss_2.0wNS.item.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0wNS.item', new MediaModuleGenerator());
  // rss_2.0yahoo.feed.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0yahoo.feed', new MediaModuleGenerator());
  // rss_2.0yahoo.item.ModuleGenerator.classes
  registry.addModuleGenerator('rss_2.0yahoo.item', new MediaModuleGenerator());
}

export function registerDefaultPlugins(registry: PluginRegistry): void {
  registerCorePlugins(registry);
  registerOpmlPlugins(registry);
  registerModulePlugins(registry);
}

// Loaded for this side effect by Index.ets and src/test/List.test.ets.
setDefaultPlugins(registerDefaultPlugins);
