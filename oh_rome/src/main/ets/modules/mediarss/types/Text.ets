// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Text.java (Apache-2.0)
import { Time } from './Time';

export class Text {
  readonly type: string | null;
  readonly value: string | null;
  readonly end: Time | null;
  readonly start: Time | null;

  constructor(type: string | null, value: string | null, start: Time | null = null, end: Time | null = null) {
    this.type = type;
    this.value = value;
    this.start = start;
    this.end = end;
  }
}
