#!/usr/bin/env bash
# @testcase: usage-python3-gi-r19-compute-hmac-sha1-key-quick-brown-fox
# @title: PyGObject GLib.compute_hmac_for_string SHA1 with key="key" on the quick-brown-fox vector
# @description: Calls GLib.compute_hmac_for_string with ChecksumType.SHA1, key bytes b"key", and the well-known string "The quick brown fox jumps over the lazy dog" and asserts the returned hex digest equals de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9 from RFC HMAC-SHA1 reference, exercising the HMAC-SHA1 surface distinct from prior HMAC-SHA256 and HMAC-MD5 tests.
# @timeout: 60
# @tags: usage, python, hmac, sha1, r19
# @client: python3-gi

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PY'
from gi.repository import GLib

key = b"key"
msg = "The quick brown fox jumps over the lazy dog"
mac = GLib.compute_hmac_for_string(GLib.ChecksumType.SHA1, key, msg, len(msg))
print("hmac=" + mac)
print("len=" + str(len(mac)))
PY

validator_assert_contains "$tmpdir/out" 'hmac=de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9'
validator_assert_contains "$tmpdir/out" 'len=40'
