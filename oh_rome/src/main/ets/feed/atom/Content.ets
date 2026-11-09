// Ported from ROME rome/src/main/java/com/rometools/rome/feed/atom/Content.java (Apache-2.0)
import { IllegalArgumentException } from '../../utils/Exceptions';
import { Strings } from '../../utils/Strings';

export class Content {
  static readonly TEXT: string = 'text';
  static readonly HTML: string = 'html';
  static readonly XHTML: string = 'xhtml';
  static readonly XML: string = 'xml';
  static readonly BASE64: string = 'base64';
  static readonly ESCAPED: string = 'escaped';
  private static readonly MODES: Set<string> = new Set<string>([Content.XML, Content.BASE64, Content.ESCAPED]);

  type: string | null = null;
  value: string | null = null;
  src: string | null = null;
  private _mode: string | null = null;

  get mode(): string | null {
    return this._mode;
  }

  // Stores the lower-cased mode before validating the original one, so an invalid mode is kept although it throws.
  set mode(mode: string | null) {
    this._mode = Strings.toLowerCase(mode);
    if (mode === null || !Content.MODES.has(mode)) {
      throw new IllegalArgumentException('Invalid mode [' + mode + ']');
    }
  }
}
