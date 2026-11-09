#!/bin/sh
# Builds the library HAR and the entry sample app and runs both modules' local unit tests.
# Exits non-zero on any compile error, ArkTS warning, crash or failed test. hvigor itself exits 0 for failed or crashed
# tests, so never trust its exit code or its "BUILD SUCCESSFUL" line.
cd "$(dirname "$0")/.." || exit 1
: "${DEVECO_SDK_HOME:=/Applications/DevEco-Studio.app/Contents/sdk}"
export DEVECO_SDK_HOME
# Logs live outside oh_rome/.test: hvigor wipes that directory during the build.
LOG_DIR=.check
mkdir -p "$LOG_DIR"
./scripts/pack-license.sh --check || exit 1

if [ ! -d oh_modules/@ohos/hypium ]; then
  echo "check: dependencies are not installed; run: ohpm install --all"
  exit 1
fi

build() { # module, task, log
  hvigorw --mode module -p "module=$1@default" -p product=default "$2" --no-daemon > "$LOG_DIR/$3" 2>&1
  if grep -qE 'ArkTS:(ERROR|WARN)|BUILD FAILED|ERROR:|Missing module info' "$LOG_DIR/$3"; then
    grep -E 'ArkTS:(ERROR|WARN)|ERROR|BUILD FAILED|Missing module info' -A 3 "$LOG_DIR/$3" | head -60
    echo "check: $1 build failed or has warnings (full log: $LOG_DIR/$3)"
    exit 1
  fi
}

# Coverage instrumentation makes the test run about 3.4x slower and adds nothing to pass/fail.
# A test bundle that throws while loading makes hvigor wait forever instead of exiting, so the run has a time limit.
: "${CHECK_TIMEOUT:=1800}"
kill_tree() {
  for child in $(pgrep -P "$1"); do
    kill_tree "$child"
  done
  kill "$1" 2>/dev/null
}
run_tests() { # module, log
  RESULT="$1/.test/default/intermediates/test/coverage_data/test_result.txt"
  rm -f "$RESULT"
  hvigorw -p "module=$1@default" -p product=default -p ohos-test-coverage=false test --no-daemon > "$LOG_DIR/$2" 2>&1 &
  TEST_PID=$!
  trap 'kill_tree "$TEST_PID"; exit 130' INT TERM HUP
  START=$(date +%s)
  while kill -0 "$TEST_PID" 2>/dev/null; do
    if [ $(($(date +%s) - START)) -ge "$CHECK_TIMEOUT" ]; then
      kill_tree "$TEST_PID"
      wait "$TEST_PID" 2>/dev/null
      echo "check: $1 tests did not finish in ${CHECK_TIMEOUT}s; the test bundle probably crashed while loading (full log: $LOG_DIR/$2)"
      exit 1
    fi
    sleep 2
  done
  # Its exit code says nothing: see the top of this file.
  wait "$TEST_PID"
  trap - INT TERM HUP
  if [ ! -f "$RESULT" ]; then
    grep -E 'ERROR|Error' "$LOG_DIR/$2" | head -40
    echo "check: $1 tests did not run; the test bundle crashed while loading (full log: $LOG_DIR/$2)"
    exit 1
  fi
  SUMMARY=$(grep '^Tests run:' "$RESULT")
  echo "$1: $SUMMARY"
  if ! echo "$SUMMARY" | grep -q 'Failure: 0, Error: 0'; then
    grep -B 1 -A 4 'result=Failure\|result=Error' "$RESULT" | grep -v '^    at ' | head -60
    echo "check: $1 has failing tests (details: $RESULT)"
    exit 1
  fi
}

# The library module, its package and its directory all share the name: hvigor's unit-test run hangs otherwise.
build oh_rome assembleHar build.log
run_tests oh_rome test.log
# The sample app: it must build without ArkTS warnings, and its own logic has tests.
build entry assembleHap entry-build.log
run_tests entry entry-test.log
