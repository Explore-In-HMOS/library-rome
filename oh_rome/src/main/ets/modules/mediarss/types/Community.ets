// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Community.java (Apache-2.0)
import { StarRating } from './StarRating';
import { Statistics } from './Statistics';
import { Tag } from './Tag';

export class Community {
  starRating: StarRating | null = null;
  statistics: Statistics | null = null;
  // Java's TreeSet<Tag>: add through addTag, which keeps Tag.compareTo order and drops a tag comparing equal to one
  // already present.
  readonly tags: Tag[] = [];

  addTag(tag: Tag): boolean {
    for (let i = 0; i < this.tags.length; i++) {
      const c = tag.compareTo(this.tags[i]);
      if (c === 0) {
        return false;
      }
      if (c < 0) {
        this.tags.splice(i, 0, tag);
        return true;
      }
    }
    this.tags.push(tag);
    return true;
  }
}
