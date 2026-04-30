#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-pwhash-argon2id
# @title: PyNaCl crypto_pwhash argon2id at MIN ops/mem limits
# @description: Calls the low-level nacl.bindings.crypto_pwhash entry point with the argon2id algorithm constant, the documented MIN ops/mem limits, and a fixed 16-byte salt, asserts the derived key has the requested 32-byte length, that the same inputs reproduce the same key, and that swapping the password yields a different key.
# @timeout: 600
# @tags: usage, crypto, pwhash, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import nacl.bindings as nb

# nacl.bindings exposes the algorithm-aware entry point under the name
# crypto_pwhash_alg; the bare name "crypto_pwhash" resolves to the
# submodule that defines all of these constants, not to a callable.
pwhash = nb.crypto_pwhash_alg

ALG = nb.crypto_pwhash_ALG_ARGON2ID13
SALT = bytes([0x55]) * nb.crypto_pwhash_SALTBYTES
OPS = nb.crypto_pwhash_argon2id_OPSLIMIT_MIN
MEM = nb.crypto_pwhash_argon2id_MEMLIMIT_MIN

password = b"validator-pwhash-password"
out_len = 32

k1 = pwhash(out_len, password, SALT, OPS, MEM, ALG)
assert len(k1) == out_len, len(k1)

k2 = pwhash(out_len, password, SALT, OPS, MEM, ALG)
assert k1 == k2, "argon2id derivation not deterministic"

k3 = pwhash(out_len, b"validator-different-password", SALT, OPS, MEM, ALG)
assert k1 != k3, "different passwords produced same key"

print("ok", out_len, k1.hex()[:16])
PY
