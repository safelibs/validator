#!/usr/bin/env bash
# @testcase: usage-python3-nacl-generichash-bytes-bounds
# @title: PyNaCl generichash digest length at MIN and MAX boundaries
# @description: Reads nacl.bindings.crypto_generichash_BYTES_MIN, crypto_generichash_BYTES, and crypto_generichash_BYTES_MAX, asserts the libsodium documented values (16, 32, 64), and exercises crypto_generichash on the MIN, default, and MAX digest lengths against a fixed message and a fixed key, asserting each output has the requested length and that the same inputs are deterministic.
# @timeout: 180
# @tags: usage, crypto, hash, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import nacl.bindings as nb

# nacl.bindings exposes the BLAKE2b hash entry point under the long
# crypto_generichash_blake2b_salt_personal name; the bare attribute
# crypto_generichash resolves to the submodule that defines all of these
# constants, not to a callable.
generichash = nb.crypto_generichash_blake2b_salt_personal

BMIN = nb.crypto_generichash_BYTES_MIN
BDEF = nb.crypto_generichash_BYTES
BMAX = nb.crypto_generichash_BYTES_MAX
KMIN = nb.crypto_generichash_KEYBYTES_MIN
KMAX = nb.crypto_generichash_KEYBYTES_MAX

assert BMIN == 16, BMIN
assert BDEF == 32, BDEF
assert BMAX == 64, BMAX
assert KMIN <= KMAX

message = b"validator generichash boundary message"
key = bytes([0x7a]) * 32
assert KMIN <= len(key) <= KMAX

for n in (BMIN, BDEF, BMAX):
    h1 = generichash(message, digest_size=n, key=key)
    h2 = generichash(message, digest_size=n, key=key)
    assert len(h1) == n, (n, len(h1))
    assert h1 == h2, n

# Different lengths must give different prefixes (or values), since BLAKE2b
# parameterises the personalised hash by output length.
hmin = generichash(message, digest_size=BMIN, key=key)
hmax = generichash(message, digest_size=BMAX, key=key)
assert hmax[:BMIN] != hmin, "min-prefix of max digest unexpectedly matched min digest"

print("ok", BMIN, BDEF, BMAX)
PY
