#!/usr/bin/env bash
# @testcase: usage-python3-gi-batch12-checksum-reset
# @title: PyGObject GLib.Checksum.reset reuses the digest object
# @description: Computes a SHA1 with GLib.Checksum, calls reset(), recomputes a different digest and verifies the second digest matches a fresh Checksum instance for the same data.
# @timeout: 60
# @tags: usage, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
c = GLib.Checksum.new(GLib.ChecksumType.SHA1)
c.update(b"first-input")
first = c.get_string()
c.reset()
c.update(b"second-input")
second = c.get_string()

c2 = GLib.Checksum.new(GLib.ChecksumType.SHA1)
c2.update(b"second-input")
expected = c2.get_string()

print("first", first)
print("second", second)
print("match", second == expected)
assert first != second
assert second == expected
PY
validator_assert_contains "$tmpdir/out" 'match True'
