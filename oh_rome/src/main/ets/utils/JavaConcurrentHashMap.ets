// Replicates the iteration order of JDK 17 new ConcurrentHashMap<String, V>() used from one thread: table growth, bin
// order and the node order a resize leaves. ROME's cc License registry picks the first matching key in this order.
// Follows the structure of the JSR-166 ConcurrentHashMap by Doug Lea, released to the public domain
// (http://creativecommons.org/publicdomain/zero/1.0/), from which the JDK's copy derives.

const DEFAULT_CAPACITY: number = 16;
const TREEIFY_THRESHOLD: number = 8;
const MIN_TREEIFY_CAPACITY: number = 64;

function stringHash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h;
}

function spread(h: number): number {
  return (h ^ (h >>> 16)) & 0x7fffffff;
}

function tableSizeFor(c: number): number {
  let n = 1;
  while (n < c) {
    n *= 2;
  }
  return n;
}

class MapNode<V> {
  readonly hash: number;
  readonly key: string;
  value: V;
  next: MapNode<V> | null;

  constructor(hash: number, key: string, value: V, next: MapNode<V> | null) {
    this.hash = hash;
    this.key = key;
    this.value = value;
    this.next = next;
  }
}

export class JavaConcurrentHashMap<V> {
  private table: (MapNode<V> | null)[] = [];
  private sizeCtl: number = 0;
  private count: number = 0;
  // get reads a Map kept beside the table: hashing the key in ArkTS made each License.findByValue cost ~6.7 us.
  private readonly values: Map<string, V> = new Map<string, V>();

  get(key: string): V | undefined {
    return this.values.get(key);
  }

  put(key: string, value: V): void {
    this.values.set(key, value);
    const hash = spread(stringHash(key));
    if (this.table.length === 0) {
      this.initTable();
    }
    const n = this.table.length;
    const i = hash & (n - 1);
    let binCount = 0;
    let e = this.table[i];
    if (e === null) {
      this.table[i] = new MapNode<V>(hash, key, value, null);
    } else {
      binCount = 1;
      let replaced = false;
      while (true) {
        if (e.hash === hash && e.key === key) {
          e.value = value;
          replaced = true;
          break;
        }
        if (e.next === null) {
          e.next = new MapNode<V>(hash, key, value, null);
          break;
        }
        e = e.next;
        binCount++;
      }
      // Known limit: bins are not treeified in tables of 64+, whose TreeBin prepends new keys; needs 9 keys in one bin.
      if (binCount >= TREEIFY_THRESHOLD && n < MIN_TREEIFY_CAPACITY) {
        this.tryPresize(n * 2);
      }
      if (replaced) {
        return;
      }
    }
    this.count++;
    while (this.count >= this.sizeCtl) {
      this.transfer();
    }
  }

  // Iteration order: bin by bin, each bin in list order.
  keys(): string[] {
    const keys: string[] = [];
    for (const head of this.table) {
      for (let e = head; e !== null; e = e.next) {
        keys.push(e.key);
      }
    }
    return keys;
  }

  // Keeps the table size, like ConcurrentHashMap.clear.
  clear(): void {
    this.table = this.table.map((): MapNode<V> | null => null);
    this.count = 0;
    this.values.clear();
  }

  private initTable(): void {
    const n = this.sizeCtl > 0 ? this.sizeCtl : DEFAULT_CAPACITY;
    this.table = new Array<MapNode<V> | null>(n).fill(null);
    this.sizeCtl = n - (n >>> 2);
  }

  private tryPresize(size: number): void {
    const c = tableSizeFor(size + (size >>> 1) + 1);
    while (c > this.sizeCtl) {
      this.transfer();
    }
  }

  private transfer(): void {
    const n = this.table.length;
    const next = new Array<MapNode<V> | null>(n * 2).fill(null);
    for (let i = n - 1; i >= 0; i--) {
      const f = this.table[i];
      if (f === null) {
        continue;
      }
      let runBit = f.hash & n;
      let lastRun: MapNode<V> = f;
      for (let p = f.next; p !== null; p = p.next) {
        const b = p.hash & n;
        if (b !== runBit) {
          runBit = b;
          lastRun = p;
        }
      }
      let ln: MapNode<V> | null = runBit === 0 ? lastRun : null;
      let hn: MapNode<V> | null = runBit === 0 ? null : lastRun;
      for (let p: MapNode<V> = f; p !== lastRun; p = p.next!) {
        if ((p.hash & n) === 0) {
          ln = new MapNode<V>(p.hash, p.key, p.value, ln);
        } else {
          hn = new MapNode<V>(p.hash, p.key, p.value, hn);
        }
      }
      next[i] = ln;
      next[i + n] = hn;
    }
    this.table = next;
    this.sizeCtl = n * 2 - (n >>> 1);
  }
}
