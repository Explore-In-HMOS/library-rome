// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/MediaGroup.java (Apache-2.0)
import { MediaContent } from './MediaContent';
import { Metadata } from './Metadata';

export class MediaGroup {
  private _defaultContentIndex: number | null = null;
  metadata: Metadata | null = null;
  contents: MediaContent[];

  constructor(contents: MediaContent[], defaultContentIndex?: number | null, metadata: Metadata | null = null) {
    this.contents = contents;
    if (defaultContentIndex !== undefined) {
      this.defaultContentIndex = defaultContentIndex;
    }
    this.metadata = metadata;
  }

  get defaultContentIndex(): number | null {
    return this._defaultContentIndex;
  }

  set defaultContentIndex(defaultContentIndex: number | null) {
    if (defaultContentIndex === null && this.contents.length > 0) {
      throw new Error('Cannot invoke "java.lang.Integer.intValue()" because "defaultContentIndex" is null');
    }
    this.contents.forEach((content: MediaContent, i: number) => {
      content.defaultContent = i === defaultContentIndex;
    });
    this._defaultContentIndex = defaultContentIndex;
  }
}
