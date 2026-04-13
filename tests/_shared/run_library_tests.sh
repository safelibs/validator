#!/usr/bin/env bash
set -euo pipefail

library=${1:?usage: run_library_tests.sh <library>}
run_script="/validator/tests/${library}/tests/run.sh"

if [[ ! -f "$run_script" ]]; then
  echo "Missing library test script: $run_script" >&2
  exit 1
fi

if [[ ! -x "$run_script" ]]; then
  echo "Library test script is not executable: $run_script" >&2
  exit 1
fi

export VALIDATOR_LIBRARY="$library"
export VALIDATOR_LIBRARY_ROOT="/validator/tests/${library}"
export VALIDATOR_TAGGED_ROOT="$VALIDATOR_LIBRARY_ROOT/tests/tagged-port"

exec "$run_script"
