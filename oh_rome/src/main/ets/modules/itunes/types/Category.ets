// Ported from ROME rome-modules/src/main/java/com/rometools/modules/itunes/types/Category.java (Apache-2.0)
import { Subcategory } from './Subcategory';

export class Category {
  name: string | null;
  subcategories: Subcategory[] = [];

  constructor(name: string | null = null) {
    this.name = name;
  }

  get subcategory(): Subcategory | null {
    return this.subcategories.length === 0 ? null : this.subcategories[0];
  }

  set subcategory(subcategory: Subcategory | null) {
    this.subcategories = subcategory === null ? [] : [subcategory];
  }

  addSubcategory(subcategory: Subcategory): void {
    this.subcategories.push(subcategory);
  }
}
