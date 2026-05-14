#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r17-crypto-kx-keypair-length
# @title: PyNaCl nacl.bindings.crypto_kx_keypair returns 32-byte public and secret keys
# @description: Calls nacl.bindings.crypto_kx_keypair, asserts the result is a tuple of two distinct 32-byte byte strings (public, secret) with lengths matching crypto_kx_PUBLICKEYBYTES and crypto_kx_SECRETKEYBYTES respectively, and asserts a second call yields a different keypair (sanity check on RNG output).
# @timeout: 60
# @tags: usage, crypto, kx, python, r17
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.bindings as b

pub1, sec1 = b.crypto_kx_keypair()
assert isinstance(pub1, bytes) and isinstance(sec1, bytes)
assert len(pub1) == b.crypto_kx_PUBLICKEYBYTES == 32, len(pub1)
assert len(sec1) == b.crypto_kx_SECRETKEYBYTES == 32, len(sec1)
assert pub1 != sec1, "pub equals sec"

pub2, sec2 = b.crypto_kx_keypair()
assert pub2 != pub1, "two keypairs collided on pub"
assert sec2 != sec1, "two keypairs collided on sec"
print("ok kx pub=%d sec=%d" % (len(pub1), len(sec1)))
PY
