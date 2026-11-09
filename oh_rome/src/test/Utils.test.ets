import { describe, it, expect } from '@ohos/hypium';
import { Doubles } from '../main/ets/utils/Doubles';
import { Integers } from '../main/ets/utils/Integers';
import { Lists } from '../main/ets/utils/Lists';
import { Longs } from '../main/ets/utils/Longs';
import { Strings } from '../main/ets/utils/Strings';

export default function utilsTest() {
  describe('Utils', () => {
    it('stringsFollowJavaTrim', 0, () => {
      expect(Strings.trim(' \t a \n')).assertEqual('a');
      expect(Strings.trim(' a ')).assertEqual(' a ');
      expect(Strings.trimToNull('   ')).assertNull();
      expect(Strings.trimToEmpty(null)).assertEqual('');
      expect(Strings.isBlank(' ')).assertTrue();
      expect(Strings.isBlank(null)).assertTrue();
      expect(Strings.isEmpty(' ')).assertFalse();
    });

    it('integersFollowParseInt', 0, () => {
      expect(Integers.parse('42')).assertEqual(42);
      expect(Integers.parse('-7')).assertEqual(-7);
      expect(Integers.parse(' 42')).assertNull();
      expect(Integers.parse('4.2')).assertNull();
      expect(Integers.parse('12abc')).assertNull();
      expect(Integers.parse('2147483648')).assertNull();
      expect(Integers.parse(null)).assertNull();
    });

    it('doublesFollowParseDouble', 0, () => {
      expect(Doubles.parse(' 1.5 ')).assertEqual(1.5);
      expect(Doubles.parse('2f')).assertEqual(2);
      expect(Doubles.parse('.5')).assertEqual(0.5);
      expect(Doubles.parse('1e3')).assertEqual(1000);
      expect(Doubles.parse('abc')).assertNull();
      expect(Doubles.parse('')).assertNull();
      expect(Longs.parseDecimal('12.9')).assertEqual(12);
      expect(Longs.parseDecimal('-12.9')).assertEqual(-12);
    });

    it('lists', 0, () => {
      expect(Lists.firstEntry<string>(['a', 'b'])).assertEqual('a');
      expect(Lists.firstEntry<string>([])).assertNull();
      expect(Lists.emptyToNull<string>([])).assertNull();
      expect(Lists.sizeIs<string>(null, 0)).assertTrue();
    });
  });
}
