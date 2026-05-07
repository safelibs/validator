#!/usr/bin/env bash
# @testcase: usage-python3-gi-r14-compute-checksum-for-string-sha256
# @title: PyGObject GLib.compute_checksum_for_string returns canonical SHA-256 hex
# @description: Calls GLib.compute_checksum_for_string with ChecksumType.SHA256 on the literal 'abc' (with length=-1) and asserts the returned hex digest equals the published SHA-256 known-answer ba7816bf...f20015ad.
# @timeout: 60
# @tags: usage, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
digest = GLib.compute_checksum_for_string(GLib.ChecksumType.SHA256, "abc", -1)
print("digest", digest)
print("len", len(digest))
PY

# RFC 6234 / FIPS 180-4 known answer for "abc"
validator_assert_contains "$tmpdir/out" 'digest ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'
validator_assert_contains "$tmpdir/out" 'len 64'
