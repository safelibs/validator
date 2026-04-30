#!/usr/bin/env bash
# @testcase: usage-python3-gi-variant-double-get
# @title: PyGObject GLib Variant double get_double roundtrip
# @description: Builds a double-typed GLib Variant in PyGObject and verifies get_double roundtrips the floating-point value within a small epsilon.
# @timeout: 180
# @tags: usage, glib, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-variant-double-get"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v = GLib.Variant("d", 3.14)
got = v.get_double()
assert abs(got - 3.14) < 1e-9, "double roundtrip mismatch: %r" % got
print("double=%.2f" % got)
print("type=" + v.get_type_string())
PY

validator_assert_contains "$tmpdir/out" 'double=3.14'
validator_assert_contains "$tmpdir/out" 'type=d'
