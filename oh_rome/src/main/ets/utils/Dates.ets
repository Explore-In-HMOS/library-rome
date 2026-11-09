// Ported from ROME rome-utils/src/main/java/com/rometools/utils/Dates.java (Apache-2.0)

export class Dates {
  static copy(d: Date | null): Date | null {
    return d === null ? null : new Date(d.getTime());
  }
}
