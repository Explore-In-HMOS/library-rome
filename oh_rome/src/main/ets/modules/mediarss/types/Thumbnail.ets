// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Thumbnail.java (Apache-2.0)
import { Time } from './Time';

export class Thumbnail {
  readonly height: number | null;
  readonly width: number | null;
  readonly time: Time | null;
  readonly url: string | null;

  constructor(url: string | null, width: number | null = null, height: number | null = null, time: Time | null = null) {
    this.url = url;
    this.height = height;
    this.width = width;
    this.time = time;
  }
}
