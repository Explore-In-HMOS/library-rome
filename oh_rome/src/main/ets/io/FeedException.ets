// Ported from ROME rome/src/main/java/com/rometools/rome/io/FeedException.java and ParsingFeedException.java (Apache-2.0)
import { XmlParseException } from '../xml/Dom';

export class FeedException extends Error {
  readonly rootCause: Error | null;

  constructor(message: string, rootCause?: Error) {
    super(message);
    this.name = 'FeedException';
    this.rootCause = rootCause === undefined ? null : rootCause;
  }
}

export class ParsingFeedException extends FeedException {
  constructor(message: string, rootCause?: Error) {
    super(message, rootCause);
    this.name = 'ParsingFeedException';
  }

  getLineNumber(): number {
    return this.rootCause instanceof XmlParseException ? this.rootCause.lineNumber : -1;
  }

  getColumnNumber(): number {
    return this.rootCause instanceof XmlParseException ? this.rootCause.columnNumber : -1;
  }
}
