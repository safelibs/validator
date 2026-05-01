#!/usr/bin/env bash
# @testcase: usage-python3-gi-checksum-sha512-string
# @title: PyGObject GLib compute_checksum_for_string SHA-512
# @description: Computes the SHA-512 digest of the string abc through GLib.compute_checksum_for_string and verifies the canonical 128-character hex digest matches the FIPS 180-4 known-answer vector.
# @timeout: 120
# @tags: usage, glib, python, checksum
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-gi-checksum-sha512-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

digest = GLib.compute_checksum_for_string(GLib.ChecksumType.SHA512, "abc", -1)
print("digest=" + digest)
print("len=" + str(len(digest)))
PY

# FIPS 180-4 SHA-512("abc"):
#   ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a
#   2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f
validator_assert_contains "$tmpdir/out" 'digest=ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f'
validator_assert_contains "$tmpdir/out" 'len=128'
