#!/usr/bin/env bash
# @testcase: usage-python3-nacl-bindings-scalarmult-base-batch12
# @title: PyNaCl bindings scalarmult_base derived public key
# @description: Calls nacl.bindings.crypto_scalarmult_base on a fixed 32-byte private scalar to derive a Curve25519 public key, asserts the output is exactly crypto_scalarmult_BYTES (32) long and matches the value derived independently by nacl.public.PrivateKey(scalar).public_key.encode(), proving the low-level binding agrees with the high-level wrapper.
# @timeout: 120
# @tags: usage, crypto, scalarmult, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.bindings as nb
from nacl.public import PrivateKey

scalar = bytes(range(32))
pub_low = nb.crypto_scalarmult_base(scalar)
assert len(pub_low) == nb.crypto_scalarmult_BYTES == 32, len(pub_low)

pub_high = PrivateKey(scalar).public_key.encode()
assert pub_low == pub_high, (pub_low.hex(), pub_high.hex())

# Different scalar -> different public key
other = bytes((b ^ 0x55) for b in scalar)
pub_other = nb.crypto_scalarmult_base(other)
assert pub_other != pub_low

print("ok", pub_low.hex())
PY
