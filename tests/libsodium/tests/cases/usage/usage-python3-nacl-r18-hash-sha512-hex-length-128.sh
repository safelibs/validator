#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r18-hash-sha512-hex-length-128
# @title: PyNaCl nacl.hash.sha512 returns a 128-character lowercase hex digest by default
# @description: Calls nacl.hash.sha512(b"") with the default HexEncoder and asserts the output is a 128-character ASCII bytes string containing only [0-9a-f], confirming the libsodium SHA-512 default hex-encoded output shape; also calls sha512 on a non-empty payload and asserts the result differs from the empty-input digest.
# @timeout: 60
# @tags: usage, crypto, hash, sha512, python, r18
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.hash
import string

empty = nacl.hash.sha512(b"")
assert isinstance(empty, bytes), type(empty)
assert len(empty) == 128, ("len_empty", len(empty))
allowed = set(string.hexdigits.lower().encode())
assert set(empty).issubset(allowed), ("non_hex",)

other = nacl.hash.sha512(b"r18 pynacl sha512 vector")
assert len(other) == 128, ("len_other", len(other))
assert other != empty, ("empty equals non-empty",)
print("ok sha512 len=%d" % len(empty))
PY
