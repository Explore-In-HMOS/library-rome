# Compares RomeOracle.java and arkts_runner.js results for one case file. Each mismatch is either one of the
# port's documented deviations (KNOWN) or OTHER; exit status 1 if there is any OTHER. A date mismatch is only
# excused when the cutoffs file (RomeOracle --zone-cutoffs, same JDK and default zone) explains it:
#   - the input contains a zone name (anywhere: masks put literals around it and names match as prefixes) and the date is before that name's cutoff, the last change of
#     the offset Java uses for it (the port uses each zone's current offset), and the results differ by <= 3 h;
#   - the date is before the end of local mean time in the default zone ("@default"), differing by < 1 h;
#   - Java's date is outside the JS Date range: the port's mask fails there, so it returns null or whatever a
#     later mask gives.
# With --other it also lists every case whose Java result differs on another JDK.
# Usage: python3 tools/dateparser-oracle/compare.py <cases> <java results> <arkts results> <cutoffs> [--other <file>]
import os
import re
import sys

JS_DATE_LIMIT = 8640000000000000


def unescape(s):
    return re.sub(r'\\u([0-9a-f]{4})', lambda m: chr(int(m.group(1), 16)), s)


def load_cutoffs(path):
    names = {}
    default = None
    for line in open(path, encoding='utf-8'):
        name, ms = line.rstrip('\n').split('\t')
        if name == '@default':
            default = int(ms)
        else:
            names.setdefault(unescape(name).lower(), int(ms))
    return names, default


def zone_cutoff(text, names):
    low = text.lower()
    best = None
    for name, cutoff in names.items():
        if name in low:
            best = cutoff if best is None else max(best, cutoff)
    return best


def classify(kind, text, j, p, names, default_cutoff):
    if kind in ('P', 'W', 'R') and re.fullmatch(r'-?\d+', j):
        ms = int(j)
        if abs(ms) > JS_DATE_LIMIT:
            return 'KNOWN date outside the JS Date range (the mask fails; a later one may match)'
        if not re.fullmatch(r'-?\d+', p):
            return 'OTHER'
        diff = abs(ms - int(p))
        cutoff = zone_cutoff(text, names)
        if cutoff is not None and ms < cutoff and diff <= 3 * 3600000:
            return 'KNOWN named zone before its last offset change'
        if default_cutoff is not None and ms < default_cutoff and diff < 3600000:
            return 'KNOWN local mean time in the default zone'
    if kind == 'LONG' and re.fullmatch(r'-?\d+', j) and re.fullmatch(r'-?\d+', p) and abs(int(j)) > 2 ** 53 and \
            abs(int(j) - int(p)) < 4096:
        return 'KNOWN long beyond 2^53 rounded to a double'
    return 'OTHER'


def main():
    args = sys.argv[1:]
    other = None
    if '--other' in args:
        i = args.index('--other')
        other = open(args[i + 1], encoding='utf-8').read().split('\n')
        del args[i:i + 2]
    cases = open(args[0], encoding='utf-8').read().split('\n')[:-1]
    java = open(args[1], encoding='utf-8').read().split('\n')
    port = open(args[2], encoding='utf-8').read().split('\n')
    names, default_cutoff = load_cutoffs(args[3])
    counts = {}
    jdk_diffs = 0
    for i, case in enumerate(cases):
        kind, _, text = case.split('\t')
        if other is not None and other[i] != java[i]:
            jdk_diffs += 1
            print('JDK-DIFF\t%s\tjdk17=%s\tother=%s' % (case, java[i], other[i]))
        if java[i] == port[i]:
            counts['match'] = counts.get('match', 0) + 1
            continue
        c = classify(kind, unescape(text), java[i], port[i], names, default_cutoff)
        counts[c] = counts.get(c, 0) + 1
        print('%s\t%s\tjava=%s\tport=%s' % (c, case, java[i], port[i]))
    summary = ', '.join('%s: %d' % kv for kv in sorted(counts.items()))
    jdk = '' if other is None else ', Java results differing between JDKs: %d' % jdk_diffs
    print('SUMMARY %s: %d cases; %s%s' % (os.path.basename(args[0]), len(cases), summary, jdk), file=sys.stderr)
    sys.exit(1 if counts.get('OTHER', 0) else 0)


main()
