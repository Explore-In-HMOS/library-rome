// Ported from ROME rome/src/main/java/com/rometools/rome/io/XmlReaderException.java (Apache-2.0)

export class XmlReaderException extends Error {
  readonly contentTypeMime: string | null;
  readonly contentTypeEncoding: string | null;
  readonly bomEncoding: string | null;
  readonly xmlGuessEncoding: string | null;
  readonly xmlEncoding: string | null;
  // The unread bytes, positioned after the BOM like ROME's stream.
  readonly inputStream: Uint8Array;

  constructor(message: string, contentTypeMime: string | null, contentTypeEncoding: string | null,
    bomEncoding: string | null, xmlGuessEncoding: string | null, xmlEncoding: string | null, inputStream: Uint8Array) {
    super(message);
    this.name = 'XmlReaderException';
    this.contentTypeMime = contentTypeMime;
    this.contentTypeEncoding = contentTypeEncoding;
    this.bomEncoding = bomEncoding;
    this.xmlGuessEncoding = xmlGuessEncoding;
    this.xmlEncoding = xmlEncoding;
    this.inputStream = inputStream;
  }
}
