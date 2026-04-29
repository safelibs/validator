#!/usr/bin/env bash
# @testcase: usage-python3-json-roundtrip
# @title: Python literal round trip
# @description: Serializes and reloads a structured Python literal with Python and verifies the decoded values survive round trip.
# @timeout: 180
# @tags: usage, python
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-json-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
import ast
payload = {"name": "alpha", "count": 7, "items": [1, 2]}
text = repr(payload)
roundtrip = ast.literal_eval(text)
assert roundtrip["items"] == [1, 2]
print(text)
PY
validator_assert_contains "$tmpdir/out" "'count': 7"
validator_assert_contains "$tmpdir/out" "'name': 'alpha'"
