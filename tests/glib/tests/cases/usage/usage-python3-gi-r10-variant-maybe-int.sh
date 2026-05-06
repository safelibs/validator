#!/usr/bin/env bash
# @testcase: usage-python3-gi-r10-variant-maybe-int
# @title: PyGObject GLib.Variant 'mi' maybe-int distinguishes None and 42
# @description: Constructs Variant 'mi' with a value and with None, verifies type string is 'mi' and unpack returns the original int or None.
# @timeout: 60
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v_some = GLib.Variant("mi", 42)
v_none = GLib.Variant("mi", None)
print("type-some", v_some.get_type_string())
print("type-none", v_none.get_type_string())
print("val-some", v_some.unpack())
print("val-none", v_none.unpack())
assert v_some.get_type_string() == "mi"
assert v_none.get_type_string() == "mi"
assert v_some.unpack() == 42
assert v_none.unpack() is None
PY
validator_assert_contains "$tmpdir/out" 'type-some mi'
validator_assert_contains "$tmpdir/out" 'type-none mi'
validator_assert_contains "$tmpdir/out" 'val-some 42'
validator_assert_contains "$tmpdir/out" 'val-none None'
