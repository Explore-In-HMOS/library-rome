#!/bin/sh
# Differential test of the ArkTS DateParser, Base64 and NumberParser against ROME's own classes on Temurin
# 17.0.17+10: generates the corpora, runs RomeOracle.java and arkts_runner.js on each in UTC and in
# America/New_York (the port's 'local' default zone), and compares. Exit status 1 on any unexplained mismatch.
# Usage (from anywhere): tools/dateparser-oracle/run.sh <rome checkout at 6b4a7e8> [<work dir>]
# Required: JAVA17_HOME=<Temurin 17.0.17+10 home> (the oracle refuses any other JDK).
# Optional: OTHER_JAVA=<path to another java> also runs the oracle there and lists Java results that differ;
#           NODE (default: DevEco Studio's node) and TYPESCRIPT (see arkts_runner.js).
# arkts_runner.js runs the port under Node after a TypeScript transpile, so it cannot see bugs of the ArkTS
# runtime itself (e.g. its Number(string) misrounding some decimals). To run a corpus inside the ArkTS runtime,
# see arkts_runner.js --emit-test.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
if [ -z "$JAVA17_HOME" ] || [ ! -x "$JAVA17_HOME/bin/java" ]; then
  echo "run.sh: set JAVA17_HOME to a Temurin 17.0.17+10 JDK home (got '${JAVA17_HOME}')" >&2
  exit 2
fi
if [ -z "$1" ] || [ ! -d "$1/rome/src/main/java" ]; then
  echo "run.sh: first argument must be a ROME checkout at 6b4a7e8" >&2
  exit 2
fi
NODE=${NODE:-/Applications/DevEco-Studio.app/Contents/tools/node/bin/node}
ROME=$(cd "$1" && pwd)
WORK=${2:-$(mktemp -d)}
mkdir -p "$WORK"
IMPL=$ROME/rome/src/main/java/com/rometools/rome/io/impl
"$JAVA17_HOME/bin/javac" -nowarn -d "$WORK/classes" "$IMPL/DateParser.java" "$IMPL/PropertiesLoader.java" \
  "$ROME/rome/src/main/java/com/rometools/rome/feed/impl/ConfigurableClassLoader.java" "$IMPL/Base64.java" "$IMPL/NumberParser.java" "$HERE/RomeOracle.java"
CP="$WORK/classes:$ROME/rome/src/main/resources"
python3 "$HERE/gen_cases.py" "$WORK/cases"
status=0
for zone in UTC America/New_York; do
  dpz=UTC; [ "$zone" = UTC ] || dpz=local
  out="$WORK/$(echo "$zone" | tr / _)"
  mkdir -p "$out"
  "$JAVA17_HOME/bin/java" -Duser.timezone="$zone" -Duser.language=en -Duser.country=US -cp "$CP" \
    RomeOracle --zone-cutoffs "$out/cutoffs.txt"
  for cases in "$WORK"/cases/*.txt; do
    name=$(basename "$cases" .txt)
    "$JAVA17_HOME/bin/java" -Duser.timezone="$zone" -Duser.language=en -Duser.country=US -cp "$CP" \
      RomeOracle "$cases" "$out/$name.java"
    other=""
    if [ -n "$OTHER_JAVA" ]; then
      "$OTHER_JAVA" -Doracle.allowOtherJdk=true -Duser.timezone="$zone" -Duser.language=en -Duser.country=US \
        -cp "$CP" RomeOracle "$cases" "$out/$name.other"
      other="--other $out/$name.other"
    fi
    DPZ=$dpz TZ=$zone "$NODE" "$HERE/arkts_runner.js" "$cases" "$out/$name.arkts" "$WORK"
    printf '%s ' "$zone"
    python3 "$HERE/compare.py" "$cases" "$out/$name.java" "$out/$name.arkts" "$out/cutoffs.txt" $other > "$out/$name.report" || status=1
  done
done
echo "reports: $WORK/<zone>/<corpus>.report"
exit $status
