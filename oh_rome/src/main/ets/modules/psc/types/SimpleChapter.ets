// Ported from ROME rome-modules/src/main/java/com/rometools/modules/psc/types/SimpleChapter.java (Apache-2.0)

export class SimpleChapter {
  start: string | null = null;
  title: string | null = null;
  href: string | null = null;
  image: string | null = null;

  copyFrom(item: SimpleChapter): void {
    this.start = item.start;
    this.title = item.title;
    this.href = item.href;
    this.image = item.image;
  }
}
