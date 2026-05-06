#!/usr/bin/env bash
# @testcase: usage-python3-gi-r10-variant-vardict-lookup
# @title: PyGObject GLib.Variant 'a{sv}' lookup_value finds nested values
# @description: Builds a Variant 'a{sv}' with mixed-type entries and verifies lookup_value returns the original Variant for present keys and None for missing keys.
# @timeout: 60
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
v = GLib.Variant("a{sv}", {
    "name": GLib.Variant("s", "alice"),
    "age": GLib.Variant("i", 30),
})
got_name = v.lookup_value("name", GLib.VariantType.new("s"))
got_age = v.lookup_value("age", GLib.VariantType.new("i"))
got_missing = v.lookup_value("nope", None)
print("name", got_name.get_string())
print("age", got_age.get_int32())
print("missing", got_missing is None)
assert got_name.get_string() == "alice"
assert got_age.get_int32() == 30
assert got_missing is None
PY
validator_assert_contains "$tmpdir/out" 'name alice'
validator_assert_contains "$tmpdir/out" 'age 30'
validator_assert_contains "$tmpdir/out" 'missing True'
