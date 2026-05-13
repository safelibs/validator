#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r16-argon2id-kdf-16-byte-output
# @title: PyNaCl nacl.pwhash.argon2id.kdf derives a 16-byte key from a fixed password and salt
# @description: Calls nacl.pwhash.argon2id.kdf with a 16-byte output size, the documented OPSLIMIT_MIN and MEMLIMIT_MIN parameters, a fixed password and a fixed 16-byte salt, asserts the returned key is exactly 16 bytes, asserts a second call with identical inputs returns an identical key, and asserts a different salt produces a different key.
# @timeout: 120
# @tags: usage, crypto, pwhash, argon2id, python, r16
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.pwhash

salt_a = b"\x10" * nacl.pwhash.argon2id.SALTBYTES
salt_b = b"\x20" * nacl.pwhash.argon2id.SALTBYTES
password = b"r16-argon2id-password"

k1 = nacl.pwhash.argon2id.kdf(
    16, password, salt_a,
    opslimit=nacl.pwhash.argon2id.OPSLIMIT_MIN,
    memlimit=nacl.pwhash.argon2id.MEMLIMIT_MIN,
)
k2 = nacl.pwhash.argon2id.kdf(
    16, password, salt_a,
    opslimit=nacl.pwhash.argon2id.OPSLIMIT_MIN,
    memlimit=nacl.pwhash.argon2id.MEMLIMIT_MIN,
)
k3 = nacl.pwhash.argon2id.kdf(
    16, password, salt_b,
    opslimit=nacl.pwhash.argon2id.OPSLIMIT_MIN,
    memlimit=nacl.pwhash.argon2id.MEMLIMIT_MIN,
)

assert isinstance(k1, bytes), type(k1)
assert len(k1) == 16, len(k1)
assert k1 == k2, "argon2id kdf non-deterministic"
assert k1 != k3, "argon2id kdf ignored salt"
print("ok", k1.hex())
PY
