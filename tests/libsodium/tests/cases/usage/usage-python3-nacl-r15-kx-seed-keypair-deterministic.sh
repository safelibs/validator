#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r15-kx-seed-keypair-deterministic
# @title: PyNaCl bindings crypto_kx_seed_keypair derives a deterministic keypair from a fixed seed
# @description: Calls nacl.bindings.crypto_kx_seed_keypair twice on the same fixed 32-byte seed, asserts both runs return identical (public, secret) pairs of the documented sizes (crypto_kx_PUBLIC_KEY_BYTES and crypto_kx_SECRET_KEY_BYTES), then calls again with a different seed and asserts both the public and secret keys differ — exercising libsodium's seeded X25519 keypair derivation through PyNaCl's low-level binding.
# @timeout: 120
# @tags: usage, crypto, kx, seed-keypair, python, r15
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.bindings import (
    crypto_kx_SEED_BYTES,
    crypto_kx_PUBLIC_KEY_BYTES,
    crypto_kx_SECRET_KEY_BYTES,
    crypto_kx_seed_keypair,
)

seed_a = bytes([0x15]) * crypto_kx_SEED_BYTES
seed_b = bytes([0x16]) * crypto_kx_SEED_BYTES

pub_a1, sec_a1 = crypto_kx_seed_keypair(seed_a)
pub_a2, sec_a2 = crypto_kx_seed_keypair(seed_a)
pub_b,  sec_b  = crypto_kx_seed_keypair(seed_b)

assert isinstance(pub_a1, bytes) and isinstance(sec_a1, bytes)
assert len(pub_a1) == crypto_kx_PUBLIC_KEY_BYTES, len(pub_a1)
assert len(sec_a1) == crypto_kx_SECRET_KEY_BYTES, len(sec_a1)

# Determinism: same seed -> same (pub, sec).
assert pub_a1 == pub_a2, "deterministic seed produced different public keys"
assert sec_a1 == sec_a2, "deterministic seed produced different secret keys"

# Distinct seeds -> distinct keys (both halves).
assert pub_a1 != pub_b, "distinct seeds produced same public key"
assert sec_a1 != sec_b, "distinct seeds produced same secret key"

print("ok", len(pub_a1), len(sec_a1))
PY
