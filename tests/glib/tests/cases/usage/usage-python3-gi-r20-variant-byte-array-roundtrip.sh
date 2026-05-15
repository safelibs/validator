#!/usr/bin/env bash
# @testcase: usage-python3-gi-r20-variant-byte-array-roundtrip
# @title: PyGObject GLib.Variant byte-array "ay" roundtrips a non-trivial byte sequence
# @description: Builds a GLib.Variant of type "ay" from a Python bytes payload b"\x00\x01\x02hello\xff", round-trips it via GVariant.unpack and asserts the recovered Python list equals [0, 1, 2, 104, 101, 108, 108, 111, 255], exercising the byte-array Variant construction and unpacking distinct from prior indexed-byte-access tests.
# @timeout: 60
# @tags: usage, python, variant, byte-array, r20
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

payload = b"\x00\x01\x02hello\xff"
v = GLib.Variant("ay", payload)
unpacked = v.unpack()
print("unpacked=" + repr(unpacked))
print("len=" + str(len(unpacked)))
PY

validator_assert_contains "$tmpdir/out" 'unpacked=[0, 1, 2, 104, 101, 108, 108, 111, 255]'
validator_assert_contains "$tmpdir/out" 'len=9'
