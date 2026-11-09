// Golden harness: one fixture feed and the goldens ROME produced for it (generated files construct these).
import { JsonNode } from './Json';

export class GoldenFixture {
  readonly id: string;
  readonly xml: string;
  private readonly keys: string[];
  private readonly refs: number[];
  private readonly values: string[];

  // keys[i] is "<profile>/<kind>"; its golden is values[refs[i]] (identical goldens are stored once).
  constructor(id: string, xml: string, keys: string[], refs: number[], values: string[]) {
    this.id = id;
    this.xml = xml;
    this.keys = keys;
    this.refs = refs;
    this.values = values;
  }

  has(profile: string, kind: string): boolean {
    return this.keys.includes(`${profile}/${kind}`);
  }

  kinds(profile: string): string[] {
    const prefix = `${profile}/`;
    return this.keys.filter((k: string) => k.startsWith(prefix)).map((k: string) => k.substring(prefix.length));
  }

  goldenText(profile: string, kind: string): string {
    const index = this.keys.indexOf(`${profile}/${kind}`);
    if (index < 0) {
      throw new Error(`No golden ${profile}/${kind} for ${this.id}; it has: ${this.keys.join(', ')}`);
    }
    return this.values[this.refs[index]];
  }

  golden(profile: string, kind: string): JsonNode {
    return JsonNode.parse(this.goldenText(profile, kind));
  }
}
