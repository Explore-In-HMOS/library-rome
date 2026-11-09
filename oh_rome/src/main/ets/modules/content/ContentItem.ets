// Ported from ROME rome-modules/src/main/java/com/rometools/modules/content/ContentItem.java (Apache-2.0)
import { Content, Namespace } from '../../xml/Dom';

const XHTML_DECLARATION: RegExp = / xmlns="http:\/\/www\.w3\.org\/1999\/xhtml"/g;

function sameList<T>(a: T[] | null, b: T[] | null, equal: (x: T, y: T) => boolean): boolean {
  return a === b || (a !== null && b !== null && a.length === b.length && a.every((x: T, i: number) => equal(x, b[i])));
}

export class ContentItem {
  contentFormat: string | null = null;
  contentEncoding: string | null = null;
  contentValue: string | null = null;
  contentValueDOM: Content[] | null = null;
  contentAbout: string | null = null;
  contentValueParseType: string | null = null;
  contentValueNamespaces: Namespace[] | null = null;
  contentResource: string | null = null;

  // Like Java, throws when either contentValue is null.
  equals(obj: Object | null): boolean {
    if (!(obj instanceof ContentItem)) {
      return false;
    }
    const other = obj as ContentItem;
    if (this.contentFormat !== other.contentFormat || this.contentEncoding !== other.contentEncoding) {
      return false;
    }
    const thisCV = this.contentValue!.replace(XHTML_DECLARATION, '').trim();
    const thatCV = other.contentValue!.replace(XHTML_DECLARATION, '').trim();
    if (thisCV !== thatCV) {
      return false;
    }
    if (!sameList(this.contentValueDOM, other.contentValueDOM, (x: Content, y: Content) => x === y)) {
      return false;
    }
    if (this.contentAbout !== other.contentAbout || this.contentValueParseType !== other.contentValueParseType) {
      return false;
    }
    if (!sameList(this.contentValueNamespaces, other.contentValueNamespaces,
      (x: Namespace, y: Namespace) => x.equals(y))) {
      return false;
    }
    return this.contentResource === other.contentResource;
  }

  clone(): ContentItem {
    const o = new ContentItem();
    o.contentAbout = this.contentAbout;
    o.contentEncoding = this.contentEncoding;
    o.contentFormat = this.contentFormat;
    o.contentResource = this.contentResource;
    o.contentValue = this.contentValue;
    o.contentValueDOM = this.contentValueDOM;
    o.contentValueNamespaces = this.contentValueNamespaces;
    o.contentValueParseType = this.contentValueParseType;
    return o;
  }
}
