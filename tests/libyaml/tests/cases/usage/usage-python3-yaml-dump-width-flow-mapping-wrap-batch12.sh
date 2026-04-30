#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-width-flow-mapping-wrap-batch12
# @title: PyYAML dump width wraps flow mapping
# @description: Dumps a flow-style mapping with yaml.dump width=20 and verifies the output wraps onto multiple lines while still round-tripping.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-width-flow-mapping-wrap-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" >"$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]

data = {
    "alpha": "first-value",
    "bravo": "second-value",
    "charlie": "third-value",
    "delta": "fourth-value",
}
text = yaml.dump(data, default_flow_style=True, width=20, sort_keys=True)

lines = text.splitlines()
non_empty = [ln for ln in lines if ln.strip()]
assert len(non_empty) >= 2, text
# At least one wrapped continuation line should not start at column 0.
assert any(ln.startswith(" ") for ln in non_empty[1:]), text

# Width must still produce a round-trippable document.
roundtrip = yaml.safe_load(text)
assert roundtrip == data, roundtrip

print("LINES", len(non_empty))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "OK"
python3 -c "import sys; lines=int([ln.split()[1] for ln in open('$tmpdir/out') if ln.startswith('LINES')][0]); assert lines>=2; print('LINES_OK')"
echo "OK"
