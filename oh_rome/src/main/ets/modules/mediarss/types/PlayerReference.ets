// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/PlayerReference.java (Apache-2.0)
import { Reference } from './Reference';

export class PlayerReference implements Reference {
  readonly height: number | null;
  readonly width: number | null;
  readonly url: string;

  constructor(url: string | null, width: number | null = null, height: number | null = null) {
    if (url === null) {
      throw new Error('url cannot be null.');
    }
    this.url = url;
    this.height = height;
    this.width = width;
  }
}
