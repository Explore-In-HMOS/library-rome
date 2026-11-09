import { ParsingFeedException } from 'oh_rome';

// What went wrong, sorted so a by-hand test can tell a library bug from a network or feed problem.
export enum ErrorKind {
  NETWORK = 'Network',
  HTTP = 'HTTP',
  PARSE = 'Parse',
  CONVERT = 'Convert'
}

export class ErrorInfo {
  readonly kind: ErrorKind;
  readonly name: string;
  readonly message: string;

  constructor(kind: ErrorKind, name: string, message: string) {
    this.kind = kind;
    this.name = name;
    this.message = message;
  }

  get title(): string {
    return `${this.kind} error: ${this.name}`;
  }
}

export function describeError(kind: ErrorKind, e: Object): ErrorInfo {
  if (!(e instanceof Error)) {
    return new ErrorInfo(kind, 'Error', String(e));
  }
  const error = e as Error;
  let message = error.message;
  if (error instanceof ParsingFeedException) {
    const line = (error as ParsingFeedException).getLineNumber();
    if (line >= 0) {
      message += ` (line ${line}, column ${(error as ParsingFeedException).getColumnNumber()})`;
    }
  }
  return new ErrorInfo(kind, error.name, message);
}
