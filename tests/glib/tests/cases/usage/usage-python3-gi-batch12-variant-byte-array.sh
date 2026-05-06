#!/usr/bin/env bash
# @testcase: usage-python3-gi-batch12-variant-byte-array
# @title: PyGObject GLib.Variant 'ay' byte-array roundtrip
# @description: Constructs a GLib.Variant of type 'ay' (byte array) and verifies unpack returns the original byte sequence.
# @timeout: 60
# @tags: usage, python, variant
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
expected = [0, 1, 2, 254, 255]
v = GLib.Variant("ay", expected)
got = v.unpack()
print("type", v.get_type_string())
print("len", len(got))
print("first", got[0])
print("last", got[-1])
assert v.get_type_string() == "ay"
assert list(got) == expected
PY
validator_assert_contains "$tmpdir/out" 'type ay'
validator_assert_contains "$tmpdir/out" 'len 5'
validator_assert_contains "$tmpdir/out" 'first 0'
validator_assert_contains "$tmpdir/out" 'last 255'
