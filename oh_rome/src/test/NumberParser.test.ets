import { describe, expect, it } from '@ohos/hypium';
import { NumberParser } from '../main/ets/io/impl/NumberParser';

function floatBits(value: number | null): string {
  const view = new DataView(new ArrayBuffer(4));
  view.setFloat32(0, value!);
  return view.getUint32(0).toString(16).padStart(8, '0');
}

export default function numberParserTest() {
  describe('NumberParser', () => {
    // rome/src/test/java/com/rometools/rome/io/impl/NumberParserTest.java
    it('testLongParseFailure', 0, () => {
      expect(NumberParser.parseLong('Non Long')).assertNull();
    });

    it('testLongParseSuccess', 0, () => {
      expect(NumberParser.parseLong('1')).assertEqual(1);
    });

    it('testLongParseDefaultSuccess', 0, () => {
      expect(NumberParser.parseLongWithDefault('Non Long', 1)).assertEqual(1);
    });

    it('testLongParseNonDefaultSuccess', 0, () => {
      expect(NumberParser.parseLongWithDefault('0', 1)).assertEqual(0);
    });

    it('testIntParseFailure', 0, () => {
      expect(NumberParser.parseInt('Non Int')).assertNull();
    });

    it('testIntParseSuccess', 0, () => {
      expect(NumberParser.parseInt('1')).assertEqual(1);
    });

    it('testFloatParseFailure', 0, () => {
      expect(NumberParser.parseFloat('Non Float')).assertNull();
    });

    it('testFloatParseSuccess', 0, () => {
      expect(NumberParser.parseFloat('1.0')).assertEqual(1);
    });

    it('testFloatParseDefaultSuccess', 0, () => {
      expect(NumberParser.parseFloatWithDefault('Non Float', 1)).assertEqual(1);
    });

    it('testFloatParseNonDefaultSuccess', 0, () => {
      expect(NumberParser.parseFloatWithDefault('0.0', 1)).assertEqual(0);
    });

    // Float.parseFloat on Temurin 17.0.17+10 rounds the exact decimal or hex value once, to nearest even.
    it('roundsFloatsLikeJdk17', 0, () => {
      expect(floatBits(NumberParser.parseFloat('1.00000005960464477539062501'))).assertEqual('3f800001');
      expect(floatBits(NumberParser.parseFloat('1.000000059604644775390625'))).assertEqual('3f800000');
      expect(floatBits(NumberParser.parseFloat('3.4028235677973366e38'))).assertEqual('7f7fffff');
      expect(NumberParser.parseFloat('3.4028235677973367e38')).assertEqual(Infinity);
      expect(floatBits(NumberParser.parseFloat('7.006492321624086e-46'))).assertEqual('00000001');
      expect(floatBits(NumberParser.parseFloat('7.006492321624085e-46'))).assertEqual('00000000');
      expect(floatBits(NumberParser.parseFloat('2.80529344454407691955566406251E-2'))).assertEqual('3ce5cf45');
      expect(floatBits(NumberParser.parseFloat('0x1.000001p-150'))).assertEqual('00000001');
      expect(floatBits(NumberParser.parseFloat('0x1.fffffefp127'))).assertEqual('7f7fffff');
      expect(NumberParser.parseFloat('0x1.ffffffp127')).assertEqual(Infinity);
      expect(floatBits(NumberParser.parseFloat('0x0p99999999999'))).assertEqual('00000000');
      expect(NumberParser.parseFloat('1e99999999999')).assertEqual(Infinity);
      expect(floatBits(NumberParser.parseFloat('1e00000000001'))).assertEqual('41200000');
      expect(floatBits(NumberParser.parseFloat('1e-00000000001'))).assertEqual('3dcccccd');
      expect(floatBits(NumberParser.parseFloat('1.4e-000000000045'))).assertEqual('00000001');
      expect(NumberParser.parseFloat('1e+0000000000000000000039')).assertEqual(Infinity);
    });

    // Like FloatingDecimal, long inputs are cut to a bounded number of significant digits plus a sticky digit:
    // same results as Temurin 17.0.17+10, in linear time.
    it('parsesLongFloatsQuicklyLikeJdk17', 0, () => {
      const start = Date.now();
      expect(floatBits(NumberParser.parseFloat('0.' + '1'.repeat(20000)))).assertEqual('3de38e39');
      expect(floatBits(NumberParser.parseFloat('0x1' + '0'.repeat(20000) + '1p-80000'))).assertEqual('41800000');
      expect(floatBits(NumberParser.parseFloat('0x1.000001' + '0'.repeat(20000) + '1p0'))).assertEqual('3f800001');
      expect(floatBits(NumberParser.parseFloat('0x1.000001' + '0'.repeat(20000) + 'p0'))).assertEqual('3f800000');
      expect(Date.now() - start < 2000).assertTrue();
    });

    // Long.parseLong/Integer.parseInt accept any Character.digit decimal digit; Float.parseFloat does not.
    it('acceptsUnicodeDigitsLikeJdk17', 0, () => {
      expect(NumberParser.parseLong('\u0661\u0662')).assertEqual(12);
      expect(NumberParser.parseInt('-\u0661\u0662')).assertEqual(-12);
      expect(NumberParser.parseLong('\uff11\uff12')).assertEqual(12);
      expect(NumberParser.parseInt('\u00b2')).assertNull();
      expect(NumberParser.parseFloat('\u0661')).assertNull();
    });

    // Results of Long.valueOf/Integer.valueOf/Float.valueOf on Temurin 17.0.17+10.
    it('followsJavaNumberParsing', 0, () => {
      expect(NumberParser.parseLong(' +5 ')).assertEqual(5);
      expect(NumberParser.parseInt('+5')).assertEqual(5);
      expect(1 / NumberParser.parseLong('-0')!).assertEqual(Infinity);
      expect(NumberParser.parseLong('1.5')).assertNull();
      expect(NumberParser.parseLong('0x10')).assertNull();
      expect(NumberParser.parseLong('1_0')).assertNull();
      expect(NumberParser.parseLong('')).assertNull();
      expect(NumberParser.parseLong(null)).assertNull();
      expect(NumberParser.parseLong('9223372036854775807')).assertEqual(9223372036854775807);
      expect(NumberParser.parseLong('-9223372036854775808')).assertEqual(-9223372036854775808);
      expect(NumberParser.parseLong('9223372036854775808')).assertNull();
      expect(NumberParser.parseLong('00000000000000000000001')).assertEqual(1);
      expect(NumberParser.parseInt('2147483647')).assertEqual(2147483647);
      expect(NumberParser.parseInt('-2147483648')).assertEqual(-2147483648);
      expect(NumberParser.parseInt('2147483648')).assertNull();
      expect(NumberParser.parseFloat(' 1.5f ')).assertEqual(1.5);
      expect(NumberParser.parseFloat('0x1p3')).assertEqual(8);
      expect(NumberParser.parseFloat('-0x1.8p1')).assertEqual(-3);
      expect(NumberParser.parseFloat('0x10')).assertNull();
      expect(NumberParser.parseFloat('1e40')).assertEqual(Infinity);
      expect(NumberParser.parseFloat('0.1')).assertEqual(Math.fround(0.1));
      expect(Number.isNaN(NumberParser.parseFloat('NaN'))).assertTrue();
      expect(1 / NumberParser.parseFloat('-0')!).assertEqual(-Infinity);
      expect(NumberParser.parseFloat('1_0')).assertNull();
    });
  });
}
