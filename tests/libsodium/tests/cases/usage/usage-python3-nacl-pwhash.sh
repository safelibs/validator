#!/usr/bin/env bash
# @testcase: usage-python3-nacl-pwhash
# @title: PyNaCl password hash
# @description: Derives a key with PyNaCl argon2id password hashing parameters.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-pwhash"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.pwhash import argon2id
salt = b"0" * argon2id.SALTBYTES
key = argon2id.kdf(32, b"password", salt, opslimit=argon2id.OPSLIMIT_MIN, memlimit=argon2id.MEMLIMIT_MIN)
assert len(key) == 32
print("key", len(key))
PY
