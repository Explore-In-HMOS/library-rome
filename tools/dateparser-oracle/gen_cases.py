# Writes the deterministic case files RomeOracle.java and arkts_runner.js run, one "KIND\tARG\tINPUT" per line
# (\, tab, CR, LF and non-ASCII chars escaped as \uXXXX). Corpora: dates (seeds 1-6, 31k inputs),
# zones (every name in DateParserZoneNames.ets at 2021 dates), base64, numbers.
# Usage (from the repo root): python3 tools/dateparser-oracle/gen_cases.py <out dir>
import os
import random
import re
import struct
import sys
from decimal import Decimal, getcontext
from fractions import Fraction

getcontext().prec = 1300
HERE = os.path.dirname(os.path.abspath(__file__))
ZONE_FILE = os.path.join(HERE, '../../oh_rome/src/main/ets/io/impl/DateParserZoneNames.ets')


def esc(s):
    b = s.encode('utf-16-le', 'surrogatepass')
    units = [b[i] | b[i + 1] << 8 for i in range(0, len(b), 2)]
    return ''.join(chr(u) if 0x20 <= u <= 0x7e and u != 0x5c else '\\u%04x' % u for u in units)


def write(path, cases):
    with open(path, 'w', encoding='utf-8') as f:
        for kind, arg, text in cases:
            f.write('%s\t%s\t%s\n' % (kind, esc(arg), esc(text)))


# ---- dates ----

HAND = ('2005-07-19T17:00:42Z|2005-07-19T17:00Z|2005-07-19|2005-07|2005|Tue, 19 Jul 2005 17:00:42 GMT|'
        'Tue, 19 Jul 05 17:00:42 GMT|Tue, 19 Jul 2005 17:00:42 UT|Tue, 19 Jul 2005 17:00:42 Z|17:00 2005/07/19|'
        '1970-01-01T00:00:01+00:00   |Sat, 28 Mar 20 09:12:38 CET|2004-01-01T10:00:00,123+01:00|'
        '2004-13-45T25:61:61Z|1582-10-10|1505-04019|Thu, 01  Jan 2004 00:00:00 GMT|Wed, 01 Jan 2E1 00:00:00 GMT|'
        'Wed, 01 Jan NaN 00:00:00 GMT|1E4294967296|1E-4294967296|2E2147483647|1E9223372036854775807|'
        '1E9223372036854775808|1E-9223372036854775808|١٩٧٠|Thu, ٠١ Jan 2004 00:00 GMT|'
        '2004-01-01T10:00:00+24:00|2004-01-01T10:00:00+5:30|20040101|T|Z|09999999999999999E-16|'
        '12999999999999999E-15|0.5|1E2147483647').split('|')
DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Monday', 'Thursday', 'Thurs', 'Tues', 'mon', 'X']
MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Sept', 'Oct', 'Nov', 'Dec', 'January',
          'June', 'july', 'MAY', 'Foo']
ZONES = ['GMT', 'UT', 'UTC', 'Z', 'EST', 'EDT', 'CST', 'CDT', 'MST', 'MDT', 'PST', 'PDT', 'CET', 'CEST', 'BST',
         'IST', 'JST', 'AEST', 'AEDT', 'NZDT', 'HKT', 'SGT', 'MSK', 'WET', 'EET', '+0000', '-0500', '+0530',
         '+05:30', '-08', 'GMT+8', 'GMT-05:00', 'GMT+5:30', 'A', 'M', 'Y', 'z', 'gmt', 'Pacific Standard Time',
         'Central European Summer Time', 'Etc/GMT', '']
MASK_TOKENS = ['yyyy', 'yy', 'y', 'MM', 'M', 'MMM', 'MMMM', 'dd', 'd', 'HH', 'H', 'hh', 'h', 'kk', 'KK', 'mm', 'ss',
               'SSS', 'S', 'EEE', 'EEEE', 'a', 'z', 'Z', 'D', 'DDD']
MASK_SEPS = ['-', '/', ' ', ':', '.', ',', "'T'", '', "'at' "]


def dates(seed):
    rnd = random.Random(seed)

    def num(lo, hi, w=0):
        s = str(rnd.randint(lo, hi))
        return s.zfill(w) if w and rnd.random() < 0.7 else s

    def rfc():
        parts = []
        if rnd.random() < 0.7:
            parts.append(rnd.choice(DAYS) + rnd.choice([',', ',', ' ,', '']))
        parts += [num(-2, 40, 2), rnd.choice(MONTHS), rnd.choice([num(0, 99, 2), num(1900, 2100), num(0, 3000)])]
        t = num(0, 25, 2) + ':' + num(0, 61, 2)
        if rnd.random() < 0.7:
            t += ':' + num(0, 61, 2)
        return ' '.join(parts + [t, rnd.choice(ZONES)])

    def w3c():
        s = num(0, 2200, 4)
        if rnd.random() < 0.8:
            s += '-' + num(0, 14, 2)
        if rnd.random() < 0.7:
            s += '-' + num(0, 33, 2)
        if rnd.random() < 0.7:
            s += rnd.choice(['T', 'T', 't', ' ', 'T ']) + num(0, 25, 2) + ':' + num(0, 61, 2)
            if rnd.random() < 0.6:
                s += ':' + num(0, 61, 2)
            if rnd.random() < 0.4:
                s += rnd.choice(['.', ',']) + num(0, 99999)
            s += rnd.choice(['Z', 'z', '+00:00', '-05:00', '+0530', '+05', '-0800', 'GMT', 'GMT+01:00', '', ' Z',
                             '+5:30', '+23:59', '+24:00'])
        return s

    def mutate(s):
        if not s or rnd.random() < 0.6:
            return s
        i = rnd.randrange(len(s) + 1)
        ch = rnd.choice(' \t-+:,.TZ0123456789aEN١')
        op = rnd.random()
        if op < 0.4:
            return s[:i] + ch + s[i:]
        if op < 0.7:
            return s[:i] + s[i + 1:]
        return s[:i] + ch + s[i + 1:]

    def field(tok):
        c, n = tok[0], len(tok)
        if c == 'y':
            return rnd.choice([num(0, 99, 2), num(1500, 2100), num(0, 9), '-5'])
        if c == 'M':
            return rnd.choice(MONTHS) if n >= 3 else num(0, 13, n)
        if c in 'dHhkKms':
            return num(0, 32 if c == 'd' else 61, n)
        if c == 'S':
            return num(0, 2000, n)
        if c == 'E':
            return rnd.choice(DAYS)
        if c == 'a':
            return rnd.choice(['AM', 'PM', 'am', 'pm', 'XM'])
        if c in 'zZ':
            return rnd.choice(ZONES[:-1])
        return num(0, 400, n)

    cases = [(k, '', h) for h in HAND for k in 'PWR'] if seed == 1 else []
    for _ in range(3300):
        cases.append((rnd.choice('PPWR'), '', mutate(rnd.choice([rfc, w3c])())))
    for _ in range(1500):
        toks = [rnd.choice(MASK_TOKENS) for _ in range(rnd.randint(1, 5))]
        mask = text = ''
        for i, t in enumerate(toks):
            sep = rnd.choice(MASK_SEPS) if i > 0 else ''
            mask += sep + t
            text += sep.replace("'", '') + field(t)
        cases.append(('P', mask, mutate(text)))
    if seed == 1:
        cases.append(('P', 'yyyyMMdd', '1E2147483647'))
        for n in (1000, 3000):
            cases += [('P', '', '0' + '9' * n + 'E-' + str(n)), ('P', '', '1' + '0' * n + '1E-' + str(n)),
                      ('P', 'yyyy', '2' + '0' * n + '1E-' + str(n - 3))]
        for _ in range(600):
            digits = rnd.choice(['0', '']) + str(rnd.randint(1, 99)) + rnd.choice('09') * rnd.randint(10, 22) + \
                str(rnd.randint(0, 9))
            cases.append(('P', rnd.choice(['', 'yyyy']), digits + 'E' + rnd.choice(['-', '']) + str(rnd.randint(0, 25))))
    for _ in range(400):
        ms = rnd.choice([rnd.randint(-8640000000000000, 8640000000000000), rnd.randint(-70000000000000, 4000000000000),
                         rnd.randint(-13000000000000, -12000000000000)])
        cases.append(('F', '', str(ms)))
    for ms in [0, -1, -12219292800000, -12219292800001, -62135596800000, -62198928000000, 253402300800000]:
        cases.append(('F', '', str(ms)))
    return cases


def zones():
    names = re.findall(r"(?:'|;)((?:[^,;'\\]|\\.)+),-?\d+,(?:\*|-?\d+)", open(ZONE_FILE, encoding='utf-8').read())
    cases = []
    for n in names:
        n = n.replace("\\'", "'")
        for d in ['Fri, 15 Jan 2021 12:00:00 ', 'Thu, 15 Jul 2021 12:00:00 ', '15 Jan 2021 12:00 ']:
            cases.append(('P', '', d + n))
        cases.append(('P', 'HH:mm z yyyy-MM-dd', '12:00 ' + n + ' 2021-07-15'))
    return cases


# ---- base64 ----

def utf8_fragment(rnd):
    lead = rnd.choice([rnd.randint(0x00, 0x7f), rnd.randint(0x80, 0xbf), 0xc0, 0xc1, rnd.randint(0xc2, 0xdf),
                       0xe0, rnd.randint(0xe1, 0xec), 0xed, 0xee, 0xef, 0xf0, rnd.randint(0xf1, 0xf3), 0xf4,
                       rnd.randint(0xf5, 0xff)])
    tail = [rnd.choice([rnd.randint(0x80, 0xbf), 0x80, 0x8f, 0x90, 0x9f, 0xa0, 0xbf, rnd.randint(0, 0xff)])
            for _ in range(rnd.randint(0, 3))]
    return bytes([lead] + tail)


def base64_cases(seed=7):
    import base64 as b64
    rnd = random.Random(seed)
    cases = []
    for _ in range(4000):
        data = b''.join(utf8_fragment(rnd) for _ in range(rnd.randint(0, 5)))
        s = b64.b64encode(data).decode('ascii')
        r = rnd.random()
        if r < 0.15 and s:
            i = rnd.randrange(len(s) + 1)
            s = s[:i] + rnd.choice(['\n', '\r\n', ' ', '=', '!', '-', '_', 'é', '\t']) + s[i:]
        elif r < 0.3 and s:
            s = s[:rnd.randrange(len(s))]
        cases.append(('B64D', '', s))
    alphabet = 'ABCabc019+/=\n\r !é'
    for _ in range(1500):
        cases.append(('B64D', '', ''.join(rnd.choice(alphabet) for _ in range(rnd.randint(0, 14)))))
    pieces = ['a', 'Z', '&', ' ', 'é', '€', '\U0001f600', '\ud800', '\udc00', '\x00', '\x7f']
    for _ in range(500):
        cases.append(('B64E', '', ''.join(rnd.choice(pieces) for _ in range(rnd.randint(0, 6)))))
    return cases


# ---- numbers ----

def f32(bits):
    return Fraction(struct.unpack('>f', struct.pack('>I', bits))[0])


def dec(fr, sig=None):
    d = Decimal(fr.numerator) / Decimal(fr.denominator)
    return format(d, 'E') if sig is None else format(d.quantize(Decimal(1).scaleb(d.adjusted() - sig + 1)), 'E')


def number_cases(seed=11):
    rnd = random.Random(seed)
    cases = []
    floats = ['1.00000005960464477539062501', '3.4028235677973366e38', '3.4028235677973367e38',
              '3.4028234663852886e38', '1.4e-45', '7.006492321624085e-46', '7.006492321624086e-46', '0.7e-45',
              '1.401298464324817e-45', '1.1754942e-38', '1.17549435e-38', '1e39', '1e40', '1e-46', '1e-47',
              '.', '1.', '.5', '+.5', '-.5f', ' 1.5f ', '1e', '1e+', '1e+5', '1E-5D', 'NaN', '-NaN', 'NaNf',
              'Infinity', '-Infinity', '+Infinity', 'infinity', '0x1p3', '0x1.8p1', '0x.8p1', '0X1P-149', '0x1p-150',
              '0x1.000001p-150', '0x1.fffffep127', '0x1.ffffffp127', '0x1.fffffefp127', '0x1p128', '0x1p',
              '0x1p2147483647', '0x1p-2147483648', '0x1p99999999999', '0x0p99999999999', '0x0.0p0', '-0x0p0',
              '0x1_0p1', '1e99999999999', '1e-99999999999', '0e99999999999', '-0', '-0.0', '00000.000001',
              '١', '1١', '1 2', '1,5', '1d', '1F', '1.5ff', '0x10', '1_0', '1e00000000001',
              '1e-00000000001', '1.4e-000000000045', '1e+0000000000000000000038', '1e0000000000000000000039',
              '1e-0000000000000000000046', '1e2147483647', '1e-2147483648', '1e2147483648', '0x1p0000000000001',
              '0x1p-0000000000149']
    for _ in range(300):
        floats.append('%d.%de%s%s%d' % (rnd.randint(0, 99), rnd.randint(0, 999), rnd.choice(['', '+', '-']),
                                         '0' * rnd.randint(0, 14), rnd.randint(0, 50)))
    floats += ['1' * n for n in (8, 10, 16, 40, 210)] + ['0.' + '3' * 250, '9' * 39, '9' * 40]
    for _ in range(1500):
        bits = rnd.choice([rnd.randint(1, 0x7f7fffff), rnd.randint(1, 0x007fffff), rnd.randint(0x7f000000, 0x7f7ffffe)])
        lo, hi = f32(bits), f32(bits + 1)
        mid = (lo + hi) / 2
        exact = dec(mid)
        floats.append(exact)
        mant, exp = exact.split('E')
        floats.append(mant + '1E' + exp)
        floats.append(dec(mid, rnd.randint(6, 12)))
        floats.append(dec(lo, rnd.randint(1, 9)))
    for _ in range(600):
        floats.append('%se%d' % (rnd.choice(['1', '9.99', '3.4028236', '1.17549', '2.5']), rnd.randint(-50, 40)))
        floats.append(rnd.choice(['', '-', '+']) + '0x' + ''.join(rnd.choice('0123456789abcdef')
                                                                    for _ in range(rnd.randint(1, 9))) +
                      rnd.choice(['', '.', '.8']) + 'p' + str(rnd.randint(-160, 140)))
    # Long inputs: FloatingDecimal keeps 200 significant digits for floats plus a sticky digit.
    for _ in range(150):
        bits = rnd.randint(1, 0x7f7ffffe)
        mant, exp = dec((f32(bits) + f32(bits + 1)) / 2).split('E')
        tail = rnd.choice(['0' * rnd.randint(200, 3000) + '1', '0' * rnd.randint(200, 3000), '9' * rnd.randint(1, 3000)])
        floats.append(mant + tail + 'E' + exp)
    for n in (1000, 3000, 10000):
        floats += ['0.' + '1' * n, '1' * n + 'e-' + str(n), '0.' + '0' * n + '1', '1' + '0' * n + 'e-' + str(n),
                   '0x' + 'f' * n + 'p-' + str(4 * n), '0x0.' + 'f' * n + 'p0', '0x' + '0' * n + '1p0',
                   '0x1' + '0' * n + 'p-' + str(4 * n), '0x1' + '0' * n + '1p-' + str(4 * n),
                   '0x1.000001' + '0' * n + '1p0', '0x1.000001' + '0' * n + 'p0']
    cases += [('FLOAT', '', f) for f in floats]
    ints = ['1', '-0', '+5', ' 7 ', '', '-', '+', '9223372036854775807', '9223372036854775808', '-9223372036854775808',
            '-9223372036854775809', '2147483647', '2147483648', '-2147483648', '-2147483649', '00000000000000000000001',
            '١٢', '-١٢', '１２', '१', '1.0', '1e3', '0x10', '1_000', '²',
            '\U0001d7ce', '١' * 25]
    digitsets = ['0123456789', '٠١٢٣٤٥٦٧٨٩', '０５９']
    for _ in range(800):
        ds = rnd.choice(digitsets)
        ints.append(rnd.choice(['', '-', '+']) + ''.join(rnd.choice(ds) for _ in range(rnd.randint(1, 21))))
    for i in ints:
        cases += [('LONG', '', i), ('INT', '', i)]
    return cases


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    for seed in range(1, 7):
        write(os.path.join(out, 'dates-%d.txt' % seed), dates(seed))
    write(os.path.join(out, 'zones.txt'), zones())
    write(os.path.join(out, 'base64.txt'), base64_cases())
    write(os.path.join(out, 'numbers.txt'), number_cases())


main()
