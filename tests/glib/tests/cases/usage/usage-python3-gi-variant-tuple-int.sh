#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-tuple-int
# @title: PyGObject GLib Variant tuple of ints
# @description: Builds a GLib.Variant with the (ii) signature from PyGObject and verifies unpack returns the original integer pair.
# @timeout: 180
# @tags: usage, glib, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-tuple-int"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v = GLib.Variant("(ii)", (11, -7))
a, b = v.unpack()
print(f"signature={v.get_type_string()}")
print(f"a={a}")
print(f"b={b}")
print(f"sum={a + b}")
PY

validator_assert_contains "$tmpdir/out" 'signature=(ii)'
validator_assert_contains "$tmpdir/out" 'a=11'
validator_assert_contains "$tmpdir/out" 'b=-7'
validator_assert_contains "$tmpdir/out" 'sum=4'
