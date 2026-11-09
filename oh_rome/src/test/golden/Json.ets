// Golden harness: a typed JSON tree. ArkTS has no `any`, so goldens and serialized models are parsed into this.

export enum JsonKind {
  NULL,
  BOOLEAN,
  NUMBER,
  STRING,
  ARRAY,
  OBJECT
}

export class JsonNode {
  readonly kind: JsonKind;
  bool: boolean = false;
  num: number = 0;
  str: string = '';
  items: JsonNode[] = [];
  fields: Map<string, JsonNode> = new Map<string, JsonNode>();

  constructor(kind: JsonKind) {
    this.kind = kind;
  }

  static ofString(value: string): JsonNode {
    const node = new JsonNode(JsonKind.STRING);
    node.str = value;
    return node;
  }

  static parse(text: string): JsonNode {
    const parser = new JsonParser(text);
    const node = parser.value();
    parser.end();
    return node;
  }

  get(key: string): JsonNode | null {
    return this.fields.get(key) ?? null;
  }

  isNull(): boolean {
    return this.kind === JsonKind.NULL;
  }

  // Compact JSON, cut to `limit` characters for messages.
  describe(limit: number = 160): string {
    const text = this.toJson();
    return text.length <= limit ? text : `${text.substring(0, limit)}...`;
  }

  toJson(): string {
    switch (this.kind) {
      case JsonKind.NULL:
        return 'null';
      case JsonKind.BOOLEAN:
        return this.bool ? 'true' : 'false';
      case JsonKind.NUMBER:
        return String(this.num);
      case JsonKind.STRING:
        return JSON.stringify(this.str);
      case JsonKind.ARRAY:
        return `[${this.items.map((item: JsonNode) => item.toJson()).join(',')}]`;
      default:
        const parts: string[] = [];
        const keys = Array.from(this.fields.keys()).sort();
        for (const key of keys) {
          parts.push(`${JSON.stringify(key)}:${this.fields.get(key)!.toJson()}`);
        }
        return `{${parts.join(',')}}`;
    }
  }
}

class JsonParser {
  private readonly text: string;
  private pos: number = 0;

  constructor(text: string) {
    this.text = text;
  }

  value(): JsonNode {
    this.skipWhitespace();
    const c = this.text.charAt(this.pos);
    if (c === '{') {
      return this.object();
    }
    if (c === '[') {
      return this.array();
    }
    if (c === '"') {
      return JsonNode.ofString(this.string());
    }
    if (this.text.startsWith('true', this.pos)) {
      this.pos += 4;
      const node = new JsonNode(JsonKind.BOOLEAN);
      node.bool = true;
      return node;
    }
    if (this.text.startsWith('false', this.pos)) {
      this.pos += 5;
      return new JsonNode(JsonKind.BOOLEAN);
    }
    if (this.text.startsWith('null', this.pos)) {
      this.pos += 4;
      return new JsonNode(JsonKind.NULL);
    }
    return this.number();
  }

  end(): void {
    this.skipWhitespace();
    if (this.pos !== this.text.length) {
      this.fail('trailing characters');
    }
  }

  private object(): JsonNode {
    const node = new JsonNode(JsonKind.OBJECT);
    this.pos++;
    this.skipWhitespace();
    if (this.text.charAt(this.pos) === '}') {
      this.pos++;
      return node;
    }
    while (true) {
      this.skipWhitespace();
      if (this.text.charAt(this.pos) !== '"') {
        this.fail('expected a key');
      }
      const key = this.string();
      this.skipWhitespace();
      this.expect(':');
      node.fields.set(key, this.value());
      this.skipWhitespace();
      if (this.text.charAt(this.pos) === ',') {
        this.pos++;
        continue;
      }
      this.expect('}');
      return node;
    }
  }

  private array(): JsonNode {
    const node = new JsonNode(JsonKind.ARRAY);
    this.pos++;
    this.skipWhitespace();
    if (this.text.charAt(this.pos) === ']') {
      this.pos++;
      return node;
    }
    while (true) {
      node.items.push(this.value());
      this.skipWhitespace();
      if (this.text.charAt(this.pos) === ',') {
        this.pos++;
        continue;
      }
      this.expect(']');
      return node;
    }
  }

  private string(): string {
    this.pos++;
    let out = '';
    let start = this.pos;
    while (this.pos < this.text.length) {
      const c = this.text.charAt(this.pos);
      if (c === '"') {
        out += this.text.substring(start, this.pos);
        this.pos++;
        return out;
      }
      if (c === '\\') {
        out += this.text.substring(start, this.pos);
        const e = this.text.charAt(this.pos + 1);
        this.pos += 2;
        if (e === 'u') {
          out += String.fromCharCode(parseInt(this.text.substring(this.pos, this.pos + 4), 16));
          this.pos += 4;
        } else if (e === 'n') {
          out += '\n';
        } else if (e === 'r') {
          out += '\r';
        } else if (e === 't') {
          out += '\t';
        } else if (e === 'b') {
          out += '\b';
        } else if (e === 'f') {
          out += '\f';
        } else if (e === '"' || e === '\\' || e === '/') {
          out += e;
        } else {
          this.fail(`bad escape \\${e}`);
        }
        start = this.pos;
        continue;
      }
      this.pos++;
    }
    this.fail('unterminated string');
    return out;
  }

  private number(): JsonNode {
    const match = /^-?\d+(\.\d+)?([eE][+-]?\d+)?/.exec(this.text.substring(this.pos, this.pos + 64));
    if (match === null) {
      this.fail('unexpected character');
    }
    const node = new JsonNode(JsonKind.NUMBER);
    node.num = Number(match![0]);
    this.pos += match![0].length;
    return node;
  }

  private skipWhitespace(): void {
    while (this.pos < this.text.length && ' \t\r\n'.includes(this.text.charAt(this.pos))) {
      this.pos++;
    }
  }

  private expect(c: string): void {
    if (this.text.charAt(this.pos) !== c) {
      this.fail(`expected '${c}'`);
    }
    this.pos++;
  }

  private fail(message: string): void {
    throw new Error(`JSON: ${message} at ${this.pos}: ${this.text.substring(this.pos, this.pos + 40)}`);
  }
}
