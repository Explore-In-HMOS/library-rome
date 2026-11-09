// Every golden of every fixture, so a fixture no suite lists can't go unrun. It must stay first in List.test.ets:
// License.findByValue depends on every license looked up before, and tools/golden runs each profile over the fixtures
// in index order in a JVM of its own.
import { describe, expect, it } from '@ohos/hypium';
import { fixture, fixtureIds, PROFILES, runGolden } from './golden/Golden';

// Hypium keeps only the first line of a failure message and cuts it short.
const MAX_REPORTED = 12;
const MAX_DIFF_CHARS = 150;

export default function allFixturesTest() {
  describe('AllFixtures', () => {
    it('everyGoldenMatches', 0, () => {
      const failures: string[] = [];
      for (const profile of PROFILES) {
        for (const id of fixtureIds()) {
          for (const kind of fixture(id).kinds(profile)) {
            const lines = runGolden(id, profile, kind).lines;
            if (lines.length > 0) {
              failures.push(`${id} ${profile}/${kind}: ${lines[0].replace(/\n/g, ' ').substring(0, MAX_DIFF_CHARS)}`);
            }
          }
        }
      }
      expect(`${failures.length} failures. ${failures.slice(0, MAX_REPORTED).join(' ;; ')}`).assertEqual('0 failures. ');
    });
  });
}
