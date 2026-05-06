#!/usr/bin/env bash
# @testcase: usage-python3-gi-batch12-bytes-equality
# @title: PyGObject GLib.Bytes equality and hash
# @description: Constructs two GLib.Bytes objects with identical content, verifies equal() returns True and hashing matches, and that different content yields equal() False.
# @timeout: 60
# @tags: usage, python, bytes
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
a = GLib.Bytes.new(b"validator")
b = GLib.Bytes.new(b"validator")
c = GLib.Bytes.new(b"different")
print("equal_ab", a.equal(b))
print("equal_ac", a.equal(c))
print("hash_match", a.hash() == b.hash())
assert a.equal(b)
assert not a.equal(c)
assert a.hash() == b.hash()
PY
validator_assert_contains "$tmpdir/out" 'equal_ab True'
validator_assert_contains "$tmpdir/out" 'equal_ac False'
validator_assert_contains "$tmpdir/out" 'hash_match True'
