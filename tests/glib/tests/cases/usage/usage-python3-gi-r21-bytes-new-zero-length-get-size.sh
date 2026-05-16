#!/usr/bin/env bash
# @testcase: usage-python3-gi-r21-bytes-new-zero-length-get-size
# @title: PyGObject GLib.Bytes.new(b'') reports size 0 and equality with another empty Bytes
# @description: Constructs a GLib.Bytes from a zero-length Python bytes object and asserts get_size() returns 0, get_data() returns an empty bytes object, and equal() returns True against a second zero-length GLib.Bytes, exercising the empty-Bytes boundary case distinct from prior nonempty-payload Bytes roundtrip tests.
# @timeout: 60
# @tags: usage, python, bytes, empty, r21
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

b1 = GLib.Bytes.new(b"")
b2 = GLib.Bytes.new(b"")
print("size1=" + str(b1.get_size()))
print("data1_len=" + str(len(b1.get_data() or b"")))
print("equal=" + str(b1.equal(b2)))
print("compare=" + str(b1.compare(b2)))
PY

validator_assert_contains "$tmpdir/out" 'size1=0'
validator_assert_contains "$tmpdir/out" 'data1_len=0'
validator_assert_contains "$tmpdir/out" 'equal=True'
validator_assert_contains "$tmpdir/out" 'compare=0'
