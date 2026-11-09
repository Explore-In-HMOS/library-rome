// Ported from ROME rome-utils/src/main/java/com/rometools/utils/Alternatives.java (Apache-2.0)

export class Alternatives {
  static firstNotNull<T>(...objects: (T | null)[]): T | null {
    for (const o of objects) {
      if (o !== null) {
        return o;
      }
    }
    return null;
  }
}
