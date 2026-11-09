// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Category.java (Apache-2.0)

export class Category {
  static readonly SCHEME_FLICKR_TAGS: string = 'urn:flickr:tags';
  readonly label: string | null;
  readonly scheme: string | null;
  readonly value: string | null;

  constructor(scheme: string | null, label: string | null, value: string | null) {
    this.scheme = scheme;
    this.value = value;
    this.label = label;
  }
}
