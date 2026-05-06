#!/usr/bin/env bash
# @testcase: usage-python3-gi-r10-compute-hmac-md5
# @title: PyGObject GLib.compute_hmac_for_data MD5 RFC 2104 KAT
# @description: Computes HMAC-MD5 of "Hi There" with a 16-byte 0x0b key via GLib.compute_hmac_for_data and verifies the digest matches the RFC 2104 published value.
# @timeout: 60
# @tags: usage, python, hmac
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib
key = b"\x0b" * 16
data = b"Hi There"
digest = GLib.compute_hmac_for_data(GLib.ChecksumType.MD5, key, data)
expected = "9294727a3638bb1c13f48ef8158bfc9d"  # RFC 2104 test case 1
print("digest", digest)
print("expected", expected)
assert digest == expected
PY
validator_assert_contains "$tmpdir/out" 'digest 9294727a3638bb1c13f48ef8158bfc9d'
