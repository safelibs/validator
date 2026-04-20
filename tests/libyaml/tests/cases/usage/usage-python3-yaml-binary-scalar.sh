#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
import yaml

decoded = yaml.safe_load("payload: !!binary dmFsaWRhdG9yLWJpbmFyeQ==\n")["payload"]
assert decoded == b"validator-binary"
print(len(decoded))
PY

validator_assert_contains "$tmpdir/out" '16'
