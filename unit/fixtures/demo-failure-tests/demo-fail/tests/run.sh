#!/usr/bin/env bash
set -euo pipefail

test "$VALIDATOR_LIBRARY" = "demo-fail"
test "$VALIDATOR_LIBRARY_ROOT" = "/validator/tests/demo-fail"
test "$VALIDATOR_TAGGED_ROOT" = "/validator/tests/demo-fail/tests/tagged-port"
test -f "$VALIDATOR_TAGGED_ROOT/marker.txt"

if dpkg-query -W -f='${Status}\n' demo-fail-safe-marker 2>/dev/null; then
  echo "demo-fail-safe-marker installed"
else
  echo "demo-fail-safe-marker not installed"
fi

echo "demo-fail intentionally returning failure"
exit 1
