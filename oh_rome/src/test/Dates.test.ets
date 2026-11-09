import { describe, it, expect } from '@ohos/hypium';
import { Dates } from '../main/ets/utils/Dates';

export default function datesTest() {
  describe('Dates', () => {
    it('testCopy', 0, () => {
      const date = new Date();
      const copy = Dates.copy(date);
      expect(copy).not().assertNull();
      expect(copy !== date).assertTrue();
      expect(copy!.getTime()).assertEqual(date.getTime());
      expect(Dates.copy(null)).assertNull();
    });
  });
}
