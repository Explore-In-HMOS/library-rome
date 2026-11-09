// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Credit.java (Apache-2.0)

export class Credit {
  static readonly SCHEME_EBU: string = 'urn:ebu';
  readonly name: string;
  readonly role: string | null;
  readonly scheme: string;

  constructor(scheme: string | null, role: string | null, name: string | null) {
    if (name === null) {
      throw new Error('A credit name cannot be null.');
    }
    this.scheme = scheme === null ? Credit.SCHEME_EBU : scheme;
    this.role = role === null ? null : role.toLowerCase();
    this.name = name;
  }
}
