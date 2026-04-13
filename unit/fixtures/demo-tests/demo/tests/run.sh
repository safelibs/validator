#!/usr/bin/env bash
set -euo pipefail

test "$VALIDATOR_LIBRARY" = "demo"
test "$VALIDATOR_LIBRARY_ROOT" = "/validator/tests/demo"
test "$VALIDATOR_TAGGED_ROOT" = "/validator/tests/demo/tests/tagged-port"
test -d "$VALIDATOR_TAGGED_ROOT"
test -f "$VALIDATOR_TAGGED_ROOT/marker.txt"

echo "running demo validator harness"
cat "$VALIDATOR_TAGGED_ROOT/marker.txt"

if dpkg-query -W -f='${Status}\n' demo-safe-marker 2>/dev/null; then
  echo "demo-safe-marker installed"
else
  echo "demo-safe-marker not installed"
fi
