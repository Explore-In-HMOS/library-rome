// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/io/MediaModuleParser.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleParser } from '../../../io/ModuleParser';
import { NumberParser } from '../../../io/impl/NumberParser';
import { Doubles } from '../../../utils/Doubles';
import { IllegalArgumentException, NumberFormatException } from '../../../utils/Exceptions';
import { Integers } from '../../../utils/Integers';
import { BigDecimal, currencyInstance, parseJavaInt } from '../../../utils/JavaMath';
import { parseUri, parseUrl } from '../../../utils/JavaNet';
import { Longs } from '../../../utils/Longs';
import { Strings } from '../../../utils/Strings';
import { URIs } from '../../../utils/URIs';
import { GeoRSSModule } from '../../georss/GeoRSSModule';
import { SimpleParser } from '../../georss/SimpleParser';
import { MediaEntryModule } from '../MediaEntryModule';
import { MediaModule } from '../MediaModule';
import { javaFloatingString } from './MediaModuleGenerator';
import { Category } from '../types/Category';
import { Community } from '../types/Community';
import { Credit } from '../types/Credit';
import { Embed, EmbedParam } from '../types/Embed';
import { Expression } from '../types/Expression';
import { Hash } from '../types/Hash';
import { License } from '../types/License';
import { Location } from '../types/Location';
import { MediaContent } from '../types/MediaContent';
import { MediaGroup } from '../types/MediaGroup';
import { Metadata, MetadataRightsStatus } from '../types/Metadata';
import { PeerLink } from '../types/PeerLink';
import { PlayerReference } from '../types/PlayerReference';
import { Price, PriceType } from '../types/Price';
import { Rating } from '../types/Rating';
import { Restriction, RestrictionRelationship, RestrictionType } from '../types/Restriction';
import { Scene } from '../types/Scene';
import { StarRating } from '../types/StarRating';
import { Statistics } from '../types/Statistics';
import { Status, StatusState } from '../types/Status';
import { SubTitle } from '../types/SubTitle';
import { Tag } from '../types/Tag';
import { Text } from '../types/Text';
import { Thumbnail } from '../types/Thumbnail';
import { Time } from '../types/Time';
import { UrlReference } from '../types/UrlReference';

const NS: Namespace = Namespace.getNamespace(MediaModule.URI);
const FILESIZE_WITH_UNIT_PATTERN: RegExp = /^([\d,.]+)([TGMK])?B$/i;
const UNIT_POWERS: Map<string, number> = new Map<string, number>([['k', 3], ['m', 6], ['g', 9], ['t', 12]]);

// Java String.equalsIgnoreCase.
function equalsIgnoreCase(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i++) {
    const x = a.charAt(i);
    const y = b.charAt(i);
    if (x !== y && x.toUpperCase() !== y.toUpperCase() && x.toLowerCase() !== y.toLowerCase()) {
      return false;
    }
  }
  return true;
}

function isJavaRegexSpace(c: string): boolean {
  return c === ' ' || c === '\t' || c === '\n' || c === '\x0B' || c === '\f' || c === '\r';
}

// Java String.split("\\s*" + separator + "\\s*") without the regex, which backtracks quadratically on long spaces:
// whitespace next to each separator is dropped, and trailing empty strings once there was a separator.
function javaSplitAround(s: string, separator: string): string[] {
  const parts = s.split(separator);
  if (parts.length === 1) {
    return parts;
  }
  const trimmed = parts.map((part: string, i: number) => {
    let start = 0;
    let end = part.length;
    while (i > 0 && start < end && isJavaRegexSpace(part.charAt(start))) {
      start++;
    }
    while (i < parts.length - 1 && end > start && isJavaRegexSpace(part.charAt(end - 1))) {
      end--;
    }
    return part.substring(start, end);
  });
  while (trimmed.length > 0 && trimmed[trimmed.length - 1] === '') {
    trimmed.pop();
  }
  return trimmed;
}

// Float.valueOf: throws NumberFormatException. Stored as the number Float.toString prints, so 29.97 stays 29.97.
function floatValueOf(s: string): number {
  const value = NumberParser.parseFloat(s);
  if (value === null) {
    throw new NumberFormatException(`For input string: "${s}"`);
  }
  return Doubles.parse(javaFloatingString(value, true))!;
}

// Java Enum.valueOf.
function enumValueOf<T>(values: T[], name: string | null, type: string): T {
  if (name === null) {
    throw new TypeError('Name is null');
  }
  const found = values.find((v: T) => `${v}` === name);
  if (found === undefined) {
    throw new IllegalArgumentException(`No enum constant com.rometools.modules.mediarss.types.${type}.${name}`);
  }
  return found;
}

export class MediaModuleParser implements ModuleParser {
  getNamespaceUri(): string {
    return MediaModule.URI;
  }

  parse(mmRoot: Element): Module | null {
    const mod = mmRoot.getName() === 'channel' || mmRoot.getName() === 'feed' ? new MediaModule() : new MediaEntryModule();
    mod.metadata = this.parseMetadata(mmRoot);
    mod.player = this.parsePlayer(mmRoot);
    if (mod instanceof MediaEntryModule) {
      mod.mediaContents = this.parseContent(mmRoot);
      mod.mediaGroups = this.parseGroup(mmRoot);
    }
    return mod;
  }

  static parseFileSize(fileSizeAttrValue: string): number {
    const nonWSFileSize = fileSizeAttrValue.replace(/[ \t\n\x0B\f\r]/g, '');
    if (/^\d+$/.test(nonWSFileSize)) {
      const value = NumberParser.parseLong(nonWSFileSize);
      if (value === null) {
        throw new NumberFormatException(`For input string: "${nonWSFileSize}"`);
      }
      return value;
    }
    const sizeWithUnitMatcher = FILESIZE_WITH_UNIT_PATTERN.exec(nonWSFileSize);
    if (sizeWithUnitMatcher !== null) {
      const number = BigDecimal.parse(sizeWithUnitMatcher[1].replace(/,/g, '.'));
      const unit = sizeWithUnitMatcher[2];
      const power = unit === undefined ? 0 : UNIT_POWERS.get(unit.toLowerCase())!;
      return number.multiplyByPowerOfTen(power).longValue();
    }
    throw new NumberFormatException(`Invalid file size: ${fileSizeAttrValue}`);
  }

  private parseContent(e: Element): MediaContent[] {
    const contents = e.getChildren('content', this.getNS());
    const values: MediaContent[] = [];
    try {
      for (const content of contents) {
        let mc: MediaContent | null = null;
        if (content.getAttributeValue('url') !== null) {
          try {
            mc = new MediaContent(new UrlReference(URIs.parse(content.getAttributeValue('url')!)));
            mc.player = this.parsePlayer(content);
          } catch (ex) {
          }
        } else {
          mc = new MediaContent(this.parsePlayer(content));
        }
        if (mc === null) {
          continue;
        }
        const c = mc;
        values.push(c);
        const attr = (name: string): string | null => content.getAttributeValue(name);
        const tryAttr = (name: string, set: (value: string) => void): void => {
          try {
            if (attr(name) !== null) {
              set(attr(name)!);
            }
          } catch (ex) {
          }
        };
        tryAttr('channels', (v: string) => {
          c.audioChannels = parseJavaInt(v);
        });
        tryAttr('bitrate', (v: string) => {
          c.bitrate = floatValueOf(v);
        });
        tryAttr('duration', (v: string) => {
          c.duration = Longs.parseDecimal(v);
        });
        c.medium = attr('medium');
        const expression = attr('expression');
        if (expression !== null) {
          if (equalsIgnoreCase(expression, 'full')) {
            c.expression = Expression.FULL;
          } else if (equalsIgnoreCase(expression, 'sample')) {
            c.expression = Expression.SAMPLE;
          } else if (equalsIgnoreCase(expression, 'nonstop')) {
            c.expression = Expression.NONSTOP;
          }
        }
        tryAttr('fileSize', (v: string) => {
          c.fileSize = MediaModuleParser.parseFileSize(v);
        });
        tryAttr('framerate', (v: string) => {
          c.framerate = floatValueOf(v);
        });
        tryAttr('height', (v: string) => {
          c.height = parseJavaInt(v);
        });
        c.language = attr('lang');
        c.metadata = this.parseMetadata(content);
        tryAttr('samplingrate', (v: string) => {
          c.samplingrate = floatValueOf(v);
        });
        c.type = attr('type');
        tryAttr('width', (v: string) => {
          c.width = parseJavaInt(v);
        });
        if (attr('isDefault') !== null) {
          c.defaultContent = equalsIgnoreCase(attr('isDefault')!, 'true');
        }
      }
    } catch (ex) {
    }
    return values;
  }

  private parseGroup(e: Element): MediaGroup[] {
    return e.getChildren('group', this.getNS()).map((group: Element) => {
      const g = new MediaGroup(this.parseContent(group));
      const index = g.contents.findIndex((c: MediaContent) => c.defaultContent);
      if (index >= 0) {
        g.defaultContentIndex = index;
      }
      g.metadata = this.parseMetadata(group);
      return g;
    });
  }

  private parseMetadata(e: Element): Metadata {
    const md = new Metadata();
    this.parseCategories(e, md);
    this.parseCopyright(e, md);
    this.parseCredits(e, md);
    this.parseDescription(e, md);
    this.parseHash(e, md);
    this.parseKeywords(e, md);
    this.parseRatings(e, md);
    this.parseText(e, md);
    this.parseThumbnail(e, md);
    this.parseTitle(e, md);
    this.parseRestrictions(e, md);
    this.parseAdultMetadata(e, md);
    this.parseBackLinks(e, md);
    this.parseComments(e, md);
    this.parseCommunity(e, md);
    this.parsePrices(e, md);
    this.parseResponses(e, md);
    this.parseStatus(e, md);
    this.parseEmbed(e, md);
    this.parseLicenses(e, md);
    this.parseSubTitles(e, md);
    this.parsePeerLinks(e, md);
    this.parseRights(e, md);
    this.parseLocations(e, md);
    this.parseScenes(e, md);
    return md;
  }

  private parseScenes(e: Element, md: Metadata): void {
    const scenesElement = e.getChild('scenes', this.getNS());
    if (scenesElement !== null) {
      md.scenes = scenesElement.getChildren('scene', this.getNS()).map((sceneElement: Element) => {
        const scene = new Scene();
        scene.title = sceneElement.getChildText('sceneTitle', this.getNS());
        scene.description = sceneElement.getChildText('sceneDescription', this.getNS());
        const sceneStartTime = sceneElement.getChildText('sceneStartTime', this.getNS());
        if (sceneStartTime !== null) {
          scene.startTime = Time.parse(sceneStartTime);
        }
        const sceneEndTime = sceneElement.getChildText('sceneEndTime', this.getNS());
        if (sceneEndTime !== null) {
          scene.endTime = Time.parse(sceneEndTime);
        }
        return scene;
      });
    }
  }

  private parseLocations(e: Element, md: Metadata): void {
    const geoRssParser = new SimpleParser();
    md.locations = e.getChildren('location', this.getNS()).map((locationElement: Element) => {
      const location = new Location();
      location.description = locationElement.getAttributeValue('description');
      if (locationElement.getAttributeValue('start') !== null) {
        location.start = Time.parse(locationElement.getAttributeValue('start')!);
      }
      if (locationElement.getAttributeValue('end') !== null) {
        location.end = Time.parse(locationElement.getAttributeValue('end')!);
      }
      const geoRssModule = geoRssParser.parse(locationElement);
      if (geoRssModule instanceof GeoRSSModule) {
        location.geoRss = geoRssModule as GeoRSSModule;
      }
      return location;
    });
  }

  private parseRights(e: Element, md: Metadata): void {
    const rightsElement = e.getChild('rights', this.getNS());
    if (rightsElement !== null && rightsElement.getAttributeValue('status') !== null) {
      md.rights = enumValueOf([MetadataRightsStatus.userCreated, MetadataRightsStatus.official],
        rightsElement.getAttributeValue('status'), 'Metadata.RightsStatus');
    }
  }

  private parsePeerLinks(e: Element, md: Metadata): void {
    md.peerLinks = e.getChildren('peerLink', this.getNS()).map((peerLinkElement: Element) => {
      const peerLink = new PeerLink();
      peerLink.type = peerLinkElement.getAttributeValue('type');
      peerLink.href = this.urlOrNull(peerLinkElement.getAttributeValue('href'));
      return peerLink;
    });
  }

  private parseSubTitles(e: Element, md: Metadata): void {
    md.subTitles = e.getChildren('subTitle', this.getNS()).map((subTitleElement: Element) => {
      const subTitle = new SubTitle();
      subTitle.type = subTitleElement.getAttributeValue('type');
      subTitle.lang = subTitleElement.getAttributeValue('lang');
      subTitle.href = this.urlOrNull(subTitleElement.getAttributeValue('href'));
      return subTitle;
    });
  }

  private parseLicenses(e: Element, md: Metadata): void {
    md.licenses = e.getChildren('license', this.getNS()).map((licenseElement: Element) => {
      const license = new License();
      license.type = licenseElement.getAttributeValue('type');
      license.value = licenseElement.getTextTrim();
      license.href = this.urlOrNull(licenseElement.getAttributeValue('href'));
      return license;
    });
  }

  private parsePrices(e: Element, md: Metadata): void {
    md.prices = e.getChildren('price', this.getNS()).map((priceElement: Element) => {
      const price = new Price();
      const currency = priceElement.getAttributeValue('currency');
      if (currency !== null) {
        try {
          price.currency = currencyInstance(currency);
        } catch (ex) {
        }
      }
      const value = priceElement.getAttributeValue('price');
      if (value !== null) {
        try {
          price.price = BigDecimal.parse(value).toString();
        } catch (ex) {
        }
      }
      const type = priceElement.getAttributeValue('type');
      if (type !== null) {
        price.type = enumValueOf([PriceType.RENT, PriceType.PURCHASE, PriceType.PACKAGE, PriceType.SUBSCRIPTION],
          type.toUpperCase(), 'Price.Type');
      }
      price.info = this.urlOrNull(priceElement.getAttributeValue('info'));
      return price;
    });
  }

  private parseStatus(e: Element, md: Metadata): void {
    const statusElement = e.getChild('status', this.getNS());
    if (statusElement !== null) {
      const status = new Status();
      status.state = enumValueOf([StatusState.active, StatusState.blocked, StatusState.deleted],
        statusElement.getAttributeValue('state'), 'Status.State');
      status.reason = statusElement.getAttributeValue('reason');
      md.status = status;
    }
  }

  // ROME leaves a null in the array for a backLink that is not a URL; our string[] drops it.
  private parseBackLinks(e: Element, md: Metadata): void {
    const backLinksElement = e.getChild('backLinks', this.getNS());
    if (backLinksElement !== null) {
      md.backLinks = backLinksElement.getChildren('backLink', this.getNS())
        .map((backLink: Element) => this.urlOrNull(backLink.getTextTrim()))
        .filter((url: string | null) => url !== null)
        .map((url: string | null) => url!);
    }
  }

  private parseComments(e: Element, md: Metadata): void {
    const commentsElement = e.getChild('comments', this.getNS());
    if (commentsElement !== null) {
      md.comments = commentsElement.getChildren('comment', this.getNS()).map((c: Element) => c.getTextTrim());
    }
  }

  private parseResponses(e: Element, md: Metadata): void {
    const responsesElement = e.getChild('responses', this.getNS());
    if (responsesElement !== null) {
      md.responses = responsesElement.getChildren('response', this.getNS()).map((r: Element) => r.getTextTrim());
    }
  }

  private parseCommunity(e: Element, md: Metadata): void {
    const communityElement = e.getChild('community', this.getNS());
    if (communityElement === null) {
      return;
    }
    const community = new Community();
    const starRatingElement = communityElement.getChild('starRating', this.getNS());
    if (starRatingElement !== null) {
      const starRating = new StarRating();
      starRating.average = Doubles.parse(starRatingElement.getAttributeValue('average'));
      starRating.count = Integers.parse(starRatingElement.getAttributeValue('count'));
      starRating.max = Integers.parse(starRatingElement.getAttributeValue('max'));
      starRating.min = Integers.parse(starRatingElement.getAttributeValue('min'));
      community.starRating = starRating;
    }
    const statisticsElement = communityElement.getChild('statistics', this.getNS());
    if (statisticsElement !== null) {
      const statistics = new Statistics();
      statistics.favorites = Integers.parse(statisticsElement.getAttributeValue('favorites'));
      statistics.views = Integers.parse(statisticsElement.getAttributeValue('views'));
      community.statistics = statistics;
    }
    const tagsElement = communityElement.getChild('tags', this.getNS());
    if (tagsElement !== null) {
      for (const tagText of javaSplitAround(tagsElement.getTextTrim(), ',')) {
        const tagParts = javaSplitAround(tagText, ':');
        if (tagParts.length === 0) {
          throw new RangeError('Index 0 out of bounds for length 0');
        }
        const tag = new Tag(tagParts[0]);
        if (tagParts.length > 1) {
          tag.weight = Integers.parse(tagParts[1]);
        }
        community.addTag(tag);
      }
    }
    md.community = community;
  }

  private parseCategories(e: Element, md: Metadata): void {
    md.categories = e.getChildren('category', this.getNS()).map((cat: Element) =>
      new Category(cat.getAttributeValue('scheme'), cat.getAttributeValue('label'), cat.getText()));
  }

  private parseCopyright(e: Element, md: Metadata): void {
    try {
      const copy = e.getChild('copyright', this.getNS());
      if (copy !== null) {
        md.copyright = copy.getText();
        if (copy.getAttributeValue('url') !== null) {
          md.copyrightUrl = parseUri(copy.getAttributeValue('url')!);
        }
      }
    } catch (ex) {
    }
  }

  // ROME sets credits inside the loop, so a feed without media:credit keeps the default empty array.
  private parseCredits(e: Element, md: Metadata): void {
    const credits = e.getChildren('credit', this.getNS());
    if (credits.length > 0) {
      md.credits = credits.map((cred: Element) =>
        new Credit(cred.getAttributeValue('scheme'), cred.getAttributeValue('role'), cred.getText()));
    }
  }

  private parseDescription(e: Element, md: Metadata): void {
    const description = e.getChild('description', this.getNS());
    if (description !== null) {
      md.description = description.getText();
      md.descriptionType = description.getAttributeValue('type');
    }
  }

  private parseEmbed(e: Element, md: Metadata): void {
    const embedElement = e.getChild('embed', this.getNS());
    if (embedElement !== null) {
      const embed = new Embed();
      embed.width = Integers.parse(embedElement.getAttributeValue('width'));
      embed.height = Integers.parse(embedElement.getAttributeValue('height'));
      embed.url = this.urlOrNull(embedElement.getAttributeValue('url'));
      embed.params = embedElement.getChildren('param', this.getNS()).map((param: Element) =>
        new EmbedParam(param.getAttributeValue('name'), param.getTextTrim()));
      md.embed = embed;
    }
  }

  private parseHash(e: Element, md: Metadata): void {
    const hash = e.getChild('hash', this.getNS());
    if (hash !== null) {
      md.hash = new Hash(hash.getAttributeValue('algo'), hash.getText());
    }
  }

  // java.util.StringTokenizer(text, ","): empty tokens are skipped.
  private parseKeywords(e: Element, md: Metadata): void {
    const keywords = e.getChild('keywords', this.getNS());
    if (keywords !== null) {
      md.keywords = keywords.getText().split(',').filter((t: string) => t.length > 0)
        .map((t: string) => Strings.trim(t)!);
    }
  }

  private parseRatings(e: Element, md: Metadata): void {
    md.ratings = e.getChildren('rating', this.getNS()).map((ratingElement: Element) =>
      new Rating(Strings.trimToNull(ratingElement.getAttributeValue('scheme')) ?? 'urn:simple', ratingElement.getText()));
  }

  private parseText(e: Element, md: Metadata): void {
    const values: Text[] = [];
    for (const text of e.getChildren('text', this.getNS())) {
      try {
        const start = text.getAttributeValue('start') === null ? null : Time.parse(text.getAttributeValue('start')!);
        const end = text.getAttributeValue('end') === null ? null : Time.parse(text.getAttributeValue('end')!);
        values.push(new Text(text.getAttributeValue('type'), text.getTextTrim(), start, end));
      } catch (ex) {
      }
    }
    md.text = values;
  }

  private parseThumbnail(e: Element, md: Metadata): void {
    const values: Thumbnail[] = [];
    for (const thumb of e.getChildren('thumbnail', this.getNS())) {
      try {
        const timeAttr = Strings.trimToNull(thumb.getAttributeValue('time'));
        const time = timeAttr === null ? null : Time.parse(timeAttr);
        const width = Integers.parse(thumb.getAttributeValue('width'));
        const height = Integers.parse(thumb.getAttributeValue('height'));
        const url = thumb.getAttributeValue('url');
        if (url === null) {
          throw new TypeError('url is null');
        }
        values.push(new Thumbnail(parseUri(url), width, height, time));
      } catch (ex) {
      }
    }
    md.thumbnail = values;
  }

  private parseTitle(e: Element, md: Metadata): void {
    const title = e.getChild('title', this.getNS());
    if (title !== null) {
      md.title = title.getText();
      md.titleType = title.getAttributeValue('type');
    }
  }

  private parseRestrictions(e: Element, md: Metadata): void {
    md.restrictions = e.getChildren('restriction', this.getNS()).map((r: Element) => {
      let type: RestrictionType | null = null;
      const restrictionType = r.getAttributeValue('type');
      if (restrictionType !== null) {
        if (equalsIgnoreCase(restrictionType, RestrictionType.URI)) {
          type = RestrictionType.URI;
        } else if (equalsIgnoreCase(restrictionType, RestrictionType.COUNTRY)) {
          type = RestrictionType.COUNTRY;
        } else if (equalsIgnoreCase(restrictionType, RestrictionType.SHARING)) {
          type = RestrictionType.SHARING;
        }
      }
      const relationshipAttr = r.getAttributeValue('relationship');
      if (relationshipAttr === null) {
        throw new TypeError('relationship is null');
      }
      let relationship: RestrictionRelationship | null = null;
      if (equalsIgnoreCase(relationshipAttr, 'allow')) {
        relationship = RestrictionRelationship.ALLOW;
      } else if (equalsIgnoreCase(relationshipAttr, 'deny')) {
        relationship = RestrictionRelationship.DENY;
      }
      return new Restriction(relationship, type, r.getTextTrim());
    });
  }

  private parseAdultMetadata(e: Element, md: Metadata): void {
    const adult = e.getChild('adult', this.getNS());
    if (adult !== null && md.ratings.length === 0) {
      md.ratings = [new Rating('urn:simple', adult.getTextTrim() === 'true' ? 'adult' : 'nonadult')];
    }
  }

  private parsePlayer(e: Element): PlayerReference | null {
    const player = e.getChild('player', this.getNS());
    if (player === null) {
      return null;
    }
    try {
      const width = player.getAttributeValue('width') === null ? null : parseJavaInt(player.getAttributeValue('width')!);
      const height = player.getAttributeValue('height') === null ? null :
        parseJavaInt(player.getAttributeValue('height')!);
      const url = player.getAttributeValue('url');
      if (url === null) {
        throw new TypeError('url is null');
      }
      return new PlayerReference(parseUri(url), width, height);
    } catch (ex) {
      return null;
    }
  }

  // new URL(spec).toString(), or null where ROME catches the MalformedURLException.
  private urlOrNull(spec: string | null): string | null {
    if (spec === null) {
      return null;
    }
    try {
      return parseUrl(spec).toString();
    } catch (ex) {
      return null;
    }
  }

  getNS(): Namespace {
    return NS;
  }
}
