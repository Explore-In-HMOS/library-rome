// Ported from ROME rome-modules/src/main/java/com/rometools/modules/mediarss/types/Embed.java (Apache-2.0)

export class EmbedParam {
  name: string | null;
  value: string | null;

  constructor(name: string | null = null, value: string | null = null) {
    this.name = name;
    this.value = value;
  }
}

export class Embed {
  params: EmbedParam[] = [];
  url: string | null = null;
  width: number | null = null;
  height: number | null = null;
}
