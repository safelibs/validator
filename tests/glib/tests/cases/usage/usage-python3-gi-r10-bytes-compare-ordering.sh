#!/usr/bin/env bash
# @testcase: usage-python3-gi-r10-bytes-compare-ordering
# @title: PyGObject GLib.Bytes.compare yields lexicographic ordering
# @description: Constructs three GLib.Bytes objects and verifies Bytes.compare returns negative, zero, and positive for the lexicographic less-than, equal, and greater-than cases.
# @timeout: 60
# @tags: usage, python, bytes
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
a = GLib.Bytes.new(b"alpha")
b = GLib.Bytes.new(b"alpha")
c = GLib.Bytes.new(b"beta")
eq = a.compare(b)
lt = a.compare(c)
gt = c.compare(a)
print("eq", eq)
print("lt-sign", -1 if lt < 0 else (1 if lt > 0 else 0))
print("gt-sign", -1 if gt < 0 else (1 if gt > 0 else 0))
assert eq == 0
assert lt < 0
assert gt > 0
PY
validator_assert_contains "$tmpdir/out" 'eq 0'
validator_assert_contains "$tmpdir/out" 'lt-sign -1'
validator_assert_contains "$tmpdir/out" 'gt-sign 1'
