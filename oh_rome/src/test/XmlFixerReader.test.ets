import { describe, it, expect } from '@ohos/hypium';
import { fixXml, processHtmlEntities } from '../main/ets/io/impl/XmlFixerReader';
import { HTML_ENTITIES_CASES, XML_FIXER_CASES, XmlFixerCase } from './XmlFixerCases';

function mismatches(cases: XmlFixerCase[], run: (input: string) => string): string {
  const failures: string[] = [];
  cases.forEach((c: XmlFixerCase) => {
    const actual = run(c.input);
    if (actual !== c.expected) {
      failures.push(`${c.name}\n  expected: ${JSON.stringify(c.expected)}\n  actual:   ${JSON.stringify(actual)}`);
    }
  });
  return failures.join('\n');
}

export default function xmlFixerReaderTest() {
  describe('XmlFixerReader', () => {
    // TestXmlFixerReader.testAmpHandling and Issue1Test.testAmpHandling
    it('ampHandling', 0, () => {
      expect(fixXml('&amp; &aa &')).assertEqual('&amp; &amp;aa &amp;');
    });

    it('matchesRomeOnEveryOracleCase', 0, () => {
      expect(mismatches(XML_FIXER_CASES, fixXml)).assertEqual('');
    });

    it('processHtmlEntitiesMatchesRome', 0, () => {
      expect(mismatches(HTML_ENTITIES_CASES, processHtmlEntities)).assertEqual('');
    });
  });
}
