#!/usr/bin/env bash
# @testcase: usage-python3-gi-r18-variant-dict-of-int32-build-and-lookup
# @title: PyGObject GLib.Variant a{si} round-trips three int32 values through lookup_value
# @description: Builds a GLib.Variant with type signature a{si} containing three string-keyed int32 entries, then calls lookup_value on each key and asserts the unpacked int32 value matches the original Python int, exercising the dict-of-int variant construction and per-key lookup distinct from string-array variant tests.
# @timeout: 60
# @tags: usage, python, variant, dict-int32, r18
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

src = {"one": 1, "two": 2, "thirty": 30}
v = GLib.Variant("a{si}", src)
for k, want in src.items():
    got = v.lookup_value(k, GLib.VariantType.new("i")).get_int32()
    print("kv " + k + "=" + str(got))
    assert got == want, (k, got, want)
print("dict-of-int32-ok")
PY

validator_assert_contains "$tmpdir/out" 'dict-of-int32-ok'
validator_assert_contains "$tmpdir/out" 'kv one=1'
validator_assert_contains "$tmpdir/out" 'kv two=2'
validator_assert_contains "$tmpdir/out" 'kv thirty=30'
