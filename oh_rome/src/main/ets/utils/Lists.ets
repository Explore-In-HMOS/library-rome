// Ported from ROME rome-utils/src/main/java/com/rometools/utils/Lists.java (Apache-2.0)

export class Lists {
  static firstEntry<T>(list: T[] | null): T | null {
    return list !== null && list.length > 0 ? list[0] : null;
  }

  static isEmpty<T>(list: T[] | null): boolean {
    return list === null || list.length === 0;
  }

  static isNotEmpty<T>(list: T[] | null): boolean {
    return !Lists.isEmpty(list);
  }

  static sizeIs<T>(list: T[] | null, size: number): boolean {
    if (size === 0) {
      return list === null || list.length === 0;
    }
    return list !== null && list.length === size;
  }

  static emptyToNull<T>(list: T[] | null): T[] | null {
    return Lists.isEmpty(list) ? null : list;
  }
}
