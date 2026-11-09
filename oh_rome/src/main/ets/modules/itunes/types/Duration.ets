// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/types/Duration.java (Apache-2.0)
import { NumberParser } from '../../../io/impl/NumberParser';

const SECOND: number = 1000;
const MINUTE: number = SECOND * 60;
const HOUR: number = MINUTE * 60;

// Java's (long) cast of a float or double.
function toLong(value: number): number {
  if (Number.isNaN(value)) {
    return 0;
  }
  return Math.trunc(Math.min(Math.max(value, -9223372036854775808), 9223372036854775807));
}

// Java's (long) (seconds * SECOND) with a float seconds.
function secondsToMillis(seconds: number): number {
  return toLong(Math.fround(seconds * SECOND));
}

// NumberFormat.getNumberInstance(Locale.US) with 2 minimum integer digits, no fraction digits and no grouping.
function format(value: number): string {
  return (value < 0 ? '-' : '') + String(Math.abs(value)).padStart(2, '0');
}

export class Duration {
  static readonly SECOND: number = SECOND;
  static readonly MINUTE: number = MINUTE;
  static readonly HOUR: number = HOUR;

  milliseconds: number;

  constructor(milliseconds: number = 0) {
    this.milliseconds = milliseconds;
  }

  // new Duration(int hours, int minutes, float seconds).
  static of(hours: number, minutes: number, seconds: number): Duration {
    return new Duration(hours * HOUR + minutes * MINUTE + secondsToMillis(Math.fround(seconds)));
  }

  // new Duration(String): "seconds", "minutes:seconds" or "hours:minutes:seconds"; unparsable numbers count as 0.
  static parse(duration: string): Duration {
    const tokens = duration.split(':').filter((token: string) => token.length > 0);
    switch (tokens.length) {
      case 1:
        return new Duration(secondsToMillis(NumberParser.parseFloatWithDefault(tokens[0], 0)));
      case 2:
        return new Duration(NumberParser.parseLongWithDefault(tokens[0], 0) * MINUTE +
          secondsToMillis(NumberParser.parseFloatWithDefault(tokens[1], 0)));
      case 3:
        return new Duration(NumberParser.parseLongWithDefault(tokens[0], 0) * HOUR +
          NumberParser.parseLongWithDefault(tokens[1], 0) * MINUTE +
          secondsToMillis(NumberParser.parseFloatWithDefault(tokens[2], 0)));
      default:
        throw new Error('Illegal time value: ' + duration);
    }
  }

  toString(): string {
    let time = BigInt(this.milliseconds);
    const hours = Number(time / BigInt(HOUR)) | 0;
    time = time - BigInt(hours) * BigInt(HOUR);
    const minutes = Number(time / BigInt(MINUTE)) | 0;
    time = time - BigInt(minutes) * BigInt(MINUTE);
    const seconds = Math.fround(Math.fround(Number(time)) / SECOND);
    const rounded = Math.min(Math.max(Math.round(seconds), -2147483648), 2147483647);
    return format(hours) + ':' + format(minutes) + ':' + format(rounded);
  }
}
