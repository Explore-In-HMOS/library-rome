// Ported from ROME rome/src/main/java/com/rometools/rome/io/WireFeedOutput.java (Apache-2.0)
import { WireFeed } from '../feed/WireFeed';
import { IllegalArgumentException } from '../utils/Exceptions';
import { Document, ProcessingInstruction } from '../xml/Dom';
import { Format } from '../xml/Format';
import { XMLOutputter } from '../xml/XmlOutputter';
import { plugins } from './impl/PluginRegistry';

/** Writes RSS and Atom feeds with the generator registered for the feed's type. */
export class WireFeedOutput {
  static getSupportedFeedTypes(): string[] {
    return plugins().getFeedGeneratorTypes();
  }

  outputString(feed: WireFeed, prettyPrint: boolean = true): string {
    const doc = this.outputJDom(feed);
    const format = prettyPrint ? Format.getPrettyFormat() : Format.getCompactFormat();
    if (feed.encoding !== null) {
      format.setEncoding(feed.encoding);
    }
    return new XMLOutputter(format).outputString(doc);
  }

  outputJDom(feed: WireFeed): Document {
    const type = feed.feedType;
    const generator = type === null ? null : plugins().getFeedGenerator(type);
    if (generator === null) {
      throw new IllegalArgumentException(`Invalid feed type [${type}]`);
    }
    const doc = generator.generate(feed);
    if (feed.styleSheet !== null) {
      // JDOM's ProcessingInstruction(target, Map) data: key="value" pairs, values not escaped.
      doc.addContentAt(0, new ProcessingInstruction('xml-stylesheet', `type="text/xsl" href="${feed.styleSheet}"`));
    }
    return doc;
  }
}
