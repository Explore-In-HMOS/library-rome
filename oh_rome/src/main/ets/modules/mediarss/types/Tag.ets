// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Tag.java (Apache-2.0)

export class Tag {
  readonly name: string | null;
  weight: number | null;

  constructor(name: string | null, weight: number | null = null) {
    this.name = name;
    this.weight = weight;
  }

  compareTo(o: Tag | null): number {
    const thisWeight = this.weight === null ? 1 : this.weight;
    const otherWeight = o !== null && o.weight !== null ? o.weight : 1;
    return otherWeight < thisWeight ? -1 : otherWeight === thisWeight ? 0 : 1;
  }
}
