// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/io/ITunesParser.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Format } from '../../../xml/Format';
import { XMLOutputter } from '../../../xml/XmlOutputter';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { parseJavaInt } from '../../../utils/JavaMath';
import { parseUrl } from '../../../utils/JavaNet';
import { Strings } from '../../../utils/Strings';
import { EntryInformation } from '../EntryInformation';
import { FeedInformation } from '../FeedInformation';
import { ITunes } from '../ITunes';
import { Category } from '../types/Category';
import { Duration } from '../types/Duration';
import { Subcategory } from '../types/Subcategory';

const EXPLICIT_TRUE: string[] = ['yes', 'explicit', 'true'];
const EXPLICIT_FALSE: string[] = ['clean', 'no', 'false'];

function trim(s: string): string {
  return Strings.trim(s)!;
}

// Java's Character.toUpperCase(char): a one-char mapping only.
function upperChar(c: string): string {
  const upper = c.toUpperCase();
  return upper.length === 1 ? upper : c;
}

// Java's String.equalsIgnoreCase.
function equalsIgnoreCase(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i++) {
    const x = upperChar(a.charAt(i));
    const y = upperChar(b.charAt(i));
    if (a.charAt(i) !== b.charAt(i) && x !== y && x.toLowerCase() !== y.toLowerCase()) {
      return false;
    }
  }
  return true;
}

// Integer.valueOf, or null where it throws NumberFormatException (ROME logs and skips the value).
function parseInteger(s: string): number | null {
  try {
    return parseJavaInt(trim(s));
  } catch (e) {
    return null;
  }
}

export class ITunesParser implements ModuleParser {
  protected ns: Namespace = Namespace.getNamespace(ITunes.URI);

  getNamespaceUri(): string {
    return ITunes.URI;
  }

  parse(element: Element): Module | null {
    let module: ITunes | null = null;
    const ns = this.ns;
    if (element.getName() === 'channel') {
      const feedInfo = new FeedInformation();
      module = feedInfo;
      const owner = element.getChild('owner', ns);
      if (owner !== null) {
        const name = owner.getChild('name', ns);
        if (name !== null) {
          feedInfo.ownerName = trim(name.getValue());
        }
        const email = owner.getChild('email', ns);
        if (email !== null) {
          feedInfo.ownerEmailAddress = trim(email.getValue());
        }
      }
      for (const category of element.getChildren('category', ns)) {
        const text = category.getAttribute('text');
        if (text !== null) {
          const cat = new Category();
          cat.name = trim(text.getValue());
          for (const subCategory of category.getChildren('category', ns)) {
            const subText = subCategory.getAttribute('text');
            if (subText !== null) {
              cat.addSubcategory(new Subcategory(trim(subText.getValue())));
            }
          }
          feedInfo.categories.push(cat);
        }
      }
      const complete = element.getChild('complete', ns);
      if (complete !== null) {
        feedInfo.complete = complete.getTextTrim().toLowerCase() === 'yes';
      }
      const newFeedUrl = element.getChild('new-feed-url', ns);
      if (newFeedUrl !== null) {
        feedInfo.newFeedUrl = newFeedUrl.getTextTrim();
      }
      const type = element.getChild('type', ns);
      if (type !== null) {
        feedInfo.type = type.getTextTrim();
      }
    } else if (element.getName() === 'item') {
      const entryInfo = new EntryInformation();
      module = entryInfo;
      const duration = element.getChild('duration', ns);
      if (duration !== null) {
        try {
          entryInfo.duration = Duration.parse(trim(duration.getValue()));
        } catch (e) {
          // ROME logs "Failed to parse duration" and leaves duration unset.
        }
      }
      const closedCaptioned = element.getChild('isClosedCaptioned', ns);
      if (closedCaptioned !== null && equalsIgnoreCase(trim(closedCaptioned.getValue()), 'yes')) {
        entryInfo.closedCaptioned = true;
      }
      const order = element.getChild('order', ns);
      if (order !== null) {
        entryInfo.order = parseInteger(order.getValue());
      }
      const season = element.getChild('season', ns);
      if (season !== null) {
        entryInfo.season = parseInteger(season.getValue());
      }
      const episode = element.getChild('episode', ns);
      if (episode !== null) {
        entryInfo.episode = parseInteger(episode.getValue());
      }
      const episodeType = element.getChild('episodeType', ns);
      if (episodeType !== null) {
        entryInfo.episodeType = episodeType.getTextTrim();
      }
      const title = element.getChild('title', ns);
      if (title !== null) {
        entryInfo.title = trim(title.getValue());
      }
    }
    if (module !== null) {
      const author = element.getChild('author', ns);
      if (author !== null) {
        module.author = author.getText();
      }
      const block = element.getChild('block', ns);
      if (block !== null && equalsIgnoreCase(trim(block.getValue()), 'Yes')) {
        module.block = true;
      }
      const explicit = element.getChild('explicit', ns);
      if (explicit !== null) {
        const explicitValue = trim(explicit.getValue()).toLowerCase();
        if (EXPLICIT_TRUE.includes(explicitValue)) {
          module.explicit = true;
        }
        if (EXPLICIT_FALSE.includes(explicitValue)) {
          module.explicit = false;
        }
      }
      const keywords = element.getChild('keywords', ns);
      if (keywords !== null) {
        module.keywords = trim(this.getXmlInnerText(keywords)).split(',').filter((k: string) => k.length > 0);
      }
      const subtitle = element.getChild('subtitle', ns);
      if (subtitle !== null) {
        module.subtitle = subtitle.getTextTrim();
      }
      const summary = element.getChild('summary', ns);
      if (summary !== null) {
        module.summary = summary.getTextTrim();
      }
      const image = element.getChild('image', ns);
      const href = image === null ? null : image.getAttributeValue('href');
      if (href !== null) {
        try {
          module.image = parseUrl(trim(href)).toString();
        } catch (e) {
          // ROME logs the MalformedURLException and leaves image unset.
        }
        module.imageUri = trim(href);
      }
    }
    return module;
  }

  protected getXmlInnerText(e: Element): string {
    return new XMLOutputter(Format.getRawFormat()).outputString(e.getContent());
  }
}
