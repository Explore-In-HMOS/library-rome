import { describe, it, expect } from '@ohos/hypium';
import { Doubles } from '../main/ets/utils/Doubles';
import { Integers } from '../main/ets/utils/Integers';
import { Longs } from '../main/ets/utils/Longs';
import { NUMBER_CASES, NumberCase } from './NumberCases';

// Expected values are Java's String.valueOf; Number() of them is the exact Java value (longs past 2^53 round
// the same way the port does). -0 and 0 differ here, NaN matches NaN.
function same(a: number, b: number): boolean {
  return a === b ? 1 / a === 1 / b : Number.isNaN(a) && Number.isNaN(b);
}

function highBits(d: number): number {
  const view = new DataView(new ArrayBuffer(8));
  view.setFloat64(0, d);
  return view.getUint16(0);
}

class Timed {
  label: string;
  input: string;

  constructor(label: string, input: string) {
    this.label = label;
    this.input = input;
  }
}

// Inputs that took seconds or hung while the parse was quadratic in the digit count.
const LONG_INPUTS: Timed[] = [
  new Timed("'1' x 1000", '1'.repeat(1000)),
  new Timed("'1' x 10000", '1'.repeat(10000)),
  new Timed("'0.' + '1' x 10000", '0.' + '1'.repeat(10000)),
  new Timed("'0x' + 'f' x 10000 + 'p-40000'", '0x' + 'f'.repeat(10000) + 'p-40000'),
  new Timed("'0x' + 'f' x 100000 + 'p-400000'", '0x' + 'f'.repeat(100000) + 'p-400000'),
  new Timed("'9' x 1100 + 'e-1400'", '9'.repeat(1100) + 'e-1400'),
  new Timed("'1' x 100000 + 'x'", '1'.repeat(100000) + 'x'),
  new Timed("'0x' + 'f' x 100000", '0x' + 'f'.repeat(100000)),
];

function matches(actual: number | null, expected: string): boolean {
  return expected === 'null' ? actual === null : actual !== null && same(actual, Number(expected));
}

export default function numberCasesTest() {
  describe('NumberCases', () => {
    it('matchesRomeOnEveryOracleCase', 0, () => {
      const failures: string[] = [];
      const check = (input: string | null, what: string, actual: number | null, expected: string) => {
        if (!matches(actual, expected)) {
          const shown = actual !== null && same(actual, -0) ? '-0' : String(actual);
          const text = input !== null && input.length > 80 ? `${input.substring(0, 60)}... (${input.length} chars)` : input;
          failures.push(`${what}(${JSON.stringify(text)}): expected ${expected}, got ${shown}`);
        }
      };
      NUMBER_CASES.forEach((c: NumberCase) => {
        check(c.input, 'Integers.parse', Integers.parse(c.input), c.integer);
        check(c.input, 'Longs.parseDecimal', Longs.parseDecimal(c.input), c.long);
        check(c.input, 'Doubles.parse', Doubles.parse(c.input), c.double);
      });
      expect(`${failures.length} failures: ${failures.join(' | ')}`).assertEqual('0 failures: ');
    });

    it('longInputsParseFast', 0, () => {
      const slow: string[] = [];
      LONG_INPUTS.forEach((t: Timed) => {
        const start = Date.now();
        Doubles.parse(t.input);
        const doubleMs = Date.now() - start;
        Longs.parseDecimal(t.input);
        Integers.parse(t.input);
        const totalMs = Date.now() - start;
        console.info(`TIMING ${t.label}: Doubles.parse ${doubleMs} ms, all three ${totalMs} ms`);
        if (totalMs >= 200) {
          slow.push(`${t.label}: ${totalMs} ms`);
        }
      });
      expect(slow.join(' | ')).assertEqual('');
    });

    it('negativeNaNIsJavaCanonicalNaN', 0, () => {
      expect(highBits(Doubles.parse('-NaN')!)).assertEqual(0x7ff8);
      expect(highBits(Doubles.parse('NaN')!)).assertEqual(0x7ff8);
    });
  });
}
