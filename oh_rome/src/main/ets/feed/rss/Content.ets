// Ported from ROME rome/src/main/java/com/rometools/rome/feed/rss/Content.java (Apache-2.0)

export class Content {
  static readonly HTML: string = 'html';
  static readonly TEXT: string = 'text';
  type: string | null = null;
  value: string | null = null;
}
