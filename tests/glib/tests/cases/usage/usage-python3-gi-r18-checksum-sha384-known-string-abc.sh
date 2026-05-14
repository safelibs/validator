#!/usr/bin/env bash
# @testcase: usage-python3-gi-r18-checksum-sha384-known-string-abc
# @title: PyGObject GLib.compute_checksum_for_string with SHA384 returns the FIPS abc digest
# @description: Calls GLib.compute_checksum_for_string with GLib.ChecksumType.SHA384 over the three-byte ASCII string "abc" and asserts the resulting hex string equals the standard FIPS 180-2 digest, exercising the SHA384 algorithm path through the convenience wrapper distinct from prior SHA256 known-vector tests.
# @timeout: 60
# @tags: usage, python, checksum, sha384, r18
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

digest = GLib.compute_checksum_for_string(GLib.ChecksumType.SHA384, "abc", -1)
print("digest=" + digest)
PY

expected='cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7'
validator_assert_contains "$tmpdir/out" "digest=$expected"
