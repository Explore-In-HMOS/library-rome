#!/bin/sh
# Writes oh_rome/LICENSE: the root LICENSE, then NOTICE and LICENSE-JDOM, each after a header. The HAR packs LICENSE
# but no NOTICE or other license file. With --check, exits non-zero if oh_rome/LICENSE is out of date instead.
set -e
cd "$(dirname "$0")/.."
SEP=$(printf '=%.0s' $(seq 80))
pack() {
  cat LICENSE
  printf '\n\n%s\nNOTICE\n%s\n\n' "$SEP" "$SEP"
  cat NOTICE
  printf '\n\n%s\nLICENSE-JDOM\n%s\n\n' "$SEP" "$SEP"
  cat LICENSE-JDOM
}
if [ "$1" = "--check" ]; then
  pack | cmp -s - oh_rome/LICENSE || { echo "check: oh_rome/LICENSE is out of date, run scripts/pack-license.sh"; exit 1; }
else
  pack > oh_rome/LICENSE
fi
