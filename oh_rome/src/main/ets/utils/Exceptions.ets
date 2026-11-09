// java.lang.IllegalArgumentException and NumberFormatException: ROME's WireFeedInput.build rethrows these raw and
// wraps every other exception, so callers must be able to tell them apart.
export class IllegalArgumentException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'IllegalArgumentException';
  }
}

export class NumberFormatException extends IllegalArgumentException {
  constructor(message: string) {
    super(message);
    this.name = 'NumberFormatException';
  }
}
