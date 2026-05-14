#!/usr/bin/env bash
# @testcase: usage-python3-gi-r17-checksum-sha1-known-string-abc
# @title: PyGObject GLib.Checksum SHA1 of "abc" equals the published RFC 3174 digest
# @description: Constructs a GLib.Checksum with type SHA1, feeds the three-byte literal "abc", and asserts get_string returns the lowercase hex digest a9993e364706816aba3e25717850c26c9cd0d89d as documented by RFC 3174, exercising the SHA1 surface distinct from existing SHA256 tests.
# @timeout: 60
# @tags: usage, python, checksum, sha1
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

c = GLib.Checksum.new(GLib.ChecksumType.SHA1)
c.update(b"abc")
print("digest=" + c.get_string())
PY

validator_assert_contains "$tmpdir/out" 'digest=a9993e364706816aba3e25717850c26c9cd0d89d'
