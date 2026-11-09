import { afterAll, afterEach, beforeAll, describe, expect, it } from '@ohos/hypium';
import { DateParser } from '../main/ets/io/impl/DateParser';

class JdkCase {
  readonly masks: string;
  readonly input: string;
  readonly expected: number | null;

  constructor(masks: string, input: string, expected: number | null) {
    this.masks = masks;
    this.input = input;
    this.expected = expected;
  }
}

// Expected values come from ROME's DateParser.parseDate on Temurin 17.0.17+10 (UTC default zone, en_US), with
// ROME's datetime.extra.masks set to the first column.
const JDK_CASES: JdkCase[] = [
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 EST', 1072933200000),
  new JdkCase('', '1E4294967296', -62135769600000),
  new JdkCase('', '09999999999999999E-16', -62167392000000),
  new JdkCase('', '12999999999999999E-15', -61788700800000),
  new JdkCase('', '1E-4294967296', -62135769600000),
  new JdkCase('', '2E2147483647', -62167392000000),
  new JdkCase('', '1E9223372036854775807', -62167392000000),
  new JdkCase('', '1E9223372036854775808', null),
  new JdkCase('', '\u0661\u0669\u0667\u0660', 0),
  new JdkCase('', 'Thu, \u0660\u0661 Jan 2004 00:00 GMT', 1072915200000),
  new JdkCase('', 'Thu, 15 Jul 2021 12:00:00 Kanton Standard Time', 1626303600000),
  new JdkCase('', 'Thu, 15 Jul 2021 12:00:00 Yukon Time', null),
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 EDT', 1072929600000),
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 -0500', 1072933200000),
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 +01:00', null),
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 GMT+1:00', 1072911600000),
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 Eastern Standard Time', 1072933200000),
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 CST', 1072936800000),
  new JdkCase('', 'Thu, 01 Jan 2014 00:00:00 IST', 1388527200000),
  new JdkCase('', 'Thu, 01 Jan 2014 00:00:00 JDT', 1388502000000),
  new JdkCase('', 'Thu, 01 Jan 2004 00:00:00 MEZ', null),
  new JdkCase('', 'Thu, 01  Jan 2004 00:00:00 GMT', null),
  new JdkCase('', 'Thu, 01 Jan  2004 00:00:00 GMT', 1072915200000),
  new JdkCase('', 'thu, 01 JAN 2004 00:00:00 gmt', 1072915200000),
  new JdkCase('', 'Foo, 01 Jan 2004 00:00:00 GMT', null),
  new JdkCase('', 'Thu, 01 Sept 2004 00:00:00 GMT', null),
  new JdkCase('', 'Thursday, 01 January 2004 00:00:00 GMT', 1072915200000),
  new JdkCase('', '01 Jan 2004 00:00 PST', 1072944000000),
  new JdkCase('', 'Wed, 01 Jan 2E1 00:00:00 GMT', -61536240000000),
  new JdkCase('', 'Wed, 01 Jan NaN 00:00:00 GMT', -62167392000000),
  new JdkCase('', 'Wed, -1 Jan 2004 -1:-1:-1 GMT', 1072738739000),
  new JdkCase('', 'Wed, 01 Jan 2004 24:00:00 GMT', 1073001600000),
  new JdkCase('', 'Wed, 01 Jan 004 00:00:00 GMT', -62041161600000),
  new JdkCase('', '2004-13-45T25:61:61Z', 1108432921000),
  new JdkCase('', '2004-02-30', 1078099200000),
  new JdkCase('', '2004-00-00', 1070150400000),
  new JdkCase('', '1582-10-10', -12218860800000),
  new JdkCase('', '1582-10-04', -12219379200000),
  new JdkCase('', '1505-04019', -4106678400000),
  new JdkCase('', '0000', -62167392000000),
  new JdkCase('', '2004-01-01T10:00:00.123Z', 1072951200123),
  new JdkCase('', '2004-01-01T10:00:00.1234Z', 1072951201234),
  new JdkCase('', '2004-01-01T10:00:00,123+01:00', 1072947600000),
  new JdkCase('', '2004-01-01T10:00:00.5-05:30', 1072971000005),
  new JdkCase('', '2004-01-01t10:00:00Z', null),
  new JdkCase('', '2004-01-01T10:00:00z', null),
  new JdkCase('', '2004-01-01T10:00+0100', null),
  new JdkCase('', '2004-01-01T10:00:00+24:00', null),
  new JdkCase('', '2004-01-01T10:00:00+5:30', 1072931400000),
  new JdkCase('', '2004-01T10:00Z', 1072951200000),
  new JdkCase('', '2004T10:00Z', 1072951200000),
  new JdkCase('', ' 2004-01-01T10:00:00Z ', 1072951200000),
  new JdkCase('', '2004-01-01T 10:00:00Z', 1072951200000),
  new JdkCase('', '2004-1-1T1:1:1Z', 1072918861000),
  new JdkCase('', '2004/01/01', null),
  new JdkCase('', 'Jan 1, 2004', null),
  new JdkCase('', '2004-01-01T10:00:00Zjunk', null),
  new JdkCase('EEE MMM yyyy', 'Wed Mar 2000', 951868800000),
  new JdkCase('D yyyy', '40 2000', 950054400000),
  new JdkCase('hh:mm a', '12:30 PM', 45000000),
  new JdkCase('hh:mm a', '12:30 am', 1800000),
  new JdkCase('kk:mm', '24:30', 1800000),
  new JdkCase('HHmm', '123', 43380000),
  new JdkCase('dd.MM.yyyy HH:mm', '31.12.2004 23:59', 1104537540000),
  new JdkCase('dd.MM.yyyy HH:mm', '31.12.2004 23:59 GMT', null),
  new JdkCase('yyyy', '-1', -62198928000000),
];

function millis(date: Date | null): number | null {
  return date === null ? null : date.getTime();
}

function utc(year: number, month: number, day: number, hour: number, minute: number, second: number): number {
  return Date.UTC(year, month - 1, day, hour, minute, second);
}


function thrown(action: () => void): string {
  try {
    action();
  } catch (e) {
    const error = e as Error;
    return error.name === 'Error' ? error.message : `${error.name}: ${error.message}`;
  }
  return 'nothing thrown';
}

export default function dateParserTest() {
  describe('DateParser', () => {
    let previousTimeZone = DateParser.getDefaultTimeZone();

    beforeAll(() => {
      previousTimeZone = DateParser.getDefaultTimeZone();
      DateParser.setDefaultTimeZone('UTC');
    });

    afterAll(() => {
      DateParser.setDefaultTimeZone(previousTimeZone);
    });

    afterEach(() => {
      DateParser.setExtraMasks([]);
    });

    // rome/src/test/java/com/rometools/rome/io/impl/DateParserTest.java
    it('parseW3CDateTimeIsOk', 0, () => {
      expect(millis(DateParser.parseW3CDateTime('1970-01-01T00:00:01+00:00'))).assertEqual(1000);
    });

    it('parseW3CDateTimeWithTrailingWhitespaceIsOk', 0, () => {
      expect(millis(DateParser.parseW3CDateTime('1970-01-01T00:00:01+00:00   '))).assertEqual(1000);
    });

    // ROME's case is "Sa, 28 Mär 20 09:12:38 MEZ" in Locale.GERMANY; locales are dropped, so the same
    // instant is written with the Locale.US names.
    it('parseRFC822DateTimeWithTimeZoneIsOk', 0, () => {
      expect(millis(DateParser.parseRFC822('Sat, 28 Mar 20 09:12:38 CET'))).assertEqual(utc(2020, 3, 28, 8, 12, 38));
    });

    // rome/src/test/java/com/rometools/rome/unittest/TestDateParser.java
    it('testW3c', 0, () => {
      expect(millis(DateParser.parseW3CDateTime('2005-07-19T17:00:42Z'))).assertEqual(utc(2005, 7, 19, 17, 0, 42));
    });

    it('testW3cNoSeconds', 0, () => {
      expect(millis(DateParser.parseW3CDateTime('2005-07-19T17:00Z'))).assertEqual(utc(2005, 7, 19, 17, 0, 0));
    });

    it('testW3cNoTime', 0, () => {
      expect(millis(DateParser.parseW3CDateTime('2005-07-19'))).assertEqual(utc(2005, 7, 19, 0, 0, 0));
    });

    it('testW3cOnlyYearAndMonth', 0, () => {
      expect(millis(DateParser.parseW3CDateTime('2005-07'))).assertEqual(utc(2005, 7, 1, 0, 0, 0));
    });

    it('testW3cOnlyYear', 0, () => {
      expect(millis(DateParser.parseW3CDateTime('2005'))).assertEqual(utc(2005, 1, 1, 0, 0, 0));
    });

    it('testRfc822FourDigitYear', 0, () => {
      expect(millis(DateParser.parseRFC822('Tue, 19 Jul 2005 17:00:42 GMT'))).assertEqual(utc(2005, 7, 19, 17, 0, 42));
    });

    it('testRfc822TwoDigitYear', 0, () => {
      expect(millis(DateParser.parseRFC822('Tue, 19 Jul 05 17:00:42 GMT'))).assertEqual(utc(2005, 7, 19, 17, 0, 42));
    });

    it('testRfc822WithUtTimeZone', 0, () => {
      expect(millis(DateParser.parseRFC822('Tue, 19 Jul 2005 17:00:42 UT'))).assertEqual(utc(2005, 7, 19, 17, 0, 42));
    });

    it('testRfc822WithUtcTimeZone', 0, () => {
      expect(millis(DateParser.parseRFC822('Tue, 19 Jul 2005 17:00:42 UTC'))).assertEqual(utc(2005, 7, 19, 17, 0, 42));
    });

    it('testRfc822WithZTimeZone', 0, () => {
      expect(millis(DateParser.parseRFC822('Tue, 19 Jul 2005 17:00:42 Z'))).assertEqual(utc(2005, 7, 19, 17, 0, 42));
    });

    // ROME's test rome.properties sets datetime.extra.masks=HH:mm yyyy/MM/dd.
    it('testExtraMaskInRomePropertiesFile', 0, () => {
      DateParser.setExtraMasks(['HH:mm yyyy/MM/dd']);
      expect(millis(DateParser.parseDate('17:00 2005/07/19'))).assertEqual(utc(2005, 7, 19, 17, 0, 0));
    });

    it('testInvalidDate', 0, () => {
      DateParser.setExtraMasks(['HH:mm yyyy/MM/dd']);
      expect(DateParser.parseDate('X00:00 2005-07-19')).assertNull();
    });

    it('matchesJdkLenientParsing', 0, () => {
      for (const c of JDK_CASES) {
        DateParser.setExtraMasks(c.masks === '' ? [] : c.masks.split('|'));
        const actual = millis(DateParser.parseDate(c.input));
        if (actual !== c.expected) {
          const label = c.masks + ' | ' + c.input + ' -> ';
          expect(label + actual).assertEqual(label + c.expected);
        }
      }
    });

    // Temurin 17.0.17+10 gives year 10000; the exact double conversion keeps only FloatingDecimal's 1100 digits.
    it('parsesLongNumbersQuickly', 0, () => {
      const start = Date.now();
      expect(millis(DateParser.parseDate('1' + '0'.repeat(20000) + '1E-19997'))).assertEqual(253402300800000);
      expect(Date.now() - start < 5000).assertTrue();
    });

    it('extraMasksAreTriedFirst', 0, () => {
      expect(millis(DateParser.parseDate('2004-02-03'))).assertEqual(utc(2004, 2, 3, 0, 0, 0));
      DateParser.setExtraMasks(['yyyy-dd-MM']);
      expect(millis(DateParser.parseDate('2004-02-03'))).assertEqual(utc(2004, 3, 2, 0, 0, 0));
    });

    it('rejectsIllegalMasks', 0, () => {
      expect(thrown(() => DateParser.setExtraMasks(['yyyy-MM-dd T'])))
        .assertEqual('IllegalArgumentException: Illegal pattern character \'T\'');
      expect(thrown(() => DateParser.setExtraMasks(['\'T'])))
        .assertEqual('IllegalArgumentException: Unterminated quote');
      expect(DateParser.getExtraMasks().length).assertEqual(0);
    });

    it('twoDigitYearsUseTheCenturyWindow', 0, () => {
      const start = new Date().getUTCFullYear() - 80;
      const after = (start + 5) % 100;
      const before = (start + 95) % 100;
      const date = (yy: number): Date | null =>
        DateParser.parseRFC822('01 Jul ' + (yy < 10 ? '0' : '') + yy + ' 00:00 GMT');
      expect(date(after)!.getUTCFullYear()).assertEqual(start + 5);
      expect(date(before)!.getUTCFullYear()).assertEqual(start + 95);
    });

    it('zoneLessMasksUseTheDefaultTimeZone', 0, () => {
      DateParser.setExtraMasks(['yyyy-MM-dd HH:mm']);
      expect(millis(DateParser.parseDate('2004-07-01 10:00'))).assertEqual(utc(2004, 7, 1, 10, 0, 0));
      DateParser.setDefaultTimeZone('local');
      try {
        expect(millis(DateParser.parseDate('2004-07-01 10:00'))).assertEqual(new Date(2004, 6, 1, 10, 0, 0).getTime());
      } finally {
        DateParser.setDefaultTimeZone('UTC');
      }
      expect(DateParser.getDefaultTimeZone()).assertEqual('UTC');
    });

    it('formatsLikeRome', 0, () => {
      expect(DateParser.formatRFC822(new Date(0))).assertEqual('Thu, 01 Jan 1970 00:00:00 GMT');
      expect(DateParser.formatW3CDateTime(new Date(0))).assertEqual('1970-01-01T00:00:00Z');
      expect(DateParser.formatRFC822(new Date(1700000000123))).assertEqual('Tue, 14 Nov 2023 22:13:20 GMT');
      expect(DateParser.formatW3CDateTime(new Date(1121792442000))).assertEqual('2005-07-19T17:00:42Z');
      expect(DateParser.formatRFC822(new Date(-12219292800001))).assertEqual('Thu, 04 Oct 1582 23:59:59 GMT');
      expect(DateParser.formatW3CDateTime(new Date(-62198928000000))).assertEqual('0002-01-01T00:00:00Z');
      expect(DateParser.formatRFC822(new Date(253402300800000))).assertEqual('Sat, 01 Jan 10000 00:00:00 GMT');
    });
  });
}
