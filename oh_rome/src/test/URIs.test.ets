import { describe, it, expect } from '@ohos/hypium';
import { URIs } from '../main/ets/utils/URIs';

export default function urisTest() {
  describe('URIs', () => {
    it('testParse', 0, () => {
      expect(URIs.parse('https://example.com/test 123.png')).assertEqual('https://example.com/test%20123.png');
    });
  });
}
