#!/usr/bin/env bash
# @testcase: usage-python3-gi-r19-variant-ay-indexed-byte-access
# @title: PyGObject GLib.Variant("ay") exposes per-index byte values via get_child_value().get_byte
# @description: Builds a GLib.Variant with type signature ay containing the four bytes [1, 2, 3, 255], iterates each index, and asserts get_child_value(i).get_byte() returns the original byte sequence, exercising the byte-array variant indexed-access path distinct from int32 array and string-array tests.
# @timeout: 60
# @tags: usage, python, variant, ay, r19
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

src = [1, 2, 3, 255]
v = GLib.Variant("ay", src)
got = [v.get_child_value(i).get_byte() for i in range(len(v))]
print("len=" + str(len(v)))
for i, b in enumerate(got):
    print("b" + str(i) + "=" + str(b))
assert got == src, (got, src)
print("ay-indexed-ok")
PY

validator_assert_contains "$tmpdir/out" 'len=4'
validator_assert_contains "$tmpdir/out" 'b0=1'
validator_assert_contains "$tmpdir/out" 'b1=2'
validator_assert_contains "$tmpdir/out" 'b2=3'
validator_assert_contains "$tmpdir/out" 'b3=255'
validator_assert_contains "$tmpdir/out" 'ay-indexed-ok'
