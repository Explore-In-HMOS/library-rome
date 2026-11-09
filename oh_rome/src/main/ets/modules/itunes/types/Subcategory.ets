// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/types/Subcategory.java (Apache-2.0)

export class Subcategory {
  name: string | null;

  constructor(name: string | null = null) {
    this.name = name;
  }
}
