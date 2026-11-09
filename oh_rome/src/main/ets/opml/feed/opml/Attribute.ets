// Ported from ROME rome-opml/src/main/java/com/rometools/opml/feed/opml/Attribute.java (Apache-2.0)

export class Attribute {
  name: string;
  value: string;

  constructor(name: string, value: string) {
    this.name = name;
    this.value = value;
  }
}
