#!/usr/bin/env bash
set -euo pipefail

test "$VALIDATOR_LIBRARY" = "demo-pass"
test "$VALIDATOR_LIBRARY_ROOT" = "/validator/tests/demo-pass"
test "$VALIDATOR_TAGGED_ROOT" = "/validator/tests/demo-pass/tests/tagged-port"
test -f "$VALIDATOR_TAGGED_ROOT/marker.txt"

echo "demo-pass running"
if dpkg-query -W -f='${Status}\n' demo-pass-safe-marker 2>/dev/null; then
  echo "demo-pass-safe-marker installed"
else
  echo "demo-pass-safe-marker not installed"
fi
