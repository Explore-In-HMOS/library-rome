#!/bin/sh
# Regenerates fixtures/ (ROME's test resources plus tools/golden/repo-fixtures) and oh_rome/src/test/golden/ from ROME
# 6b4a7e8. Needs JAVA_HOME = Temurin 17.0.17+10 and network access on the first run: it clones ROME into
# tools/golden/.rome (or uses ROME_DIR) and downloads Maven through ROME's wrapper. The output is committed; nobody
# else needs any of this to run the tests.
set -eu
REPO=$(cd "$(dirname "$0")/../.." && pwd)
TOOL="$REPO/tools/golden"
ROME_COMMIT=6b4a7e8
ROME_DIR=${ROME_DIR:-"$TOOL/.rome"}
OUT="$TOOL/.out"
mkdir -p "$OUT"

# Temurin 17.0.17+10 for every oracle and for the goldens, because JDKs differ in URL, Currency, charset and zone data. Maven and the generator both use it.
if ! "${JAVA_HOME:?set JAVA_HOME to Temurin 17.0.17+10}/bin/java" -version 2>&1 | grep -q 'Temurin-17.0.17+10'; then
  echo "generate.sh: JAVA_HOME must be Temurin 17.0.17+10, got: $("$JAVA_HOME/bin/java" -version 2>&1 | tail -1)"
  exit 1
fi

if [ ! -d "$ROME_DIR/.git" ]; then
  git clone -q https://github.com/rometools/rome "$ROME_DIR"
fi
if [ "$(git -C "$ROME_DIR" rev-parse --short=7 HEAD)" != "$ROME_COMMIT" ]; then
  git -C "$ROME_DIR" checkout -q "$ROME_COMMIT"
fi
# ROME's Maven wrapper looks for .mvn/ in the current directory.
(cd "$ROME_DIR" && ./mvnw -q -B -DskipTests -Dmaven.javadoc.skip=true install)
(cd "$ROME_DIR" && ./mvnw -q -B -f "$TOOL/pom.xml" package dependency:build-classpath -Dmdep.outputFile="$OUT/classpath.txt")
CP="$TOOL/target/classes:$(cat "$OUT/classpath.txt")"

golden() {
  "$JAVA_HOME/bin/java" -Duser.timezone=UTC -Duser.language=en -Duser.country=US -cp "$CP" romeharmony.golden.GoldenMain "$@"
}

rm -rf "$REPO/fixtures"
golden list "$ROME_DIR" "$REPO"
for profile in core opml full; do
  golden dump "$profile" "$REPO" "$OUT"
done
golden emit "$REPO" "$OUT"
