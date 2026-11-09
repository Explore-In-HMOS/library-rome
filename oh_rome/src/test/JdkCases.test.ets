import { describe, it, expect } from '@ohos/hypium';
import { BigDecimal, currencyInstance, javaDoubleString } from '../main/ets/utils/JavaMath';
import { MalformedURLException, parseUri, parseUrl } from '../main/ets/utils/JavaNet';
import { URIs } from '../main/ets/utils/URIs';
import { JDK_CASES, JdkCase } from './JdkCases';
import { DOUBLE_STRING_CASES } from './DoubleStringCases';

// Same formats as tools/jdk-oracle/JdkOracle.java.
function url(s: string): string {
  try {
    const u = parseUrl(s);
    return `${u.protocol} ${u.host} ${u.port} ${u.defaultPort} ${u.toString()}`;
  } catch (e) {
    return e instanceof MalformedURLException ? 'MalformedURLException' : 'unexpected error';
  }
}

function uri(parse: () => string): string {
  try {
    return parse();
  } catch (e) {
    return (e as Error).name;
  }
}

function bigDecimal(s: string): string {
  let d: BigDecimal;
  try {
    d = BigDecimal.parse(s);
  } catch (e) {
    return (e as Error).name;
  }
  const parts: string[] = [d.toString()];
  for (let k = 0; k <= 4; k++) {
    parts.push(String(d.multiplyByPowerOfTen(3 * k).longValue()));
  }
  return parts.join(' ');
}

// longValue() returns a number, so the expected Java longs are compared after the same conversion.
function asNumbers(expected: string): string {
  return expected === 'NumberFormatException' ? expected :
    expected.split(' ').map((part: string, i: number) => i === 0 ? part : String(Number(part))).join(' ');
}

function fromBits(hex: string): number {
  const view = new DataView(new ArrayBuffer(8));
  view.setUint32(0, parseInt(hex.substring(0, 8), 16));
  view.setUint32(4, parseInt(hex.substring(8), 16));
  return view.getFloat64(0);
}

function currency(s: string): string {
  try {
    return currencyInstance(s);
  } catch (e) {
    return `${(e as Error).name}: ${(e as Error).message}`;
  }
}

export default function jdkCasesTest() {
  describe('JdkCases', () => {
    it('matchesTheJdkOnEveryOracleCase', 0, () => {
      const failures: string[] = [];
      const check = (input: string, what: string, actual: string, expected: string) => {
        if (actual !== expected) {
          failures.push(`${what}(${JSON.stringify(input)}): expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
        }
      };
      JDK_CASES.forEach((c: JdkCase) => {
        check(c.input, 'URL', url(c.input), c.url);
        check(c.input, 'URI', uri(() => parseUri(c.input)), c.uri);
        check(c.input, 'URIs.parse', uri(() => URIs.parse(c.input)), c.urisParse);
        check(c.input, 'BigDecimal', bigDecimal(c.input), asNumbers(c.bigDecimal));
        check(c.input, 'Currency', currency(c.input), c.currency);
      });
      expect(failures.join('\n')).assertEqual('');
    });

    it('doubleToStringMatchesJdk17', 0, () => {
      const failures: string[] = [];
      DOUBLE_STRING_CASES.forEach((c: string[]) => {
        const actual = javaDoubleString(fromBits(c[0]));
        if (actual !== c[1]) {
          failures.push(`${c[0]}: expected ${c[1]}, got ${actual}`);
        }
      });
      expect(`${failures.length} mismatches ${failures.slice(0, 20).join('\n')}`).assertEqual('0 mismatches ');
    });
  });
}
