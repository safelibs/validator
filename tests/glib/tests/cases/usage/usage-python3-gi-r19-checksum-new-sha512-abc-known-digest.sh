#!/usr/bin/env bash
# @testcase: usage-python3-gi-r19-checksum-new-sha512-abc-known-digest
# @title: PyGObject GLib.Checksum SHA512 incremental update of "abc" equals the FIPS 180-4 digest
# @description: Constructs a GLib.Checksum with type SHA512, calls update on the three-byte literal "abc", and asserts get_string returns the lowercase 128-character hex digest ddaf35...ca49f from FIPS 180-4, exercising the incremental-update Checksum surface for SHA512 distinct from prior compute_checksum_for_string tests.
# @timeout: 60
# @tags: usage, python, checksum, sha512, r19
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

c = GLib.Checksum.new(GLib.ChecksumType.SHA512)
c.update(b"abc")
digest = c.get_string()
print("digest=" + digest)
print("len=" + str(len(digest)))
PY

validator_assert_contains "$tmpdir/out" 'digest=ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f'
validator_assert_contains "$tmpdir/out" 'len=128'
