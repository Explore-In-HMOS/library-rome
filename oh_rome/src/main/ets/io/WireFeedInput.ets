// Ported from ROME rome/src/main/java/com/rometools/rome/io/WireFeedInput.java (Apache-2.0)
import { WireFeed } from '../feed/WireFeed';
import { IllegalArgumentException } from '../utils/Exceptions';
import { Document, XmlParseException } from '../xml/Dom';
import { parseXml } from '../xml/XmlParser';
import { ParsingFeedException } from './FeedException';
import { plugins } from './impl/PluginRegistry';
import { WireFeedParser } from './WireFeedParser';
import { fixXml } from './impl/XmlFixerReader';
import { XmlReader } from './XmlReader';

/**
 * Parses RSS and Atom feeds with the first registered parser that accepts the document. A string is read like ROME's
 * build(Reader); bytes are decoded first like new XmlReader(InputStream).
 */
export class WireFeedInput {
  xmlHealerOn: boolean = true;
  allowDoctypes: boolean = false;

  static getSupportedFeedTypes(): string[] {
    return plugins().getFeedParserTypes();
  }

  build(input: string | Uint8Array | Document): WireFeed {
    if (input instanceof Document) {
      return this.buildDocument(input as Document);
    }
    const xml = input instanceof Uint8Array ? new XmlReader(input as Uint8Array).read() : input as string;
    try {
      return this.buildDocument(parseXml(this.xmlHealerOn ? fixXml(xml) : xml, this.allowDoctypes));
    } catch (e) {
      if (e instanceof XmlParseException) {
        // JDOM's JDOMParseException message (SAXBuilderEngine.java:232-237).
        const p = e as XmlParseException;
        const where = p.inBuilding ? 'Error in building' : `Error on line ${p.lineNumber}`;
        throw new ParsingFeedException(`Invalid XML: ${where}: ${p.message}`, e as Error);
      }
      if (e instanceof IllegalArgumentException) {
        throw e as Error;
      }
      throw new ParsingFeedException('Invalid XML', e as Error);
    }
  }

  private buildDocument(document: Document): WireFeed {
    const parser = plugins().getFeedParsers().find((p: WireFeedParser) => p.isMyType(document));
    if (parser === undefined) {
      throw new IllegalArgumentException('Invalid document');
    }
    return parser.parse(document);
  }
}
