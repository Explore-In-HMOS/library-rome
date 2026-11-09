// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/io/MediaModuleGenerator.java (Apache-2.0)
import { Element, Namespace } from '../../../xml/Dom';
import { Module } from '../../../feed/module/Module';
import { ModuleGenerator } from '../../../io/ModuleGenerator';
import { NumberParser } from '../../../io/impl/NumberParser';
import { GMLGenerator } from '../../georss/GMLGenerator';
import { MediaEntryModule } from '../MediaEntryModule';
import { MediaModule } from '../MediaModule';
import { MediaContent } from '../types/MediaContent';
import { MediaGroup } from '../types/MediaGroup';
import { Metadata } from '../types/Metadata';
import { PlayerReference } from '../types/PlayerReference';
import { Rating } from '../types/Rating';
import { Time } from '../types/Time';
import { UrlReference } from '../types/UrlReference';

const NS: Namespace = Namespace.getNamespace('media', MediaModule.URI);

// Float.toString / Double.toString: shortest digits that read back as the same value, in Java's layout.
// Known limit: JDK 17's FloatingDecimal is not always shortest (fixed in JDK 19); those rare values print differently.
export function javaFloatingString(v: number, isFloat: boolean): string {
  if (Number.isNaN(v)) {
    return 'NaN';
  }
  if (!Number.isFinite(v)) {
    return v > 0 ? 'Infinity' : '-Infinity';
  }
  if (v === 0) {
    return 1 / v < 0 ? '-0.0' : '0.0';
  }
  // A float field holds any double (the parser stores Float.toString's digits); Java's Float is the float it reads as.
  const a = isFloat ? NumberParser.parseFloat(String(Math.abs(v)))! : Math.abs(v);
  let exponential = a.toExponential();
  if (isFloat) {
    for (let p = 0; p < 9; p++) {
      exponential = a.toExponential(p);
      if (NumberParser.parseFloat(exponential) === a) {
        break;
      }
    }
  }
  const e = exponential.indexOf('e');
  const digits = exponential.substring(0, e).replace('.', '');
  const exp = Number(exponential.substring(e + 1));
  let out: string;
  if (a >= 1e-3 && a < 1e7) {
    out = exp >= 0 ? digits.substring(0, exp + 1).padEnd(exp + 1, '0') + '.' + (digits.substring(exp + 1) || '0') :
      '0.' + '0'.repeat(-exp - 1) + digits;
  } else {
    out = digits.charAt(0) + '.' + (digits.substring(1) || '0') + 'E' + exp;
  }
  return (v < 0 ? '-' : '') + out;
}

function intString(n: number | null): string | null {
  return n === null ? null : String(n);
}

function floatString(n: number | null): string | null {
  return n === null ? null : javaFloatingString(n, true);
}

function timeString(t: Time | null): string | null {
  return t === null ? null : t.toString();
}

export class MediaModuleGenerator implements ModuleGenerator {
  getNamespaceUri(): string {
    return MediaModule.URI;
  }

  getNamespaces(): Namespace[] {
    return [NS];
  }

  generate(module: Module, element: Element): void {
    if (module instanceof MediaModule) {
      this.generateMetadata(module.metadata, element);
      this.generatePlayer(module.player, element);
    }
    if (module instanceof MediaEntryModule) {
      for (const group of module.mediaGroups) {
        this.generateGroup(group, element);
      }
      for (const content of module.mediaContents) {
        this.generateContent(content, element);
      }
    }
  }

  generateContent(c: MediaContent, e: Element): void {
    const mc = new Element('content', NS);
    this.addNotNullAttribute(mc, 'medium', c.medium);
    this.addNotNullAttribute(mc, 'channels', intString(c.audioChannels));
    this.addNotNullAttribute(mc, 'bitrate', floatString(c.bitrate));
    this.addNotNullAttribute(mc, 'duration', intString(c.duration));
    this.addNotNullAttribute(mc, 'expression', c.expression);
    this.addNotNullAttribute(mc, 'fileSize', intString(c.fileSize));
    this.addNotNullAttribute(mc, 'framerate', floatString(c.framerate));
    this.addNotNullAttribute(mc, 'height', intString(c.height));
    this.addNotNullAttribute(mc, 'lang', c.language);
    this.addNotNullAttribute(mc, 'samplingrate', floatString(c.samplingrate));
    this.addNotNullAttribute(mc, 'type', c.type);
    this.addNotNullAttribute(mc, 'width', intString(c.width));
    if (c.defaultContent) {
      this.addNotNullAttribute(mc, 'isDefault', 'true');
    }
    if (c.reference instanceof UrlReference) {
      this.addNotNullAttribute(mc, 'url', (c.reference as UrlReference).url);
    }
    this.generatePlayer(c.player, mc);
    this.generateMetadata(c.metadata, mc);
    e.addContent(mc);
  }

  generateGroup(g: MediaGroup, e: Element): void {
    const t = new Element('group', NS);
    for (const content of g.contents) {
      this.generateContent(content, t);
    }
    this.generateMetadata(g.metadata, t);
    e.addContent(t);
  }

  generateMetadata(m: Metadata | null, e: Element): void {
    if (m === null) {
      return;
    }
    for (const cat of m.categories) {
      const c = this.generateSimpleElement('category', cat.value);
      this.addNotNullAttribute(c, 'scheme', cat.scheme);
      this.addNotNullAttribute(c, 'label', cat.label);
      e.addContent(c);
    }
    const copyright = this.addNotNullElement(e, 'copyright', m.copyright);
    this.addNotNullAttribute(copyright, 'url', m.copyrightUrl);
    for (const cred of m.credits) {
      const c = this.generateSimpleElement('credit', cred.name);
      this.addNotNullAttribute(c, 'role', cred.role);
      this.addNotNullAttribute(c, 'scheme', cred.scheme);
      e.addContent(c);
    }
    const desc = this.addNotNullElement(e, 'description', m.description);
    this.addNotNullAttribute(desc, 'type', m.descriptionType);
    if (m.hash !== null) {
      const hash = this.addNotNullElement(e, 'hash', m.hash.value);
      this.addNotNullAttribute(hash, 'algo', m.hash.algorithm);
    }
    if (m.keywords.length > 0) {
      this.addNotNullElement(e, 'keywords', m.keywords.join(', '));
    }
    for (const rat2 of m.ratings) {
      const rat = this.addNotNullElement(e, 'rating', rat2.value);
      this.addNotNullAttribute(rat, 'scheme', rat2.scheme);
      if (rat2.equals(Rating.ADULT)) {
        this.addNotNullElement(e, 'adult', 'true');
      } else if (rat2.equals(Rating.NONADULT)) {
        this.addNotNullElement(e, 'adult', 'false');
      }
    }
    for (const text of m.text) {
      const t = this.addNotNullElement(e, 'text', text.value);
      this.addNotNullAttribute(t, 'type', text.type);
      this.addNotNullAttribute(t, 'start', timeString(text.start));
      this.addNotNullAttribute(t, 'end', timeString(text.end));
    }
    const title = this.addNotNullElement(e, 'title', m.title);
    this.addNotNullAttribute(title, 'type', m.titleType);
    this.generateBackLinks(m, e);
    this.generateComments(m, e);
    this.generateCommunity(m, e);
    this.generateEmbed(m, e);
    this.generateLicenses(m, e);
    this.generateLocations(m, e);
    this.generatePeerLinks(m, e);
    this.generatePrices(m, e);
    this.generateResponses(m, e);
    for (const r of m.restrictions) {
      const res = this.addNotNullElement(e, 'restriction', r.value);
      this.addNotNullAttribute(res, 'type', r.type);
      this.addNotNullAttribute(res, 'relationship', r.relationship);
    }
    if (m.rights !== null) {
      const rights = new Element('rights', NS);
      rights.setAttribute('status', m.rights);
      e.addContent(rights);
    }
    this.generateScenes(m, e);
    this.generateStatus(m, e);
    this.generateSubTitles(m, e);
    this.generateThumbails(m, e);
  }

  private generateThumbails(m: Metadata, e: Element): void {
    for (const thumb of m.thumbnail) {
      const t = new Element('thumbnail', NS);
      this.addNotNullAttribute(t, 'url', thumb.url);
      this.addNotNullAttribute(t, 'width', intString(thumb.width));
      this.addNotNullAttribute(t, 'height', intString(thumb.height));
      this.addNotNullAttribute(t, 'time', timeString(thumb.time));
      e.addContent(t);
    }
  }

  private generateBackLinks(m: Metadata, e: Element): void {
    const backLinksElements = new Element('backLinks', NS);
    for (const backLink of m.backLinks) {
      this.addNotNullElement(backLinksElements, 'backLink', backLink);
    }
    if (backLinksElements.getChildren().length > 0) {
      e.addContent(backLinksElements);
    }
  }

  private generateComments(m: Metadata, e: Element): void {
    const commentsElements = new Element('comments', NS);
    for (const comment of m.comments) {
      this.addNotNullElement(commentsElements, 'comment', comment);
    }
    if (commentsElements.getChildren().length > 0) {
      e.addContent(commentsElements);
    }
  }

  private generateCommunity(m: Metadata, e: Element): void {
    const community = m.community;
    if (community === null) {
      return;
    }
    const communityElement = new Element('community', NS);
    if (community.starRating !== null) {
      const starRatingElement = new Element('starRating', NS);
      const average = community.starRating.average;
      this.addNotNullAttribute(starRatingElement, 'average', average === null ? null : javaFloatingString(average, false));
      this.addNotNullAttribute(starRatingElement, 'count', intString(community.starRating.count));
      this.addNotNullAttribute(starRatingElement, 'min', intString(community.starRating.min));
      this.addNotNullAttribute(starRatingElement, 'max', intString(community.starRating.max));
      if (starRatingElement.hasAttributes()) {
        communityElement.addContent(starRatingElement);
      }
    }
    if (community.statistics !== null) {
      const statisticsElement = new Element('statistics', NS);
      this.addNotNullAttribute(statisticsElement, 'views', intString(community.statistics.views));
      this.addNotNullAttribute(statisticsElement, 'favorites', intString(community.statistics.favorites));
      if (statisticsElement.hasAttributes()) {
        communityElement.addContent(statisticsElement);
      }
    }
    if (community.tags.length > 0) {
      const tagsElement = new Element('tags', NS);
      for (const tag of community.tags) {
        if (tagsElement.getTextTrim().length > 0) {
          tagsElement.addContent(', ');
        }
        tagsElement.addContent(tag.name ?? '');
        if (tag.weight !== null) {
          tagsElement.addContent(':');
          tagsElement.addContent(String(tag.weight));
        }
      }
      if (tagsElement.getTextTrim().length > 0) {
        communityElement.addContent(tagsElement);
      }
    }
    if (communityElement.getChildren().length > 0) {
      e.addContent(communityElement);
    }
  }

  private generateEmbed(m: Metadata, e: Element): void {
    const embed = m.embed;
    if (embed === null) {
      return;
    }
    const embedElement = new Element('embed', NS);
    this.addNotNullAttribute(embedElement, 'url', embed.url);
    this.addNotNullAttribute(embedElement, 'width', intString(embed.width));
    this.addNotNullAttribute(embedElement, 'height', intString(embed.height));
    for (const param of embed.params) {
      const paramElement = this.addNotNullElement(embedElement, 'param', param.value);
      this.addNotNullAttribute(paramElement, 'name', param.name);
    }
    if (embedElement.hasAttributes() || embedElement.getChildren().length > 0) {
      e.addContent(embedElement);
    }
  }

  private generateScenes(m: Metadata, e: Element): void {
    const scenesElement = new Element('scenes', NS);
    for (const scene of m.scenes) {
      const sceneElement = new Element('scene', NS);
      this.addNotNullElement(sceneElement, 'sceneTitle', scene.title);
      this.addNotNullElement(sceneElement, 'sceneDescription', scene.description);
      this.addNotNullElement(sceneElement, 'sceneStartTime', timeString(scene.startTime));
      this.addNotNullElement(sceneElement, 'sceneEndTime', timeString(scene.endTime));
      if (sceneElement.getChildren().length > 0) {
        scenesElement.addContent(sceneElement);
      }
    }
    if (scenesElement.getChildren().length > 0) {
      e.addContent(scenesElement);
    }
  }

  private generateLocations(m: Metadata, e: Element): void {
    const geoRssGenerator = new GMLGenerator();
    for (const location of m.locations) {
      const locationElement = new Element('location', NS);
      this.addNotNullAttribute(locationElement, 'description', location.description);
      this.addNotNullAttribute(locationElement, 'start', timeString(location.start));
      this.addNotNullAttribute(locationElement, 'end', timeString(location.end));
      if (location.geoRss !== null) {
        geoRssGenerator.generate(location.geoRss, locationElement);
      }
      if (locationElement.hasAttributes() || locationElement.getChildren().length > 0) {
        e.addContent(locationElement);
      }
    }
  }

  private generatePeerLinks(m: Metadata, e: Element): void {
    for (const peerLink of m.peerLinks) {
      const peerLinkElement = new Element('peerLink', NS);
      this.addNotNullAttribute(peerLinkElement, 'type', peerLink.type);
      this.addNotNullAttribute(peerLinkElement, 'href', peerLink.href);
      if (peerLinkElement.hasAttributes()) {
        e.addContent(peerLinkElement);
      }
    }
  }

  private generateSubTitles(m: Metadata, e: Element): void {
    for (const subTitle of m.subTitles) {
      const subTitleElement = new Element('subTitle', NS);
      this.addNotNullAttribute(subTitleElement, 'type', subTitle.type);
      this.addNotNullAttribute(subTitleElement, 'lang', subTitle.lang);
      this.addNotNullAttribute(subTitleElement, 'href', subTitle.href);
      if (subTitleElement.hasAttributes()) {
        e.addContent(subTitleElement);
      }
    }
  }

  private generateLicenses(m: Metadata, e: Element): void {
    for (const license of m.licenses) {
      const licenseElement = new Element('license', NS);
      this.addNotNullAttribute(licenseElement, 'type', license.type);
      this.addNotNullAttribute(licenseElement, 'href', license.href);
      if (license.value !== null) {
        licenseElement.addContent(license.value);
      }
      if (licenseElement.hasAttributes() || licenseElement.getTextTrim().length > 0) {
        e.addContent(licenseElement);
      }
    }
  }

  private generatePrices(m: Metadata, e: Element): void {
    for (const price of m.prices) {
      const priceElement = new Element('price', NS);
      if (price.type !== null) {
        priceElement.setAttribute('type', price.type.toLowerCase());
      }
      this.addNotNullAttribute(priceElement, 'info', price.info);
      this.addNotNullAttribute(priceElement, 'price', price.price);
      this.addNotNullAttribute(priceElement, 'currency', price.currency);
      if (priceElement.hasAttributes()) {
        e.addContent(priceElement);
      }
    }
  }

  private generateResponses(m: Metadata, e: Element): void {
    if (m.responses.length === 0) {
      return;
    }
    const responsesElements = new Element('responses', NS);
    for (const response of m.responses) {
      this.addNotNullElement(responsesElements, 'response', response);
    }
    e.addContent(responsesElements);
  }

  private generateStatus(m: Metadata, e: Element): void {
    const status = m.status;
    if (status === null) {
      return;
    }
    const statusElement = new Element('status', NS);
    if (status.state !== null) {
      statusElement.setAttribute('state', status.state);
    }
    this.addNotNullAttribute(statusElement, 'reason', status.reason);
    if (statusElement.hasAttributes()) {
      e.addContent(statusElement);
    }
  }

  generatePlayer(p: PlayerReference | null, e: Element): void {
    if (p === null) {
      return;
    }
    const t = new Element('player', NS);
    this.addNotNullAttribute(t, 'url', p.url);
    this.addNotNullAttribute(t, 'width', intString(p.width));
    this.addNotNullAttribute(t, 'height', intString(p.height));
    e.addContent(t);
  }

  protected addNotNullAttribute(target: Element | null, name: string, value: string | null): void {
    if (target !== null && value !== null) {
      target.setAttribute(name, value);
    }
  }

  protected addNotNullElement(target: Element, name: string, value: string | null): Element | null {
    if (value === null) {
      return null;
    }
    const e = this.generateSimpleElement(name, value);
    target.addContent(e);
    return e;
  }

  // JDOM stores a null text as "".
  protected generateSimpleElement(name: string, value: string | null): Element {
    const element = new Element(name, NS);
    element.addContent(value ?? '');
    return element;
  }
}
