// Ported from ROME rome-utils/src/main/java/com/rometools/utils/Strings.java (Apache-2.0)

export class Strings {
  static isNull(s: string | null): boolean {
    return s === null;
  }

  static isEmpty(s: string | null): boolean {
    return s === null || s.length === 0;
  }

  static isNotEmpty(s: string | null): boolean {
    return !Strings.isEmpty(s);
  }

  static isBlank(s: string | null): boolean {
    return Strings.isEmpty(s) || Strings.trim(s)!.length === 0;
  }

  // Java String.trim(): strips chars <= U+0020 only, unlike JS trim() which also strips U+00A0 etc.
  static trim(s: string | null): string | null {
    if (s === null) {
      return null;
    }
    let start = 0;
    let end = s.length;
    while (start < end && s.charCodeAt(start) <= 0x20) {
      start++;
    }
    while (end > start && s.charCodeAt(end - 1) <= 0x20) {
      end--;
    }
    return s.substring(start, end);
  }

  static trimToNull(s: string | null): string | null {
    const trimmed = Strings.trim(s);
    return trimmed === null || trimmed.length === 0 ? null : trimmed;
  }

  static trimToEmpty(s: string | null): string {
    const trimmed = Strings.trim(s);
    return trimmed === null ? '' : trimmed;
  }

  static toLowerCase(s: string | null): string | null {
    return s === null ? null : s.toLowerCase();
  }
}
