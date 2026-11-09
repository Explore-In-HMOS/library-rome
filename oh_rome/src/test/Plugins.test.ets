import { describe, it, expect } from '@ohos/hypium';
import { Document, Element, Namespace } from '../main/ets/xml/Dom';
import { WireFeed } from '../main/ets/feed/WireFeed';
import { DCModule } from '../main/ets/feed/module/DCModule';
import { Module } from '../main/ets/feed/module/Module';
import { ModuleParser } from '../main/ets/io/ModuleParser';
import { WireFeedParser } from '../main/ets/io/WireFeedParser';
import { BaseWireFeedParser } from '../main/ets/io/impl/BaseWireFeedParser';
import { PluginRegistry, plugins } from '../main/ets/io/impl/PluginRegistry';

const FEED_NS: Namespace = Namespace.getNamespace('urn:test-feed');
const DC_NS: Namespace = Namespace.getNamespace('dc', DCModule.URI);

class TestFeed extends WireFeed {
  constructor() {
    super('test_1.0');
  }
}

class NamedParser implements WireFeedParser {
  private readonly type: string;
  readonly label: string;

  constructor(type: string, label: string) {
    this.type = type;
    this.label = label;
  }

  getType(): string {
    return this.type;
  }

  isMyType(document: Document): boolean {
    return document.getRootElement().getName() === 'feed';
  }

  parse(document: Document): WireFeed {
    return new TestFeed();
  }
}

class CreatorParser implements ModuleParser {
  getNamespaceUri(): string {
    return DCModule.URI;
  }

  parse(element: Element): Module | null {
    const dc = new DCModule();
    dc.creator = element.getChildText('creator', DC_NS);
    return dc;
  }
}

class TestParser extends BaseWireFeedParser {
  constructor() {
    super('test_1.0', FEED_NS);
  }

  isMyType(document: Document): boolean {
    return true;
  }

  parse(document: Document): WireFeed {
    const root = document.getRootElement();
    const feed = new TestFeed();
    feed.modules = this.parseFeedModules(root);
    feed.foreignMarkup = this.extractForeignMarkup(root, feed, FEED_NS);
    feed.styleSheet = this.getStyleSheet(document);
    return feed;
  }
}

export default function pluginsTest() {
  describe('Plugins', () => {
    it('laterRegistrationReplacesAndMovesToEnd', 0, () => {
      const registry = new PluginRegistry();
      registry.addFeedParser(new NamedParser('rss_2.0', 'first'));
      registry.addFeedParser(new NamedParser('atom_1.0', 'atom'));
      registry.addFeedParser(new NamedParser('rss_2.0', 'second'));
      expect(registry.getFeedParserTypes().join(',')).assertEqual('atom_1.0,rss_2.0');
      expect((registry.getFeedParsers()[1] as NamedParser).label).assertEqual('second');
    });

    it('moduleParsersAreScoped', 0, () => {
      const registry = new PluginRegistry();
      registry.addModuleParser('rss_2.0.item', new CreatorParser());
      expect(registry.getModuleParsers('rss_2.0.item').length).assertEqual(1);
      expect(registry.getModuleParsers('rss_2.0.feed').length).assertEqual(0);
    });

    it('baseParserParsesModulesAndForeignMarkup', 0, () => {
      plugins().addModuleParser('test_1.0.feed', new CreatorParser());
      const root = new Element('feed', FEED_NS);
      root.addContent(new Element('title', FEED_NS).setText('t'));
      root.addContent(new Element('creator', DC_NS).setText('Jane'));
      root.addContent(new Element('extra', Namespace.getNamespace('x', 'urn:other')).setText('e'));
      const feed = new TestParser().parse(new Document(root));
      expect((feed.getModule(DCModule.URI) as DCModule).creator).assertEqual('Jane');
      expect(feed.foreignMarkup.length).assertEqual(1);
      expect(feed.foreignMarkup[0].getName()).assertEqual('extra');
      expect(feed.foreignMarkup[0].getParent()).assertNull();
      expect(feed.styleSheet).assertNull();
    });
  });
}
