// Ported from ROME rome-modules/src/main/java/com/rometools/modules/opensearch/RequiredAttributeMissingException.java (Apache-2.0)

export class RequiredAttributeMissingException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'RequiredAttributeMissingException';
  }
}
