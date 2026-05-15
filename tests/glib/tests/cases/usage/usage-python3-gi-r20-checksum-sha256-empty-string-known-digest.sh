#!/usr/bin/env bash
# @testcase: usage-python3-gi-r20-checksum-sha256-empty-string-known-digest
# @title: PyGObject GLib.compute_checksum_for_string SHA256 of empty string equals canonical digest
# @description: Calls GLib.compute_checksum_for_string with SHA256 over the empty string and asserts the returned 64-character hex digest equals the canonical FIPS-180-4 value e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855, exercising the SHA256 known-answer test for the zero-length input distinct from the existing MD5 empty-string test.
# @timeout: 60
# @tags: usage, python, checksum, sha256, empty, r20
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

digest = GLib.compute_checksum_for_string(GLib.ChecksumType.SHA256, "", -1)
print("digest=" + digest)
print("len=" + str(len(digest)))
PY

validator_assert_contains "$tmpdir/out" 'digest=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
validator_assert_contains "$tmpdir/out" 'len=64'
