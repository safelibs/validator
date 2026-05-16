#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r21-bindings-crypto-kx-keypair-sizes
# @title: python3-nacl bindings crypto_kx_keypair returns 32-byte public and 32-byte secret keys
# @description: Calls nacl.bindings.crypto_kx_keypair() and asserts the returned (pk, sk) tuple has both members of length 32 and that the pair is distinct across two calls, exercising libsodium's crypto_kx key generation primitive.
# @timeout: 60
# @tags: usage, sodium, bindings, kx, python, r21
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from nacl.bindings import crypto_kx_keypair, crypto_kx_PUBLIC_KEY_BYTES, crypto_kx_SECRET_KEY_BYTES

assert crypto_kx_PUBLIC_KEY_BYTES == 32
assert crypto_kx_SECRET_KEY_BYTES == 32
pk1, sk1 = crypto_kx_keypair()
pk2, sk2 = crypto_kx_keypair()
assert len(pk1) == 32 and len(sk1) == 32, (len(pk1), len(sk1))
assert len(pk2) == 32 and len(sk2) == 32
assert pk1 != pk2 and sk1 != sk2
print("ok kx_pk_len=%d" % len(pk1))
PY
